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
        
        // A single empty line separates the header from the body (RFC 5322, section 2.1)
        buffer.writeString(CRLF)
        
        if let data = data {
            switch self.contentTransferEncoding {
            case .base64:
                buffer.writeBase64Encoded(data)
                buffer.writeString(CRLF)
            case .quotedPrintable:
                buffer.writeBytes(data.quotedPrintableEncoded)
                buffer.writeString(CRLF)
            default:
                throw Error.notImplemented
            }

        }
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
            // Fold each parameter onto its own line to observe the recommended line length limit (RFC 5322, section 2.1.1)
            contentTypeString += MIMETokens.foldedParameterSeparator
            contentTypeString += parameters.map { "\($0.key)=\($0.value)" }.joined(separator: MIMETokens.foldedParameterSeparator)
        }
        
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
            if filename.containsNonASCII {
                // Parameter values must be US-ASCII; encode non-ASCII filenames as an extended parameter (RFC 2231)
                parameters["filename*"] = "UTF-8''" + filename.percentEncodedForMIMEParameter
            } else {
                // Escape backslashes and quotes to form a valid quoted-string (RFC 5322, section 3.2.4)
                let escapedFilename = filename
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: MIMETokens.quotes, with: "\\" + MIMETokens.quotes)
                parameters["filename"] = MIMETokens.quotes + escapedFilename + MIMETokens.quotes
            }
        }

        if let size = size {
            parameters["size"] = String(size)
        }

        // Date values contain spaces, commas and colons (tspecials, RFC 2045), so they must be quoted (RFC 2183, section 2)
        if let creationDate = creationDate {
            parameters["creation-date"] = MIMETokens.quotes + dateFormatter.string(from: creationDate) + MIMETokens.quotes
        }

        if let modificationDate = modificationDate {
            parameters["modification-date"] = MIMETokens.quotes + dateFormatter.string(from: modificationDate) + MIMETokens.quotes
        }

        if parameters.count > 0 {
            // Fold each parameter onto its own line to observe the recommended line length limit (RFC 5322, section 2.1.1)
            disposition += MIMETokens.foldedParameterSeparator
            disposition += parameters.map { "\($0.key)=\($0.value)" }.joined(separator: MIMETokens.foldedParameterSeparator)
        }

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
