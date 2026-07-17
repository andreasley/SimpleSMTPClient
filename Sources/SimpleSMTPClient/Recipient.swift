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
            if name.requiresEncodedWord {
                // Non-ASCII names need an RFC 2047 encoded word
                self.encodedName = try name.encodedWordIfRequired()
            } else if name.isPhraseSafeWithoutQuoting {
                self.encodedName = name
            } else {
                // ASCII names containing specials become a quoted-string (RFC 5322, section 3.2.4);
                // spam filters penalize headers that are encoded without needing to be
                self.encodedName = name.quotedForHeaderField
            }
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
