// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GuiltySpark",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.1"),
        .package(url: "https://github.com/NozeIO/MicroExpress.git", from: "0.5.4"),
        .package(url: "https://github.com/scaraux/Swift-Porter-Stemmer-2.git", from: "0.1.1"),
        .package(url: "https://github.com/apple/swift-markdown.git", .branch("main")),
    ],
    targets: [
        .target(
            name: "shared",
            dependencies: [
                .product(name: "PorterStemmer2", package: "swift-Porter-Stemmer-2"),
                "FrontMatter"
            ]
        ),
        .testTarget(
            name: "sharedTests",
            dependencies: ["shared"]
        ),
        .target(
            name: "FrontMatter",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .testTarget(
            name: "FrontMatterTests",
            dependencies: ["FrontMatter"]
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
                "FrontMatter",
                "shared"
            ]
        )
    ]
)
