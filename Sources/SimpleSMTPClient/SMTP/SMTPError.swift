import Foundation

public enum SMTPError: Swift.Error, LocalizedError
{
    case unknownError
    case serverError(reply:SMTPReply)
    case unexpectedReply(reply:SMTPReply)
    case invalidState
    case expectedSecureConnection
    case invalidCredentials
    case failedToDecodeAuthenticationChallenge
    case failedToEncodeAuthenticationResponse
    
    public var errorDescription: String? {
        switch self {
        case .unknownError:
            "Unknown error"
        case .serverError(reply: let reply):
            "Server error: \(reply)"
        case .unexpectedReply(reply: let reply):
            "Unexpected reply: \(reply)"
        case .invalidState:
            "Invalid state"
        case .expectedSecureConnection:
            "Expected secure connection"
        case .failedToEncodeAuthenticationResponse:
            "Falied to encode authentication response"
        case .failedToDecodeAuthenticationChallenge:
            "Falied to decode authentication challenge"
        case .invalidCredentials:
            "Invalid credentials"
        }
    }
}

