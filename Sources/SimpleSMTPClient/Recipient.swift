import Foundation

public struct Recipient
{
    enum Error : Swift.Error {
        case invalidEmailAddress
    }
    
    static let emailPattern = try! Regex(#"^\S+@\S+\.\S+$"#)
    
    public init(name:String? = nil, address:String) throws
    {
        guard let _ = address.wholeMatch(of: Self.emailPattern) else {
            throw Error.invalidEmailAddress
        }
        self.address = address
        self.name = name
        self.encodedName = try name?.base64EncodedIfRequired()
    }

    public var name: String?
    public var encodedName: String?
    public var address: String
    
    public var mailbox:String {
        if let encodedName = encodedName {
            return "\(encodedName) <\(address)>";
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

        guard let _ = address.wholeMatch(of: Self.emailPattern) else {
            return nil
        }
        self.address = address
    }
    
    public var description: String {
        return mailbox
    }
}
