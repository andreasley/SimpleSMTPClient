import Foundation

struct MIMETokens
{
    static let boundaryPrefix = "--"
    static let parameterSeparator = "; "
    /// Separates parameters while folding each one onto a new line (RFC 5322, section 2.2.3)
    static let foldedParameterSeparator = ";" + CRLF + " "
    static let quotes = "\""
}
