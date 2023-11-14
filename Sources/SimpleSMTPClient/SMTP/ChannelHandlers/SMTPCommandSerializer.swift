import NIO
import Foundation

final class SMTPCommandSerializer: MessageToByteEncoder, ChannelHandler
{
    typealias OutboundIn = SMTPCommand

    let dateFormatter = DateFormatter()

    init()
    {
        self.dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        self.dateFormatter.locale = Locale(identifier: "en_US")
    }
    
    func encode(data: SMTPCommand, out: inout ByteBuffer) throws
    {
        switch data {
            case .indicateIdentity(clientHostname: let hostname):
                out.writeString("EHLO \(hostname)")
            case .indicateIdentityFallback(clientHostname: let hostname):
                out.writeString("HELO \(hostname)")
            case .requestStartTLS:
                out.writeString("STARTTLS")
            case .beginAuthentication(let authentication):
                switch authentication {
                case .plain:
                    out.writeString("AUTH PLAIN")
                case .login:
                    out.writeString("AUTH LOGIN")
                case .cramMD5:
                    out.writeString("AUTH CRAM-MD5")
                }
            case .sendBase64EncodedData(let data):
                out.writeBase64Encoded(data)
            case .createMailTransaction(sender: let sender):
                out.writeString("MAIL FROM:<\(sender.address)>")
            case .addRecipient(let recipient):
                out.writeString("RCPT TO:<\(recipient.address)>")
            case .beginDataTransaction:
                out.writeString("DATA")
            case .transferData(let message):
                try message.write(to: &out, dateFormatter: dateFormatter)
            case .quit:
                out.writeString("QUIT")
        }
        
        out.writeString(CRLF)
    }
}

