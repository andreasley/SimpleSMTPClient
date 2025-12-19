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
    
    func base64EncodedIfRequired() throws -> String
    {
        // As per RFC 2047, "each line of a header field that contains one or more 'encoded-word's is limited to 76 characters".
        // To properly fold lines, the encoded field needs to be split up into multiple chunks.
        
        guard self.containsNonASCII else { return self }
        let fieldValueSafeLength = 65
        let encodedCharacterLengthLimit = fieldValueSafeLength / 4 * 3
        
        let chunks = stride(from: 0, to: count, by: encodedCharacterLengthLimit).map { offset in
            let start = index(startIndex, offsetBy: offset)
            let end = index(start, offsetBy: encodedCharacterLengthLimit, limitedBy: endIndex) ?? endIndex
            return String(self[start..<end])
        }

        var encodedChunks = [String]()
        
        for chunk in chunks {
            guard let data = chunk.data(using: .utf8) else {
                throw MIMEStringEncodingError.failedToEncodeToBase64
            }
            let encodedChunk = "=?UTF-8?B?\(data.base64EncodedString())?="
            
            encodedChunks.append(encodedChunk)
        }
        
        return encodedChunks.joined(separator: " ")
    }
}
