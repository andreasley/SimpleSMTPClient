import Foundation
import NIO

extension ByteBuffer
{
    mutating func writeLine(_ string:String) {
        self.writeString(string)
        self.writeString(CRLF)
    }
    
    mutating func writeBase64Encoded(_ string:String) {
        let base64data = Data(string.utf8).base64EncodedData()
        self.writeBytes(base64data)
    }

    mutating func writeBase64Encoded(_ data:Data) {
        let base64data = data.base64EncodedData()
        self.writeBytes(base64data)
    }
}
