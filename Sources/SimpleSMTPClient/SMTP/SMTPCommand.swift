import Foundation

enum SMTPCommand
{
    case indicateIdentity(clientHostname: String)
    case indicateIdentityFallback(clientHostname: String)
    case requestStartTLS
    case beginAuthentication(AuthenticationType)
    case sendBase64EncodedData(String)
    case createMailTransaction(sender: Recipient)
    case addRecipient(Recipient)
    case beginDataTransaction
    case transferData(from: BufferWritable)
    case quit
    
    enum AuthenticationType {
        case plain
        case login
        case cramMD5
    }
    
    enum RecipientType {
        case regular
        case cc
        case bcc
    }
}
