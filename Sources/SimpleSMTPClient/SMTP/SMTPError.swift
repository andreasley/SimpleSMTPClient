import Foundation

public enum SMTPError:Swift.Error
{
    case unknownError
    case serverError(reply:SMTPReply)
    case unexpectedReply(reply:SMTPReply)
    case invalidState
    case expectedSecureConnection
    case invalidCredentials
    case failedToDecodeAuthenticationChallenge
    case failedToEncodeAuthenticationResponse
}

