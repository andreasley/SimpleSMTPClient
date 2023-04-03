
import Foundation

public enum Authentication:CustomStringConvertible
{
    case plain(username:String, password:String)
    case login(username:String, password:String)
    case cramMD5(username:String, password:String) // TODO: test!

    @available(*, deprecated, message: "Using an open mail relay in production is discouraged.")
    case none
    
    public var description: String {
        switch self {
        case .none:
            return "No Authentication"
        case .plain(let username, _):
            return "PLAIN (username: \(username))"
        case .login(let username, _):
            return "LOGIN (username: \(username))"
        case .cramMD5(let username, _):
            return "CRAM-MD5 (username: \(username))"
        }
    }
}
