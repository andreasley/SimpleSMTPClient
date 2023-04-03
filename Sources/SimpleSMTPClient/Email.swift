import Foundation

public class Email
{
    public enum Priority
    {
        case low
        case normal
        case high

        public var string: String {
            switch self {
                case .low:
                    return "1"
                case .normal:
                    return "3"
                case .high:
                    return "5"
            }
        }
    }
    
    public init() {}
    
    public enum Error : Swift.Error {
        case invalidSender
        case invalidRecipient
    }
    
    var hasBody:Bool {
        return plainBody != nil || htmlBody != nil
    }
    
    var isCompleteAndValid:Bool {
        guard from != nil, !to.isEmpty, !subject.isEmpty, self.hasBody else {
            return false
        }
        return true
    }
    
    public var from: Recipient?
    public var replyTo: Recipient?
    public var to: [Recipient] = []
    public var cc: [Recipient] = []
    public var bcc: [Recipient] = []

    public var subject: String?
    public var priority: Priority = .normal
    public var plainBody: String?
    public var htmlBody: String?
    public var attachments: [Attachment] = []
    weak var mailer: Mailer?
}
