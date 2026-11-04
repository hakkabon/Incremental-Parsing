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
        .executable(name: "incremental-report", targets: ["IncrementalReportCLI"]),
    ],
    targets: [
        .target(name: "IncrementalParsing"),
        .executableTarget(
            name: "IncrementalReportCLI",
            dependencies: ["IncrementalParsing"]),
        .testTarget(
            name: "IncrementalParsingTests",
            dependencies: ["IncrementalParsing"]),
    ]
)
