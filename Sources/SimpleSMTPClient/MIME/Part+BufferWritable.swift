import Foundation
import NIO

extension Part : BufferWritable
{    
    public func write(to buffer: inout ByteBuffer, dateFormatter: DateFormatter) throws
    {
        try self.contentType.write(to: &buffer, dateFormatter: dateFormatter)
        try self.contentDisposition?.write(to: &buffer, dateFormatter: dateFormatter)
        try self.contentTransferEncoding?.write(to: &buffer, dateFormatter: dateFormatter)
        
        if let attachmentId = attachmentId {
            buffer.writeLine("X-Attachment-Id: \(attachmentId)")
        }
        
        buffer.writeLine(CRLF)
        
        if let data = data {
            switch self.contentTransferEncoding {
            case .base64:
                buffer.writeBase64Encoded(data)
            default:
                // TODO: Implement at least quoted-printable
                throw Error.notImplemented
            }

        }

        buffer.writeLine(CRLF)
    }
}

extension Part.ContentType : BufferWritable
{
    public func write(to buffer: inout ByteBuffer, dateFormatter: DateFormatter) throws
    {
        var contentTypeString = "Content-Type: \(mediaType)"
        var parameters:[String:String] = [:]
        if let charset = self.charset {
            parameters["charset"] = charset
        }
        if parameters.count > 0 {
            contentTypeString += MIMETokens.parameterSeparator
            contentTypeString += parameters.map { "\($0.key)=\($0.value)" }.joined(separator: MIMETokens.parameterSeparator)
        }
        
        // TODO: Break lines where appropriate
        
        buffer.writeLine(contentTypeString)
    }
}

extension Part.ContentDisposition.PresentationStyle
{
    var string:String
    {
        switch self {
        case .inline:
            return "inline"
        case .attachment:
            return "attachment"
        case .other(let customStyle):
            return customStyle
        }
    }
}

extension Part.ContentDisposition : BufferWritable
{
    public func write(to buffer: inout ByteBuffer, dateFormatter: DateFormatter) throws
    {
        var disposition = "Content-Disposition: \(presentationStyle.string)"
        var parameters:[String:String] = [:]
        
        if let filename = filename {
            // TODO: Normalize filename?
            parameters["filename"] = MIMETokens.quotes + filename + MIMETokens.quotes
        }

        if let size = size {
            parameters["size"] = String(size)
        }

        if let creationDate = creationDate {
            parameters["creation-date"] = dateFormatter.string(from: creationDate)
        }

        if let modificationDate = modificationDate {
            parameters["modification-date"] = dateFormatter.string(from: modificationDate)
        }

        if parameters.count > 0 {
            disposition += MIMETokens.parameterSeparator
            disposition += parameters.map { "\($0.key)=\($0.value)" }.joined(separator: MIMETokens.parameterSeparator)
        }

        // TODO: Break lines where appropriate
        
        buffer.writeLine(disposition)
    }
}

extension Part.ContentTransferEncoding : BufferWritable
{
    public func write(to buffer: inout ByteBuffer, dateFormatter: DateFormatter) throws
    {
        let encoding:String
        switch self {
        case .quotedPrintable:
            encoding = "quoted-printable"
        case .base64:
            encoding = "base64"
        case .binary:
            encoding = "binary"
        case .ascii7bit:
            encoding = "7bit"
        case .ascii8bit:
            encoding = "8bit"
        }
        buffer.writeLine("Content-Transfer-Encoding: \(encoding)")
    }
}
