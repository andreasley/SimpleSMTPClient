import Foundation

public typealias Port = Int

public extension Port
{
    static var defaultForTLS:Port {
        return 465
    }

    static var defaultForStartTLS:Port {
        return 587
    }
    
    static var defaultForUnsecured:Port {
        return 25
    }
}
