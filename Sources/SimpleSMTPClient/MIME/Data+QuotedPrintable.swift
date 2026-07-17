import Foundation

extension Data
{
    /// Encodes the data as quoted-printable for use as MIME part content (RFC 2045, section 6.7).
    /// Line breaks (CR, LF or CRLF) are normalized to hard line breaks (CRLF).
    /// Output lines are limited to 76 characters using soft line breaks, and whitespace at the end of a line is encoded.
    var quotedPrintableEncoded:Data
    {
        let maximumLineLength = 76
        let carriageReturn = UInt8(ascii: "\r")
        let lineFeed = UInt8(ascii: "\n")
        let equalsSign = UInt8(ascii: "=")
        let space = UInt8(ascii: " ")
        let tab = UInt8(ascii: "\t")
        let hexDigits = Array("0123456789ABCDEF".utf8)

        var output = [UInt8]()
        var currentLineLength = 0
        var pendingWhitespace = [UInt8]()

        // Writes a single literal or encoded character, inserting a soft line break first if the line would become too long.
        // One character is reserved for a potential soft line break at the end of the line.
        func write(_ bytes: [UInt8]) {
            if currentLineLength + bytes.count > maximumLineLength - 1 {
                output.append(equalsSign)
                output.append(carriageReturn)
                output.append(lineFeed)
                currentLineLength = 0
            }
            output.append(contentsOf: bytes)
            currentLineLength += bytes.count
        }

        func writeEncoded(_ byte: UInt8) {
            write([equalsSign, hexDigits[Int(byte >> 4)], hexDigits[Int(byte & 0x0F)]])
        }

        // Whitespace is held back until the next character is known, because whitespace
        // at the end of a line must be encoded (RFC 2045, section 6.7, rule 3)
        func flushPendingWhitespace(atEndOfLine: Bool) {
            for byte in pendingWhitespace {
                if atEndOfLine {
                    writeEncoded(byte)
                } else {
                    write([byte])
                }
            }
            pendingWhitespace.removeAll()
        }

        var index = self.startIndex
        while index < self.endIndex {
            let byte = self[index]
            switch byte {
            case carriageReturn, lineFeed:
                flushPendingWhitespace(atEndOfLine: true)
                output.append(carriageReturn)
                output.append(lineFeed)
                currentLineLength = 0
                // Treat CRLF as a single line break
                let nextIndex = self.index(after: index)
                if byte == carriageReturn, nextIndex < self.endIndex, self[nextIndex] == lineFeed {
                    index = nextIndex
                }
            case space, tab:
                pendingWhitespace.append(byte)
            case 33...60, 62...126: // printable US-ASCII except "=" (61)
                flushPendingWhitespace(atEndOfLine: false)
                write([byte])
            default:
                flushPendingWhitespace(atEndOfLine: false)
                writeEncoded(byte)
            }
            index = self.index(after: index)
        }
        flushPendingWhitespace(atEndOfLine: true)

        return Data(output)
    }
}
