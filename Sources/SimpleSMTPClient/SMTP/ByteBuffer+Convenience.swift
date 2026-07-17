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
        // As per RFC 2045, section 6.8, the encoded output must be represented in lines of no more than 76 characters, delimited by CRLF.
        let base64data = data.base64EncodedData(options: [.lineLength76Characters, .endLineWithCarriageReturn, .endLineWithLineFeed])
        self.writeBytes(base64data)
    }

    /// Writes the readable bytes of `buffer`, duplicating any dot at the beginning of a line as required for SMTP transparency (RFC 5321, section 4.5.2).
    mutating func writeDotStuffed(_ buffer:ByteBuffer) {
        let dot = UInt8(ascii: ".")
        let lineFeed = UInt8(ascii: "\n")
        var atStartOfLine = true
        for byte in buffer.readableBytesView {
            if atStartOfLine && byte == dot {
                self.writeInteger(dot)
            }
            self.writeInteger(byte)
            atStartOfLine = (byte == lineFeed)
        }
    }

    var endsWithCRLF:Bool {
        let view = self.readableBytesView
        return view.suffix(2).elementsEqual([UInt8(ascii: "\r"), UInt8(ascii: "\n")])
    }
}
