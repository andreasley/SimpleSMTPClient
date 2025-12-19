import Foundation

extension String
{
    public enum MIMEStringEncodingError: Swift.Error, LocalizedError {
        case failedToEncodeToBase64

        public var errorDescription: String? {
            switch self {
            case .failedToEncodeToBase64:
                "Failed to encode to Base64"
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
    
    func base64EncodedIfRequired(force: Bool = false) throws -> String
    {
        // As per RFC 2047, "each line of a header field that contains one or more 'encoded-word's is limited to 76 characters".
        // To properly fold lines, the encoded field needs to be split up into multiple chunks.
        
        guard force || self.containsNonASCII else { return self }
        
        let fieldValueSafeLength = 55
        let encodedCharacterLengthLimit = fieldValueSafeLength / 4 * 3

        var encodedChunks = [String]()
        
        // The field might contain characters that require multiple bytes, so to observe the length limit, chunking by byte size is necessary (instead of by character count)
        let chunks = chunkedByBytes(maxBytes: encodedCharacterLengthLimit)

        for chunk in chunks {
            guard let data = chunk.data(using: .utf8) else {
                throw MIMEStringEncodingError.failedToEncodeToBase64
            }
            let encodedChunk = "=?UTF-8?B?\(data.base64EncodedString())?="
            
            encodedChunks.append(encodedChunk)
        }
        
        return encodedChunks.joined(separator: " ")
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
