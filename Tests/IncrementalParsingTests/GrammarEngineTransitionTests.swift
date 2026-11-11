import XCTest
@testable import IncrementalParsing

final class GrammarEngineTransitionTests: XCTestCase {
    func testTransitionRoundTripsComparableEngineEvidence() throws {
        let transition = GrammarEngineTransition(
            engineID: "earley",
            sourceArtifact: .init(id: "grammar", revision: 1, fingerprint: "g1"),
            targetArtifact: .init(id: "grammar", revision: 2, fingerprint: "g2"),
            appliedIncrementally: true,
            requiresRetokenization: false,
            evidence: .init(strategy: .incremental, measurements: [
                .init(dimension: .grammarProductions, reused: 3, rebuilt: 1),
                .init(dimension: .chartFacts, reused: 8, rebuilt: 2),
            ]))

        let data = try JSONEncoder().encode(transition)
        XCTAssertEqual(
            try JSONDecoder().decode(GrammarEngineTransition.self, from: data),
            transition)
    }
}
