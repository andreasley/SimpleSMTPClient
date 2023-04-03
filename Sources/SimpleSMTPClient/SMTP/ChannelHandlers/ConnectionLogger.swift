import Foundation
import NIO
import Logging

final class ConnectionLogger: ChannelDuplexHandler
{
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    let logger: Logger
    
    init(logTo logger: Logger)
    {
        self.logger = logger
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny)
    {
        let buffer = self.unwrapInboundIn(data)
        logger.info("SMTPClient read: \(String(decoding: buffer.readableBytesView, as: UTF8.self))")
        context.fireChannelRead(data)
    }
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?)
    {
        let buffer = self.unwrapOutboundIn(data)
        logger.info("SMTPClient wrote: \(String(decoding: buffer.readableBytesView, as: UTF8.self))")
        context.write(data, promise: promise)
    }
}
