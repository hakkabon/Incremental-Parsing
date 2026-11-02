import XCTest
@testable import IncrementalParsing

private struct DifferentialParser: IncrementalParser {
    struct Output: Sendable {
        let text: String
    }

    let corruptIncrementalResult: Bool

    mutating func parse(_ snapshot: SourceSnapshot, previous: Output?,
                        change: SourceChange?) throws -> Output {
        Output(text: corruptIncrementalResult && change != nil
               ? snapshot.text + "!" : snapshot.text)
    }
}

final class DifferentialValidationTests: XCTestCase {
    private let steps = [DifferentialEditStep(
        id: "insert",
        replacements: [.init(range: SourceRange(1, 1), replacement: "x")])]

    func testCampaignAcceptsEquivalentIncrementalAndFreshResults() throws {
        let report = try DifferentialValidation.run(
            initialText: "ab", steps: steps,
            makeParser: { DifferentialParser(corruptIncrementalResult: false) },
            project: \DifferentialParser.Output.text)
        XCTAssertTrue(report.isEquivalent)
        XCTAssertEqual(report.observations.map(\.revision), [.init(0), .init(1)])
    }

    func testCampaignNamesDivergentRevision() throws {
        let report = try DifferentialValidation.run(
            initialText: "ab", steps: steps,
            makeParser: { DifferentialParser(corruptIncrementalResult: true) },
            project: \DifferentialParser.Output.text)
        XCTAssertFalse(report.isEquivalent)
        XCTAssertEqual(report.mismatchedSteps, ["insert"])
    }
}
