import XCTest
@testable import IncrementalParsing

final class OperationalEvidenceTests: XCTestCase {
    func testEvidenceSortsOpenDimensionsAndRequiresTruthfulFallback() {
        let evidence = IncrementalExecutionEvidence(
            strategy: .incremental,
            measurements: [
                .init(dimension: .syntaxNodes, reused: 3, rebuilt: 1),
                .init(dimension: .tokens, reused: 8, rebuilt: 2),
            ])
        XCTAssertEqual(evidence.measurements.map(\.dimension), [.syntaxNodes, .tokens])

        let fallback = IncrementalExecutionEvidence(
            strategy: .fallback,
            fallback: .missingCheckpoint)
        XCTAssertEqual(fallback.fallback?.code, "missingCheckpoint")
    }

    func testEvidenceCodingRoundTripsOpenDimensions() throws {
        let evidence = IncrementalExecutionEvidence(
            strategy: .incremental,
            measurements: [
                .init(
                    dimension: .init(rawValue: "engine.customNodes"),
                    reused: 4,
                    rebuilt: 2,
                    strategy: "dependency-indexed")
            ])

        let data = try JSONEncoder().encode(evidence)
        XCTAssertEqual(try JSONDecoder().decode(
            IncrementalExecutionEvidence.self, from: data), evidence)
    }

    func testEvidenceDecodingRejectsContradictoryFallbackAndDuplicateDimensions() {
        let contradictory = Data(#"""
        {
          "strategy":"incremental",
          "fallback":{"code":"missingCheckpoint"},
          "measurements":[]
        }
        """#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(
            IncrementalExecutionEvidence.self, from: contradictory))

        let duplicates = Data(#"""
        {
          "strategy":"incremental",
          "measurements":[
            {"dimension":"tokens","reused":1,"rebuilt":0,"removed":0},
            {"dimension":"tokens","reused":2,"rebuilt":0,"removed":0}
          ]
        }
        """#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(
            IncrementalExecutionEvidence.self, from: duplicates))
    }

    func testEvidenceDecodingRejectsInvalidLeafValues() {
        let negativeCount = Data(#"""
        {
          "dimension":"tokens","reused":-1,"rebuilt":0,"removed":0
        }
        """#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(
            ReuseMeasurement.self, from: negativeCount))

        let emptyDimension = Data("\"\"".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(
            ReuseDimension.self, from: emptyDimension))
    }
}
