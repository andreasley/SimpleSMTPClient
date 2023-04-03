import Foundation

extension Part
{
    init(text:String, mediaType: String, disposition presentationStyle: ContentDisposition.PresentationStyle = .inline)
    {
        let data = text.data(using: .utf8)

        self.init(contentType: ContentType(mediaType: mediaType, charset: "utf-8"),
                  contentDisposition: ContentDisposition(presentationStyle: presentationStyle),
                  contentTransferEncoding: .base64,
                  data: data)
    }
}
