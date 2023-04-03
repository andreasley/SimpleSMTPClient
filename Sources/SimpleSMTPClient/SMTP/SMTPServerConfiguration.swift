import Foundation
import NIOSSL

public struct SMTPServerConfiguration
{
    public init(hostname: String, port: Port, security: Security = .startTLS, authentication: Authentication)
    {
        self.hostname = hostname
        self.port = port
        self.security = security
        self.authentication = authentication
    }
    
    public var hostname: String
    public var port: Port
    public var security: Security = .startTLS
    public var authentication: Authentication
    
}

