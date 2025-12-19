import Foundation
import NIO

extension Email : BufferWritable
{
    public enum ErrorSerializationError: Swift.Error, LocalizedError {
        case senderMissing
        case subjectMissing
        case contentMissing
        case failedToCreatePartForAttachment
        case failedToEncodeSubject

        public var errorDescription: String? {
            switch self {
            case .senderMissing:
                "Sender address is missing"
            case .subjectMissing:
                "Subject is missing"
            case .contentMissing:
                "Content is missing"
            case .failedToCreatePartForAttachment:
                "Failed to create MIME part for attachment"
            case .failedToEncodeSubject:
                "Failed to encode subject line"
            }
        }
    }
    
    public func write(to buffer: inout ByteBuffer, dateFormatter:DateFormatter) throws
    {
        guard let sender = self.from else {
            throw ErrorSerializationError.senderMissing
        }

        guard var subject = self.subject else {
            throw ErrorSerializationError.subjectMissing
        }
        
        subject = try subject.base64EncodedIfRequired()

        let messageId = UUID().uuidString + sender.address.drop { $0 != "@" }
        
        writeMessageHeader(to: &buffer, field: "From", value: sender.mailbox)
        writeMessageHeader(to: &buffer, field: "To", value: self.to.mailboxGroup)
        if self.cc.count > 0 {
            writeMessageHeader(to: &buffer, field: "Cc", value: self.cc.mailboxGroup)
        }
        if let replyToAddress = replyTo?.mailbox {
            writeMessageHeader(to: &buffer, field: "Reply-To", value: replyToAddress)
        }
        writeMessageHeader(to: &buffer, field: "Date", value: dateFormatter.string(from: Date()))
        writeMessageHeader(to: &buffer, field: "Subject", value: subject)
        writeMessageHeader(to: &buffer, field: "Message-ID", value: messageId)
        writeMessageHeader(to: &buffer, field: "MIME-Version", value: "1.0")

        if let xMailer = mailer?.clientIdentification {
            writeMessageHeader(to: &buffer, field: "X-Mailer", value: xMailer)
        }
        
        if self.priority != .normal {
            writeMessageHeader(to: &buffer, field: "X-Priority", value: self.priority.string)
        }

        let content = try self.createContentParts()
        try content.write(to: &buffer, dateFormatter: dateFormatter)

        buffer.writeString(CRLF)
        buffer.writeString(".")
    }
        
    public func createContentParts() throws -> BufferWritable
    {
        let rootContentPart:AnyPart
        let bodyPart:AnyPart

        if let htmlBody = self.htmlBody, let plainBody = self.plainBody
        {
            var bodyMultipart = Multipart(.alternative)
            bodyMultipart.parts.append(Part(text: plainBody, mediaType: "text/plain"))
            bodyMultipart.parts.append(Part(text: htmlBody, mediaType: "text/html"))
            bodyPart = bodyMultipart
        }
        else if let htmlBody = self.htmlBody
        {
            bodyPart = Part(text: htmlBody, mediaType: "text/html")
        }
        else if let plainBody = self.plainBody
        {
            bodyPart = Part(text: plainBody, mediaType: "text/plain")
        }
        else
        {
            throw ErrorSerializationError.contentMissing
        }

        if self.attachments.count > 0
        {
            var rootContentMultipart = Multipart(.related)
            rootContentMultipart.parts.append(bodyPart)
            for attachment in self.attachments {
                rootContentMultipart.parts.append(try createPart(for: attachment))
            }
            rootContentPart = rootContentMultipart
        }
        else
        {
            rootContentPart = bodyPart
        }
        
        return rootContentPart
    }
    
    public func createPart(for attachment:Attachment) throws -> Part
    {
        guard let mediaType = attachment.contentType else {
            throw ErrorSerializationError.failedToCreatePartForAttachment
        }
        
        let disposition = Part.ContentDisposition(presentationStyle: .attachment,
                                                  filename: attachment.filename,
                                                  size: attachment.size,
                                                  creationDate: attachment.creationDate,
                                                  modificationDate: attachment.modificationDate)
        
        let attachmentPart = Part(contentType: Part.ContentType(mediaType: mediaType),
                                  contentDisposition: disposition,
                                  contentTransferEncoding: .base64,
                                  data: attachment.data)
        
        return attachmentPart
    }
    
    public func writeMessageHeader(to buffer: inout ByteBuffer, field: String, value: String, suggestedLineLength: Int = 78, partSeparatorForFolding: String = " ")
    {
        let prefix = "\(field): "
        let prefixLength = prefix.count
        
        buffer.writeString(prefix)

        if prefixLength + value.count <= suggestedLineLength {
            buffer.writeString(value)
        } else {
            var currentLineLength = prefixLength
            let parts = value.components(separatedBy: partSeparatorForFolding)
            
            for (index, part) in parts.enumerated() {
                
                guard part.count < (998 - 50) else {
                    // This part is too long to include in the header.
                    continue
                }
                
                let lineLengthWithNextPart = currentLineLength + part.count + partSeparatorForFolding.count
                let needsNewLine = (lineLengthWithNextPart > suggestedLineLength) && (currentLineLength > 1)
                
                if needsNewLine {
                    buffer.writeString(CRLF)
                    buffer.writeString(" ") // Start a new line with a leading space (folding)
                    currentLineLength = 1
                }

                buffer.writeString(part)
                
                if index < parts.count - 1 {
                    buffer.writeString(partSeparatorForFolding)
                    currentLineLength += part.count + partSeparatorForFolding.count
                }
            }
        }

        buffer.writeString(CRLF)
    }
}
