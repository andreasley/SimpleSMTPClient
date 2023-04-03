import Foundation
import NIO

public protocol BufferWritable
{
    func write(to buffer: inout ByteBuffer, dateFormatter:DateFormatter) throws
}
