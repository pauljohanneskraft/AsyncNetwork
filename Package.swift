// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "AsyncNetwork",
    platforms: [.iOS(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v13), .macCatalyst(.v13)],
    products: [.library(name: "AsyncNetwork", targets: ["AsyncNetwork"])],
    targets: [
        .target(name: "AsyncNetwork", dependencies: [], path: "Sources"),
        .testTarget(name: "AsyncNetworkTests", dependencies: ["AsyncNetwork"], path: "Tests"),
    ]
)
