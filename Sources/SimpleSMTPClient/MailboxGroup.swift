import Foundation

extension Array where Iterator.Element == Recipient
{
    var mailboxGroup:String {
        return self.map { $0.mailbox }.joined(separator: ",")
    }
}
