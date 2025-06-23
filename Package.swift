// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimpleSMTPClient",
    platforms: [
        .macOS(.v13), .iOS(.v16), .tvOS(.v14), .watchOS(.v7)
    ],
    products: [
        .library(
            name: "SimpleSMTPClient",
            targets: ["SimpleSMTPClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.83.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.32.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
        .package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "3.12.3"))
    ],
    targets: [
        .target(
            name: "SimpleSMTPClient",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Crypto", package: "swift-crypto")
            ]),
        .testTarget(
            name: "SimpleSMTPClientTests",
            dependencies: ["SimpleSMTPClient"]),
    ]
)
