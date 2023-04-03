import Foundation

public struct SMTPReply
{
    public let code:Int
    public let text:[String]
    public let isSuccess:Bool
    public let isFailure:Bool

    init(code:Int, text:[String])
    {
        self.code = code
        self.text = text

        switch code {
        case 200..<400:
            isSuccess = true
            isFailure = false
        default:
            isSuccess = false
            isFailure = true
        }
    }
}
