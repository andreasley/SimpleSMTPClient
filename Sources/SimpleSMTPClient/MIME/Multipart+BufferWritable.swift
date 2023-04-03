import Foundation
import NIO

extension Multipart : BufferWritable
{    
    public func write(to buffer: inout ByteBuffer, dateFormatter: DateFormatter) throws
    {
        buffer.writeLine("Content-Type: \(subtype.mediaType); boundary=\(MIMETokens.quotes + boundary + MIMETokens.quotes)")
        
        buffer.writeLine(CRLF)

        for part in parts
        {
            buffer.writeLine(CRLF)
            buffer.writeLine(MIMETokens.boundaryPrefix + boundary)
            try part.write(to: &buffer, dateFormatter: dateFormatter)
        }
        buffer.writeLine(MIMETokens.boundaryPrefix + boundary + MIMETokens.boundaryPrefix)
    }
}
