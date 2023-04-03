import Foundation

public struct Recipient
{
    enum Error : Swift.Error {
        case invalidEmailAddress
    }
    
    static let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "^.+@.+$")
    
    public init(name:String? = nil, address:String) throws
    {
        guard Recipient.emailPredicate.evaluate(with: address) else {
            throw Error.invalidEmailAddress
        }
        self.address = address
        self.name = name
    }

    public var name: String?
    public var address: String
    
    public var mailbox:String {
        if let name = name {
            return "\(name) <\(address)>";
        } else {
            return "<\(address)>";
        }
    }
}

extension Recipient : Hashable
{
    public func hash(into hasher: inout Hasher)
    {
        self.address.hash(into: &hasher)
    }
}

extension Recipient : LosslessStringConvertible
{
    public typealias StringLiteralType = String
    
    public init?(_ address: String)
    {
        // TODO: Parse combined name/address
        
        guard Recipient.emailPredicate.evaluate(with: address) else {
            return nil
        }
        self.address = address
    }
    
    public var description: String {
        return mailbox
    }
}
