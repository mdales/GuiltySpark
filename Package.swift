// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swiftnio2test",
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.1"),
        .package(url: "https://github.com/NozeIO/MicroExpress.git", from: "0.5.3"),
    ],
    targets: [
        .target(
            name: "shared",
            dependencies: []
        ),
        .executableTarget(
            name: "librarian",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MicroExpress", package: "MicroExpress"),
                "shared"
            ]
        ),
        .executableTarget(
            name: "indexer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
                "shared"
            ]
        )
    ]
)
