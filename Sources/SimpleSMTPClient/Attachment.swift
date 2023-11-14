import Foundation

public struct Attachment
{
    static let mimeTypes = [
        "aac": "audio/aac",
        "abw": "application/x-abiword",
        "arc": "application/x-freearc",
        "avif": "image/avif",
        "avi": "video/x-msvideo",
        "azw": "application/vnd.amazon.ebook",
        "bin": "application/octet-stream",
        "bmp": "image/bmp",
        "bz": "application/x-bzip",
        "bz2": "application/x-bzip2",
        "cda": "application/x-cdf",
        "csh": "application/x-csh",
        "css": "text/css",
        "csv": "text/csv",
        "doc": "application/msword",
        "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "eot": "application/vnd.ms-fontobject",
        "epub": "application/epub+zip",
        "gz": "application/gzip",
        "gif": "image/gif",
        "htm, .html": "text/html",
        "ico": "image/vnd.microsoft.icon",
        "ics": "text/calendar",
        "jar": "application/java-archive",
        "jpeg, .jpg": "image/jpeg",
        "js": "text/javascript",
        "json": "application/json",
        "jsonld": "application/ld+json",
        "mid, .midi": "audio/midi, audio/x-midi",
        "mjs": "text/javascript",
        "mp3": "audio/mpeg",
        "mp4": "video/mp4",
        "mpeg": "video/mpeg",
        "mpkg": "application/vnd.apple.installer+xml",
        "odp": "application/vnd.oasis.opendocument.presentation",
        "ods": "application/vnd.oasis.opendocument.spreadsheet",
        "odt": "application/vnd.oasis.opendocument.text",
        "oga": "audio/ogg",
        "ogv": "video/ogg",
        "ogx": "application/ogg",
        "opus": "audio/opus",
        "otf": "font/otf",
        "png": "image/png",
        "pdf": "application/pdf",
        "php": "application/x-httpd-php",
        "ppt": "application/vnd.ms-powerpoint",
        "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "rar": "application/vnd.rar",
        "rtf": "application/rtf",
        "sh": "application/x-sh",
        "svg": "image/svg+xml",
        "tar": "application/x-tar",
        "tif, .tiff": "image/tiff",
        "ts": "video/mp2t",
        "ttf": "font/ttf",
        "txt": "text/plain",
        "vsd": "application/vnd.visio",
        "wav": "audio/wav",
        "weba": "audio/webm",
        "webm": "video/webm",
        "webp": "image/webp",
        "woff": "font/woff",
        "woff2": "font/woff2",
        "xhtml": "application/xhtml+xml",
        "xls": "application/vnd.ms-excel",
        "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "xml": "application/xml",
        "xul": "application/vnd.mozilla.xul+xml",
        "zip": "application/zip",
        "7z": "application/x-7z-compressed"
    ]
    
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
        let filePath = url.path
        
        guard url.isFileURL else {
            throw AttachmentError.urlNotAFile
        }
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw AttachmentError.fileNotFound
        }

        self.url = url
        self.filename = url.lastPathComponent

        self.data = try Data(contentsOf: url)

        let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
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
        return Self.mimeTypes[suffix]
    }
}
