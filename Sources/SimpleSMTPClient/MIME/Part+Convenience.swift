import Foundation

extension Part
{
    init(text:String, mediaType: String, disposition presentationStyle: ContentDisposition.PresentationStyle = .inline)
    {
        let data = text.data(using: .utf8)

        // Text parts use quoted-printable instead of base64: it keeps ASCII content human-readable
        // and avoids spam filter penalties for base64-encoded text without 8-bit characters
        self.init(contentType: ContentType(mediaType: mediaType, charset: "utf-8"),
                  contentDisposition: ContentDisposition(presentationStyle: presentationStyle),
                  contentTransferEncoding: .quotedPrintable,
                  data: data)
    }
}
