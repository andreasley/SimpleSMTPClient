import Foundation
import NIO

extension Multipart : BufferWritable
{    
    public func write(to buffer: inout ByteBuffer, dateFormatter: DateFormatter) throws
    {
        buffer.writeLine("Content-Type: \(subtype.mediaType)" + MIMETokens.foldedParameterSeparator + "boundary=\(MIMETokens.quotes + boundary + MIMETokens.quotes)")
        
        // A single empty line separates the header from the body (RFC 5322, section 2.1)
        buffer.writeString(CRLF)

        // Each part ends with CRLF, so every boundary delimiter starts at the beginning of a line (RFC 2046, section 5.1.1)
        for part in parts
        {
            buffer.writeLine(MIMETokens.boundaryPrefix + boundary)
            try part.write(to: &buffer, dateFormatter: dateFormatter)
        }
        buffer.writeLine(MIMETokens.boundaryPrefix + boundary + MIMETokens.boundaryPrefix)
    }
}
