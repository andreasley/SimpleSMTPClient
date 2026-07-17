import Foundation

extension String
{
    public enum MIMEStringEncodingError: Swift.Error, LocalizedError {
        case failedToEncode

        public var errorDescription: String? {
            switch self {
            case .failedToEncode:
                "Failed to encode string for use in a header field"
            }
        }
    }

    var containsNonASCII:Bool
    {
        for utf8Character in self.utf8 {
            switch utf8Character {
            case 9, 32...60, 62...126:
                continue
            default:
                return true
            }
        }
        return false
    }

    /// Percent-encodes the string for use as an extended MIME parameter value (RFC 2231, section 4).
    var percentEncodedForMIMEParameter:String
    {
        var allowedCharacters = CharacterSet.alphanumerics
        allowedCharacters.insert(charactersIn: "!#$&+-.^_`|~")
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
    }

    /// True if the string cannot be used in a header field as-is: it contains bytes outside
    /// printable US-ASCII, or the sequence "=?", which a decoder could mistake for the start
    /// of an encoded word (RFC 2047, section 5).
    var requiresEncodedWord:Bool
    {
        for byte in self.utf8 {
            switch byte {
            case 9, 32...126:
                continue
            default:
                return true
            }
        }
        return self.contains("=?")
    }

    /// True if the string can be used as a display name without quoting or encoding.
    /// Only letters, digits and spaces are allowed — a conservative subset of an RFC 5322 phrase.
    var isPhraseSafeWithoutQuoting:Bool
    {
        return self.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == " ") }
    }

    /// Returns the string as an RFC 5322 quoted-string (section 3.2.4), escaping backslashes and double quotes.
    /// The string must not contain non-ASCII characters; use `encodedWordIfRequired()` for those.
    var quotedForHeaderField:String
    {
        let escapedString = self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escapedString)\""
    }

    /// Encodes the string as RFC 2047 encoded words if it can't be represented in a header field as-is.
    /// Mostly-ASCII strings use the human-readable Q encoding, others the more compact B encoding
    /// (spam filters penalize base64-encoded headers without 8-bit content).
    /// The result is split into space-separated encoded words where necessary, so that each encoded word
    /// stays within the 75-character limit (RFC 2047, section 2) and header lines can be folded.
    func encodedWordIfRequired() throws -> String
    {
        guard self.requiresEncodedWord else { return self }

        // "=?UTF-8?Q?" / "=?UTF-8?B?" plus "?=" leave 63 payload characters within the 75-character limit
        let maximumPayloadLength = 63

        let encodingIdentifier:String
        let payloadChunks:[String]

        // Content without 8-bit characters always uses Q: spam filters penalize base64-encoded headers that decode to plain ASCII
        let containsEightBitCharacters = self.utf8.contains { $0 > 126 }

        if !containsEightBitCharacters || self.qEncodedLength <= self.base64EncodedLength {
            encodingIdentifier = "Q"
            payloadChunks = self.qEncodedChunks(maximumPayloadLength: maximumPayloadLength)
        } else {
            encodingIdentifier = "B"
            payloadChunks = try self.base64EncodedChunks(maximumPayloadLength: maximumPayloadLength)
        }

        return payloadChunks.map { "=?UTF-8?\(encodingIdentifier)?\($0)?=" }.joined(separator: " ")
    }

    /// Q-encodes a single character (RFC 2047, section 4.2), using only characters that are
    /// safe in all header contexts, including phrases (RFC 2047, section 5, rule 3).
    private static func qEncodedToken(for character:Character) -> String
    {
        var token = ""
        for byte in String(character).utf8 {
            switch byte {
            case UInt8(ascii: " "):
                token += "_"
            case UInt8(ascii: "A")...UInt8(ascii: "Z"),
                 UInt8(ascii: "a")...UInt8(ascii: "z"),
                 UInt8(ascii: "0")...UInt8(ascii: "9"),
                 UInt8(ascii: "!"), UInt8(ascii: "*"), UInt8(ascii: "+"),
                 UInt8(ascii: "-"), UInt8(ascii: "/"):
                token.append(Character(UnicodeScalar(byte)))
            default:
                token += String(format: "=%02X", byte)
            }
        }
        return token
    }

    private var qEncodedLength:Int
    {
        return self.reduce(0) { $0 + Self.qEncodedToken(for: $1).count }
    }

    private var base64EncodedLength:Int
    {
        return (self.utf8.count + 2) / 3 * 4
    }

    private func qEncodedChunks(maximumPayloadLength: Int) -> [String]
    {
        var chunks = [String]()
        var currentChunk = ""

        // Chunking must happen at character boundaries, so a multi-byte character is never split across encoded words
        for character in self {
            let token = Self.qEncodedToken(for: character)
            if currentChunk.count + token.count > maximumPayloadLength, !currentChunk.isEmpty {
                chunks.append(currentChunk)
                currentChunk = ""
            }
            currentChunk += token
        }
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        return chunks
    }

    private func base64EncodedChunks(maximumPayloadLength: Int) throws -> [String]
    {
        // Base64 encodes 3 bytes as 4 characters; a multiple of 3 avoids padding within the string
        let maximumBytesPerChunk = maximumPayloadLength / 4 * 3

        // The string might contain characters that require multiple bytes, so to observe the length limit, chunking by byte size is necessary (instead of by character count)
        return try chunkedByBytes(maxBytes: maximumBytesPerChunk).map { chunk in
            guard let data = chunk.data(using: .utf8) else {
                throw MIMEStringEncodingError.failedToEncode
            }
            return data.base64EncodedString()
        }
    }

    private func chunkedByBytes(maxBytes: Int) -> [String]
    {
        var chunks: [String] = []
        var currentChunk = ""
        var currentByteCount = 0

        for character in self {
            let characterString = String(character)
            let characterByteCount = characterString.utf8.count

            // If adding this character would exceed the limit, start a new chunk
            if currentByteCount + characterByteCount > maxBytes {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                }
                currentChunk = characterString
                currentByteCount = characterByteCount
            } else {
                currentChunk.append(character)
                currentByteCount += characterByteCount
            }
        }

        // Add the last chunk if it's not empty
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        return chunks
    }
}
