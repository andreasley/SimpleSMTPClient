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
        guard self.containsNonASCII else { return self }
        
        guard let encoded = self.data(using: .utf8)?.base64EncodedString(options: .lineLength64Characters) else {
            throw MIMEStringEncodingError.failedToEncodeToBase64
        }
        return "=?utf-8?B?\(encoded)?="
    }
}
