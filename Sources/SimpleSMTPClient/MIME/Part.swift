import Foundation

public struct Part
{
    public enum Error : Swift.Error, LocalizedError {
        case notImplemented

        public var errorDescription: String? {
            switch self {
            case .notImplemented:
                "Not implemented"
            }
        }
    }
    
    public struct ContentType
    {
        var mediaType:String
        var charset:String?
    }

    public struct ContentDisposition
    {
        enum PresentationStyle {
            case inline
            case attachment
            case other(String)
        }
        
        var presentationStyle:PresentationStyle
        var filename:String?
        var size:Int?
        var creationDate:Date?
        var modificationDate:Date?
    }

    public enum ContentTransferEncoding {
        case quotedPrintable
        case base64
        
        @available(*, deprecated, message: "US-ASCII only with line length limit of 1000 characters.")
        case ascii7bit
        
        @available(*, deprecated, message: "Use discouraged for compatibility reasons.")
        case ascii8bit
        
        @available(*, deprecated, message: "Use discouraged for compatibility reasons.")
        case binary
    }

    var contentType:ContentType
    var contentDisposition:ContentDisposition?
    var contentTransferEncoding:ContentTransferEncoding?

    var attachmentId:String?
    let data:Data?
}

extension Part : AnyPart {}
