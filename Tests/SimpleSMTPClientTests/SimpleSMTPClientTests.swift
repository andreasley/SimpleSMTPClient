import XCTest
import Foundation
import NIO
import Logging

@testable import SimpleSMTPClient

final class SimpleSMTPClientTests: XCTestCase {
    
    struct TestCredentials : Codable
    {
        let hostname:String
        let sender:String
        let replyTo:String?
        let recipient:String
        let username:String
        let password:String
    }
    
    class LoggingMailer : Mailer
    {
        let logger = Logger(label: "ch.andreasley.Mailer")
        
        override init(server:SMTPServerConfiguration, eventLoopGroup:EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount), clientIdentification:String? = nil)
        {
            super.init(server: server, eventLoopGroup: eventLoopGroup, clientIdentification:clientIdentification)

            logger.info("SMTPClient created; connecting to \(server.hostname):\(server.port) with authentication \(server.authentication.description) on EventLoopGroup \(eventLoopGroup.description)")
        }

        override func createChannelHandlers(email: Email, completionPromise: EventLoopPromise<Void>) throws -> [ChannelHandler] {
            
            var handlers = try super.createChannelHandlers(email: email, completionPromise: completionPromise)
            if let indexOfReplyParser = handlers.firstIndex(where: { $0 is SMTPReplyParser }) {
                let connectionLoggingHandler = ConnectionLogger(logTo: logger)
                handlers.insert(connectionLoggingHandler, at: indexOfReplyParser)
            }
            return handlers
        }
    }
    
    func testSendEmail() throws
    {
        let sourceFileUrl = URL(fileURLWithPath: #file)
        let credentialsFileUrl = sourceFileUrl.deletingLastPathComponent().appendingPathComponent("TestCredentials.json")
        let credentialsData = try Data(contentsOf: credentialsFileUrl)
        let credentials = try JSONDecoder().decode(TestCredentials.self, from: credentialsData)

        let timeout:TimeInterval = 60
        
        let email = Email()
        email.subject = "Test"
        email.from = try Recipient(address: credentials.sender)
        if let replyToAddress = credentials.replyTo {
            email.replyTo = try Recipient(address: replyToAddress)
        }
        email.to = [try Recipient(address: credentials.recipient)]
        var textAttachment = try Attachment(filename: "test.txt", data: "gnampf".data(using: .utf8)!, contentType: "text/plain")
        textAttachment.creationDate = .now
        email.attachments.append(textAttachment)
        email.htmlBody = "<html><body><h1>Email attachment test</h1></body></html>"
        
        
        let server = SMTPServerConfiguration(
            hostname: credentials.hostname,
            port: .defaultForTLS,
            security: .TLS,
            authentication: .login(username: credentials.username, password: credentials.password)
        )
        
        let emailSent = expectation(description: "Email has been sent within \(timeout) seconds")
        
        let mailer = LoggingMailer(server: server)
        try mailer.send(email: email) { result in
            switch result {
            case .success(_):
                print("✅")
            case .failure(let error):
                print("❌ : \(error)")
            }
            emailSent.fulfill()
        }
        
        
        
        guard XCTWaiter.wait(for: [emailSent], timeout: timeout) != .timedOut else {
            XCTFail("Test aborted after \(timeout) seconds")
            return
        }
   }
    
    static var allTests = [
        ("testSendEmail", testSendEmail),
    ]
}
