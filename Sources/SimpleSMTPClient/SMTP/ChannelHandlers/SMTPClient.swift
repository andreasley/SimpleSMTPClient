// Based on / inspired by:
//
// SMTP: https://tools.ietf.org/html/rfc5321
// SMTP Authentication: https://tools.ietf.org/html/rfc4954
// StartTLS for SMTP: https://tools.ietf.org/html/rfc3207
// NIOSMTP: https://github.com/apple/swift-nio-examples/tree/master/NIOSMTP


import Foundation
import NIO
import NIOSSL
import NIOTLS
import Crypto

final class SMTPClient: ChannelInboundHandler
{
    typealias InboundIn = SMTPReply
    typealias OutboundIn = Email
    typealias OutboundOut = SMTPCommand
    
    enum State
    {
        case awaitingGreeting
        case awaitingIdentityConfirmation
        case awaitingStartTLSConfirmation
        case upgradingToTLS
        case awaitingAuthenticationConfirmation
        case awaitingUsernameConfirmation
        case awaitingPasswordConfirmation
        case awaitingMailTransactionConfirmation
        case awaitingRecipientConfirmation
        case awaitingDataTransactionConfirmation
        case awaitingDataTransferConfirmation
        case awaitingQuitConfirmation
        case done
    }
        
    private var state:State = .awaitingGreeting
    private let email: Email
    private let serverConfiguration: SMTPServerConfiguration
    private let completionPromise: EventLoopPromise<Void>
    private var error: Swift.Error?
    private var unprocessedRecipients = Set<Recipient>()
    private let sslHandler:NIOSSLClientHandler
    private var hasCompletedSSLHandshake = false
    private var isSendingSuccessful = false

    init(server:SMTPServerConfiguration, email:Email, completionPromise:EventLoopPromise<Void>, sslHandler:NIOSSLClientHandler)
    {
        self.serverConfiguration = server
        self.email = email
        self.sslHandler = sslHandler
        self.completionPromise = completionPromise
        self.unprocessedRecipients.formUnion(email.to)
        self.unprocessedRecipients.formUnion(email.cc)
        self.unprocessedRecipients.formUnion(email.bcc)
    }
    
    public func userInboundEventTriggered(context: ChannelHandlerContext, event: Any)
    {
        if let event = event as? TLSUserEvent, case .handshakeCompleted = event {
            // this is called for both regular TLS and StartTLS
            self.hasCompletedSSLHandshake = true
        }
        context.fireUserInboundEventTriggered(event)
    }

    func channelInactive(context: ChannelHandlerContext)
    {
        // Some SMTP servers close the connection after e.g. authentication failure. In these cases, there's already a reply and the session can just be ended. Otherwise, an .eof error is thrown.
        if self.state != .done && self.state != .awaitingQuitConfirmation {
            self.error = ChannelError.eof
        }
        done(in: context)
    }

    func errorCaught(context: ChannelHandlerContext, error: Error)
    {
        abortSending(in: context, with: error)
    }
    
    func abortSending(in context: ChannelHandlerContext, with error: Swift.Error)
    {
        self.error = error
        // TODO: Surface error
        quit(in: context)
    }

