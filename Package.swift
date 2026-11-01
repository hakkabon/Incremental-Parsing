// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "IncrementalParsing",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "IncrementalParsing", targets: ["IncrementalParsing"]),
    ],
    targets: [
        .target(name: "IncrementalParsing"),
        .testTarget(
            name: "IncrementalParsingTests",
            dependencies: ["IncrementalParsing"]),
    ]
)
