import NIO
import Foundation

final class SMTPCommandSerializer: MessageToByteEncoder, ChannelHandler
{
    typealias OutboundIn = SMTPCommand

    let dateFormatter = DateFormatter()

    init()
    {
        self.dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        // en_US_POSIX prevents the user's 12/24-hour time setting from overriding the fixed format (see Apple QA1480); RFC 5322 requires English day and month names.
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
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
                var messageBuffer = ByteBufferAllocator().buffer(capacity: 4096)
                try message.write(to: &messageBuffer, dateFormatter: dateFormatter)
                // Escape lines starting with a dot (transparency, RFC 5321, section 4.5.2) and terminate the data transfer with <CRLF>.<CRLF>
                out.writeDotStuffed(messageBuffer)
                if !out.endsWithCRLF {
                    out.writeString(CRLF)
                }
                out.writeString(".")
            case .quit:
                out.writeString("QUIT")
        }
        
        out.writeString(CRLF)
    }
}