    func submit(_ command: SMTPCommand, in context: ChannelHandlerContext)
    {
        context.writeAndFlush(self.wrapOutboundOut(command)).cascadeFailure(to: self.completionPromise)
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny)
    {
        let reply = self.unwrapInboundIn(data)
        
        // TODO:
        // - other AUTH methods
        // - length limit checks
        
        switch state {
            case .awaitingGreeting:
                switch reply.code {
                case 220:
                    submit(.indicateIdentity(clientHostname: self.serverConfiguration.hostname), in: context)
                    state = .awaitingIdentityConfirmation
                case 554:
                    error = SMTPError.serverError(reply:reply)
                    submit(.quit, in: context)
                    state = .awaitingQuitConfirmation
                default:
                    abortSending(in: context, with: SMTPError.unexpectedReply(reply: reply))
                }
            case .awaitingIdentityConfirmation:
                switch reply.code {
                case 200..<300:
                    if self.serverConfiguration.security == .startTLS, !hasCompletedSSLHandshake {
                        submit(.requestStartTLS, in: context)
                        self.state = .awaitingStartTLSConfirmation
                    } else {
                        beginAuthentication(in: context)
                    }
                case 500:
                    submit(.indicateIdentityFallback(clientHostname: self.serverConfiguration.hostname), in: context)
                    self.state = .awaitingIdentityConfirmation
                default:
                    abortSending(in: context, with: SMTPError.unexpectedReply(reply: reply))
                }
            case .awaitingStartTLSConfirmation:
                switch reply.code {
                case 220:
                    self.state = .upgradingToTLS
                    self.upgradeConnectionToTLS(in: context) {
                        self.submit(.indicateIdentity(clientHostname: self.serverConfiguration.hostname), in: context)
                        self.state = .awaitingIdentityConfirmation
                    }
                case 501:
                    error = SMTPError.serverError(reply:reply)
                    submit(.quit, in: context)
                    state = .awaitingQuitConfirmation
                default:
                    abortSending(in: context, with: SMTPError.unexpectedReply(reply: reply))
                }
            case .upgradingToTLS:
                // receiving data while the sslHandler is being added to the pipeline is not supported
                context.fireErrorCaught(SMTPError.unexpectedReply(reply: reply))
            case .awaitingAuthenticationConfirmation:
                switch reply.code {
                case 334:
                    switch serverConfiguration.authentication {
                    case .plain(let username, let password):
                        submit(.sendBase64EncodedData("\0"+username+"\0"+password), in: context)
                        state = .awaitingPasswordConfirmation
                    case .login(let username, _):
                        submit(.sendBase64EncodedData(username), in: context)
                        state = .awaitingUsernameConfirmation
                    case .cramMD5(let username, let password):
                        guard let challenge = decodeBase64(reply.text.first) else {
                            context.fireErrorCaught(SMTPError.failedToDecodeAuthenticationChallenge)
                            return
                        }
                        guard let data = (password + challenge).data(using: .utf8) else {
                            context.fireErrorCaught(SMTPError.failedToEncodeAuthenticationResponse)
                            return
                        }
                        let digest = Insecure.MD5.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
                        submit(.sendBase64EncodedData(username + digest), in: context)
                        state = .awaitingUsernameConfirmation
                    case .none:
                        abortSending(in: context, with: SMTPError.invalidState)
                    }
                case 503:
                    abortSending(in: context, with: SMTPError.invalidState)
                default:
                    abortSending(in: context, with: SMTPError.unexpectedReply(reply: reply))
                }
            case .awaitingUsernameConfirmation:
                switch reply.code {
                case 334:
                    switch serverConfiguration.authentication {
                    case .plain(_, _), .cramMD5(_, _), .none:
                        context.fireErrorCaught(SMTPError.invalidState)
                    case .login(_, let password):
                        submit(.sendBase64EncodedData(password), in: context)
                        state = .awaitingPasswordConfirmation
                    }
                default:
                    abortSending(in: context, with: SMTPError.unexpectedReply(reply: reply))
                }
            case .awaitingPasswordConfirmation:
                switch reply.code {
                case 235:
                    beginMailTransaction(in: context)
//                case 432:
//                    //  A password transition is needed
//                    fatalError("Not implemented")
//                case 454:
//                    // Temporary authentication failure
//                    fatalError("Not implemented")
//                case 534:
//                    // Authentication mechanism is too weak
//                    fatalError("Not implemented")
//                case 500:
//                    // Authentication Exchange line is too long
//                    fatalError("Not implemented")
                case 535:
                    // Authentication credentials invalid
                    abortSending(in: context, with: SMTPError.invalidCredentials)
                default:
                    abortSending(in: context, with: SMTPError.unexpectedReply(reply: reply))
                }
            case .awaitingMailTransactionConfirmation:
                switch reply.code {
                case 250:
                    addNextRecipient(in: context)
                default:
                    abortSending(in: context, with: SMTPError.unexpectedReply(reply: reply))
                }
            case .awaitingRecipientConfirmation:
                switch reply.code {
                case 250:
                    if unprocessedRecipients.count > 0 {
                        addNextRecipient(in: context)
                    } else {
                        submit(.beginDataTransaction, in: context)
                        self.state = .awaitingDataTransactionConfirmation
                    }
                default:
                    abortSending(in: context, with: SMTPError.unexpectedReply(reply: reply))
                }
            case .awaitingDataTransactionConfirmation:
                switch reply.code {
                case 354:
                    submit(.transferData(from: email), in: context)
                    self.state = .awaitingDataTransferConfirmation
                default:
                    abortSending(in: context, with: SMTPError.unexpectedReply(reply: reply))
                }
            case .awaitingDataTransferConfirmation:
                switch reply.code {
                case 250:
                    self.isSendingSuccessful = true
                    quit(in: context)
                default:
                    abortSending(in: context, with: SMTPError.unexpectedReply(reply: reply))
                }
            case .awaitingQuitConfirmation:
                done(in: context)
                switch reply.code {
                case 221:
                    () // as expected
                default:
                    () // log?
                }
            case .done:
                return
        }
    }
    
    func done(in context: ChannelHandlerContext)
    {
        context.close(promise: nil)
        self.state = .done
        
        if isSendingSuccessful {
            self.completionPromise.succeed(())
        } else {
            self.completionPromise.fail(self.error ?? SMTPError.unknownError)
        }
    }
    
    func upgradeConnectionToTLS(in context:ChannelHandlerContext, successHandler: @escaping ()->Void)
    {
        context.channel.pipeline.addHandler(sslHandler, position: .first).whenComplete { result in
            switch result {
            case .failure(let error):
                context.fireErrorCaught(error)
            case .success:
                successHandler()
            }
        }
    }
    
    func beginAuthentication(in context:ChannelHandlerContext)
    {
        guard hasCompletedSSLHandshake else {
            context.fireErrorCaught(SMTPError.expectedSecureConnection)
            return
        }
        
        switch serverConfiguration.authentication {
            case .plain(_, _):
                submit(.beginAuthentication(.plain), in: context)
                state = .awaitingAuthenticationConfirmation
            case .login(_, _):
                submit(.beginAuthentication(.login), in: context)
                state = .awaitingAuthenticationConfirmation
            case .cramMD5(_, _):
                submit(.beginAuthentication(.cramMD5), in: context)
                state = .awaitingAuthenticationConfirmation
            case .none:
                beginMailTransaction(in: context)
        }
    }
    
    func beginMailTransaction(in context:ChannelHandlerContext)
    {
        guard let sender = email.from else {
            context.fireErrorCaught(SMTPError.invalidState)
            return
        }
        submit(.createMailTransaction(sender: sender), in: context)
        self.state = .awaitingMailTransactionConfirmation
    }
    
    func addNextRecipient(in context:ChannelHandlerContext)
    {
        let nextRecipient = unprocessedRecipients.removeFirst()
        submit(.addRecipient(nextRecipient), in: context)
        self.state = .awaitingRecipientConfirmation
    }
    
    func quit(in context:ChannelHandlerContext)
    {
        submit(.quit, in: context)
        self.state = .awaitingQuitConfirmation
    }

    func decodeBase64(_ string:String?) -> String?
    {
        guard let string = string, let decodedData = Data(base64Encoded: string, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return String(bytes: decodedData, encoding: .utf8)
    }
}
