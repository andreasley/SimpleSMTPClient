import Foundation
import NIO
import NIOSSL
import Logging

public class Mailer
{
    public let server:SMTPServerConfiguration
    public let eventLoopGroup:EventLoopGroup
    public let clientIdentification:String?
    
    public enum Error: Swift.Error, LocalizedError {
        case emailInvalidOrIncomplete
        case sslInitializationFailed
        
        public var errorDescription: String? {
            switch self {
            case .emailInvalidOrIncomplete:
                "The email is invalid or incomplete. Check the following fields: from, to, subject, body"
            case .sslInitializationFailed:
                "SSL initialization failed."
            }
        }
    }
    
    public init(server:SMTPServerConfiguration, eventLoopGroup:EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount), clientIdentification:String? = nil)
    {
        self.server = server
        self.eventLoopGroup = eventLoopGroup
        self.clientIdentification = clientIdentification
    }

    public func send(email: Email, completionHandler: @escaping (Result<Void, Swift.Error>) -> Void) throws
    {
        guard email.isCompleteAndValid else {
            throw Error.emailInvalidOrIncomplete
        }
        
        email.mailer = self
        
        let completionPromise: EventLoopPromise<Void> = eventLoopGroup.next().makePromise()
        
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
        
        _ = bootstrap.channelInitializer { channel -> EventLoopFuture<Void> in
            do {
                let handlers = try self.createChannelHandlers(email: email, completionPromise: completionPromise)
                return channel.pipeline.addHandlers(handlers, position: .last)
            } catch let error {
                return channel.eventLoop.makeFailedFuture(error)
            }
        }
                
        let connection = bootstrap.connect(host: server.hostname, port: server.port)
        
        connection.cascadeFailure(to: completionPromise)
 
        completionPromise.futureResult.whenComplete { result in
            connection.whenSuccess { $0.close(promise: nil) }
            completionHandler(result)
        }
    }
    
    func createChannelHandlers(email: Email, completionPromise: EventLoopPromise<Void>) throws -> [ChannelHandler]
    {
        var handlers = [ChannelHandler]()
        
        // TODO: Don't create SSL handlers if not required
        
        let sslContext = try NIOSSLContext(configuration: .makeClientConfiguration())
        let sslHandler = try NIOSSLClientHandler(context: sslContext, serverHostname: server.hostname)
        
        if case .TLS = self.server.security {
            handlers.append(sslHandler)
        }

        handlers.append(ByteToMessageHandler(LineBasedFrameDecoder()))
        handlers.append(SMTPReplyParser())
        handlers.append(MessageToByteHandler(SMTPCommandSerializer()))
        handlers.append(SMTPClient(server: server, email: email, completionPromise: completionPromise, sslHandler:sslHandler))
        
        return handlers
    }
}
