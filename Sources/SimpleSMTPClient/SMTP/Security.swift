import Foundation

public enum Security
{
    case startTLS
    case TLS
    @available(*, deprecated, message: "Everything (including passwords) will be transmitted in plain text.")
    case insecure
//    case clientCertificate(cert: NIOSSLCertificateSource, key: NIOSSLPrivateKeySource) // TODO: implement
}
