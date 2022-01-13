// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SSDPClient",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(name: "SSDPClient", targets: ["SSDPClient"]),
    ],
    dependencies: [
        .package(name: "Socket", url: "https://github.com/Kitura/BlueSocket.git", from: "1.0.200"),
    ],
    targets: [
        .target(
            name: "SSDPClient",
            dependencies: [
                "Socket",
            ]
        ),
        .testTarget(
            name: "SSDPClientTests",
            dependencies: ["SSDPClient"]
        ),
    ]
)
