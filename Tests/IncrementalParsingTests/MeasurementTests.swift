import Foundation
import XCTest
@testable import IncrementalParsing

final class MeasurementTests: XCTestCase {
    private let environment = IncrementalMeasurementEnvironment(
        hostID: "ci-mac", operatingSystem: "macOS 15",
        architecture: "arm64", swiftVersion: "6.1")

    private func evidence(reused: Int = 8, rebuilt: Int = 2,
                          fallback: Bool = false) -> IncrementalExecutionEvidence {
        .init(
            strategy: fallback ? .fallback : .incremental,
            fallback: fallback ? .unsupportedEdit : nil,
            measurements: [.init(
                dimension: .syntaxNodes, reused: reused, rebuilt: rebuilt,
                strategy: "stable-node")])
    }

    func testRunnerWarmsUpAggregatesAndUsesNearestRankPercentiles() throws {
        var times: [UInt64] = [100, 110, 200, 230, 300, 350]
        var iterations: [Int] = []
        let report = try IncrementalMeasurementRunner.run(
            protocol: .init(id: "editor-campaign", warmupIterations: 1,
                            measurementIterations: 3),
            environment: environment,
            artifact: .init(id: "pl0", revision: 4, fingerprint: "abcd"),
            scenarios: [.init(id: "middle-edit", title: "Edit in procedure body")],
            clock: { times.removeFirst() },
            operation: { _, iteration in
                iterations.append(iteration)
                return .init(evidence: self.evidence(), equivalentToCleanRun: true)
            })

        XCTAssertEqual(iterations, [-1, 0, 1, 2])
        let summary = try XCTUnwrap(report.summaries.first)
        XCTAssertEqual(summary.sampleCount, 3)
        XCTAssertEqual(summary.minimumNanoseconds, 10)
        XCTAssertEqual(summary.medianNanoseconds, 30)
        XCTAssertEqual(summary.percentile95Nanoseconds, 50)
        XCTAssertEqual(summary.measurement(for: .syntaxNodes)?.reused, 24)
        XCTAssertEqual(summary.measurement(for: .syntaxNodes)?.rebuilt, 6)
        XCTAssertTrue(report.allOperationsEquivalent)
    }

    func testCorrectnessAndMeasurementFingerprintsHaveSeparateBoundaries() throws {
        func report(host: String, times: [UInt64]) throws -> IncrementalMeasurementReport {
            var clockValues = times
            return try IncrementalMeasurementRunner.run(
                protocol: .init(id: "p", warmupIterations: 0,
                                measurementIterations: 2),
                environment: .init(hostID: host, operatingSystem: "macOS",
                                   architecture: "arm64", swiftVersion: "6.1"),
                scenarios: [.init(id: "edit", title: "Edit")],
                clock: { clockValues.removeFirst() },
                operation: { _, _ in .init(
                    evidence: self.evidence(), equivalentToCleanRun: true) })
        }
        let first = try report(host: "a", times: [0, 10, 20, 30])
        let second = try report(host: "b", times: [0, 20, 30, 50])

        XCTAssertEqual(first.evidenceFingerprint, second.evidenceFingerprint)
        XCTAssertNotEqual(first.measurementFingerprint, second.measurementFingerprint)
        XCTAssertFalse(first.isTimingComparable(to: second))
    }

    func testBudgetsGateCorrectnessFallbackTimingAndReuseIndependently() throws {
        var times: [UInt64] = [0, 100]
        let report = try IncrementalMeasurementRunner.run(
            protocol: .init(id: "p", warmupIterations: 0,
                            measurementIterations: 1),
            environment: environment,
            scenarios: [.init(id: "edit", title: "Edit")],
            clock: { times.removeFirst() },
            operation: { _, _ in .init(
                evidence: self.evidence(reused: 1, rebuilt: 3, fallback: true),
                equivalentToCleanRun: false) })
        let evaluation = report.evaluate([.init(
            scenarioID: "edit", maximumFallbackCount: 0,
            maximumMedianNanoseconds: 50,
            minimumReuseRatios: [.syntaxNodes: 0.5])])

        XCTAssertFalse(evaluation.passed)
        XCTAssertEqual(evaluation.violations.count, 4)
        XCTAssertTrue(evaluation.violations.contains { $0.contains("clean equivalence") })
        XCTAssertTrue(evaluation.violations.contains { $0.contains("fallbacks") })
        XCTAssertTrue(evaluation.violations.contains { $0.contains("median") })
        XCTAssertTrue(evaluation.violations.contains { $0.contains("syntaxNodes") })
    }

    func testJSONRoundTripVerifiesDerivedEvidence() throws {
        var times: [UInt64] = [4, 9]
        let report = try IncrementalMeasurementRunner.run(
            protocol: .init(id: "p", warmupIterations: 0,
                            measurementIterations: 1),
            environment: environment,
            scenarios: [.init(id: "edit", title: "Edit")],
            clock: { times.removeFirst() },
            operation: { _, _ in .init(
                evidence: self.evidence(), equivalentToCleanRun: true) })
        XCTAssertEqual(try IncrementalMeasurementReport.decode(report.json()), report)

        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: report.json()) as? [String: Any])
        object["evidenceFingerprint"] = "0000000000000000"
        let tampered = try JSONSerialization.data(withJSONObject: object)
        XCTAssertThrowsError(try IncrementalMeasurementReport.decode(tampered))
    }

    func testBudgetDecodingRejectsInvalidPolicy() throws {
        let invalid = Data("""
        {
          "scenarioID": "edit",
          "requireCleanEquivalence": true,
          "maximumFallbackCount": -1,
          "minimumReuseRatios": ["syntaxNodes", 1.5]
        }
        """.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(
            IncrementalMeasurementBudget.self, from: invalid))
    }

    func testDuplicateAndEmptyScenarioSuitesFail() throws {
        let scenario = IncrementalMeasurementScenario(id: "edit", title: "Edit")
        XCTAssertThrowsError(try IncrementalMeasurementRunner.run(
            protocol: .init(id: "p"), environment: environment,
            scenarios: [scenario, scenario],
            operation: { _, _ in .init(
                evidence: self.evidence(), equivalentToCleanRun: true) }))
        XCTAssertThrowsError(try IncrementalMeasurementRunner.run(
            protocol: .init(id: "p"), environment: environment,
            scenarios: [],
            operation: { _, _ in .init(
                evidence: self.evidence(), equivalentToCleanRun: true) }))
    }

    func testAsyncRunnerSupportsActorBackedClients() async throws {
        actor Counter {
            var value = 0
            func next() -> Int { value += 1; return value }
        }
        let counter = Counter()
        var times: [UInt64] = [0, 7]
        let report = try await IncrementalMeasurementRunner.run(
            protocol: .init(id: "async", warmupIterations: 0,
                            measurementIterations: 1),
            environment: environment,
            scenarios: [.init(id: "actor", title: "Actor session")],
            clock: { times.removeFirst() },
            operation: { _, _ in
                _ = await counter.next()
                return .init(evidence: self.evidence(), equivalentToCleanRun: true)
            })
        XCTAssertEqual(report.summaries.first?.medianNanoseconds, 7)
        let next = await counter.next()
        XCTAssertEqual(next, 2)
    }
}
