import Foundation
import CoreServices

public struct Attachment
{
    enum AttachmentError : Swift.Error {
        case urlNotAFile
        case fileNotFound
    }

    public var filename: String
    public var contentType: String?
    public var data: Data
    public var url: URL?
    public let size: Int
    public var creationDate: Date?
    public var modificationDate: Date?
    
    public init(file url:URL, hideDates:Bool = false) throws
    {
        guard url.isFileURL else {
            throw AttachmentError.urlNotAFile
        }
        
        guard FileManager.default.fileExists(atPath: url.absoluteString) else {
            throw AttachmentError.fileNotFound
        }

        self.url = url
        self.filename = url.lastPathComponent

        self.data = try Data(contentsOf: url)

        let attributes = try FileManager.default.attributesOfItem(atPath: url.absoluteString)
        self.size = attributes[.size] as? Int ?? 0
        
        if !hideDates {
            self.creationDate = attributes[.creationDate] as? Date
            self.modificationDate = attributes[.modificationDate] as? Date
        }
        
        self.contentType = detectMimeType(from: url.pathExtension)
    }

    public init(filename:String, data:Data, creationDate:Date? = nil, modificationDate:Date? = nil, contentType:String? = nil) throws
    {
        self.filename = filename
        self.data = data
        self.size = data.count
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        if let contentType = contentType {
            self.contentType = contentType
        } else {
            self.contentType = detectMimeType(from: (filename as NSString).pathExtension)
        }
    }
    
    func detectMimeType(from suffix:String) -> String?
    {
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, suffix as NSString, nil)?.takeRetainedValue(),
            let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() as String? else {
                return nil
        }
        
        return mimetype
    }
}
