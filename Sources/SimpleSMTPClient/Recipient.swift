import Foundation

public struct Recipient
{
    public enum Error : Swift.Error, LocalizedError {
        case invalidEmailAddress
        
        public var errorDescription: String? {
            switch self {
            case .invalidEmailAddress:
                "Invalid email address"
            }
        }
    }
    
    static let emailPattern = try! Regex(#"^\S+@\S+\.\S+$"#)
    
    public init(name:String? = nil, address:String) throws
    {
        guard let _ = address.wholeMatch(of: Self.emailPattern) else {
            throw Error.invalidEmailAddress
        }
        self.address = address
        self.name = name
        
        if let name {
            let shouldForceEncoding = name.contains(",")
            // Note: Don't quote names because they are especially tricky to fold properly and don't combine with encoded words
            self.encodedName = try name.base64EncodedIfRequired(force: shouldForceEncoding)
        }
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
