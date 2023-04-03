import Foundation

public struct Multipart
{
    public enum Subtype
    {
        case alternative
        case mixed
        case related
        
        var mediaType:String {
            switch self {
            case .alternative:
                return "multipart/alternative"
            case .mixed:
                return "multipart/mixed"
            case .related:
                return "multipart/related"
            }
        }
    }

    let subtype:Subtype
    let boundary:String
    
    var parts:[AnyPart]
    
    init(_ subtype:Subtype, parts:[Part] = [])
    {
        self.parts = parts
        self.subtype = subtype
        self.boundary = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}

extension Multipart : AnyPart {}
