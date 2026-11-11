import Foundation
import XCTest
@testable import IncrementalParsing

final class ReleaseManifestTests: XCTestCase {
    func testPublishedReleaseManifestIsValidAndComplete() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let data = try Data(contentsOf: root
            .appendingPathComponent("Release/EcosystemRelease.json"))
        let manifest = try JSONDecoder().decode(
            EcosystemReleaseManifest.self, from: data)
        XCTAssertEqual(manifest.components.count, 24)
        XCTAssertEqual(Set(manifest.components.filter {
            $0.layer == .product
        }.map(\.name)), ["ModEdit", "Grammar-REPL", "Grammar-Workbench"])
        XCTAssertEqual(manifest.contracts.count, 7)
    }

    func testReleaseManifestRoundTripsAndValidatesLayeredGraph() throws {
        let manifest = try fixture()
        let data = try JSONEncoder().encode(manifest)
        XCTAssertEqual(try JSONDecoder().decode(
            EcosystemReleaseManifest.self, from: data), manifest)
    }

    func testReleaseManifestRejectsMissingAndUpwardDependencies() throws {
        XCTAssertThrowsError(try EcosystemReleaseManifest(
            releaseID: "release-1", swiftToolsVersion: "5.9",
            components: [.init(
                name: "Parser", swiftPMIdentity: "parser",
                minimumVersion: "1.0.0", layer: .foundation,
                maturity: .stable, dependencies: ["Missing"])],
            contracts: [])) {
            XCTAssertEqual($0 as? EcosystemReleaseManifestError,
                           .missingDependency(component: "Parser", dependency: "Missing"))
        }
        XCTAssertThrowsError(try EcosystemReleaseManifest(
            releaseID: "release-1", swiftToolsVersion: "5.9",
            components: [
                .init(name: "Foundation", swiftPMIdentity: "foundation",
                      minimumVersion: "1.0.0", layer: .foundation,
                      maturity: .stable, dependencies: ["Product"]),
                .init(name: "Product", swiftPMIdentity: "product",
                      minimumVersion: "1.0.0", layer: .product,
                      maturity: .stable),
            ], contracts: [])) {
            XCTAssertEqual($0 as? EcosystemReleaseManifestError,
                           .upwardDependency(component: "Foundation", dependency: "Product"))
        }
    }

    func testReleaseManifestRejectsCyclesAndUnknownContractOwners() throws {
        XCTAssertThrowsError(try EcosystemReleaseManifest(
            releaseID: "release-1", swiftToolsVersion: "5.9",
            components: [
                .init(name: "A", swiftPMIdentity: "a", minimumVersion: "1.0.0",
                      layer: .foundation, maturity: .stable, dependencies: ["B"]),
                .init(name: "B", swiftPMIdentity: "b", minimumVersion: "1.0.0",
                      layer: .foundation, maturity: .stable, dependencies: ["A"]),
            ], contracts: []))
        XCTAssertThrowsError(try EcosystemReleaseManifest(
            releaseID: "release-1", swiftToolsVersion: "5.9",
            components: [.init(
                name: "Parser", swiftPMIdentity: "parser", minimumVersion: "1.0.0",
                layer: .foundation, maturity: .stable)],
            contracts: [.init(id: "parse-contract", owner: "Other", schemaVersion: 1)]))
    }

    private func fixture() throws -> EcosystemReleaseManifest {
        try .init(
            releaseID: "incremental-platform-1", swiftToolsVersion: "5.9",
            components: [
                .init(name: "Incremental-Parsing", swiftPMIdentity: "incremental-parsing",
                      minimumVersion: "1.0.0", layer: .foundation, maturity: .stable),
                .init(name: "Parser", swiftPMIdentity: "parser",
                      minimumVersion: "1.0.0", layer: .foundation, maturity: .stable,
                      dependencies: ["Incremental-Parsing"]),
                .init(name: "Earley-Parser", swiftPMIdentity: "earley-parser",
                      minimumVersion: "1.0.0", layer: .engine, maturity: .stable,
                      dependencies: ["Parser"]),
            ],
            contracts: [.init(
                id: "parse-contract", owner: "Parser", schemaVersion: 1)])
    }
}
