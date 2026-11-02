// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IncrementalParsing",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
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
