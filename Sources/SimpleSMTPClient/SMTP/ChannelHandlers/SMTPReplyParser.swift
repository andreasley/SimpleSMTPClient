import NIO

final class SMTPReplyParser: ChannelInboundHandler
{
    typealias InboundIn = ByteBuffer
    typealias InboundOut = SMTPReply
    
    var multilineCache = [String]()
    
    public enum Error: Swift.Error
    {
        case failedToDetectStatusCode
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny)
    {
        var line = self.unwrapInboundIn(data)
    
        guard let replyCodeString = line.readString(length: 3), let replyCode = Int(replyCodeString) else {
            context.fireErrorCaught(Error.failedToDetectStatusCode)
            return
        }
        
        let isMultilineReply = line.readString(length: 1) == "-"
        
        let text = line.readString(length: line.readableBytes) ?? ""
        multilineCache.append(text)

        guard !isMultilineReply else {
            // multiline reply; this isn't the last line, so we don't have to return a response yet
            return
        }
        
        let response = SMTPReply(code: replyCode, text: multilineCache)
        multilineCache.removeAll()
        
        context.fireChannelRead(self.wrapInboundOut(response))
    }
    
}
