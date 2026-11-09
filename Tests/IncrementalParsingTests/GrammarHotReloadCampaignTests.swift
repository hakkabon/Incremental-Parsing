import XCTest
@testable import IncrementalParsing

final class GrammarHotReloadCampaignTests: XCTestCase {
    func testCampaignValidatesActivationAndRejectedRevisionAtomicity() async throws {
        let candidates = [
            GrammarHotReloadCandidate(
                id: "valid", sourceFingerprint: "g1", targetFingerprint: "g2",
                documentRevision: 2, expectsActivation: true),
            GrammarHotReloadCandidate(
                id: "invalid", sourceFingerprint: "g2", targetFingerprint: nil,
                documentRevision: 3, expectsActivation: false),
        ]
        let report = try await GrammarHotReloadCampaignRunner.run(
            id: "campaign", initialFingerprint: "g1",
            initialDocumentRevision: 1, candidates: candidates
        ) { candidate in
            if candidate.id == "valid" {
                return .init(
                    candidateID: candidate.id, activated: true,
                    activeFingerprint: "g2", documentRevision: 2,
                    equivalentToCleanRun: true,
                    evidence: .init(strategy: .incremental))
            }
            return .init(
                candidateID: candidate.id, activated: false,
                activeFingerprint: "g2", documentRevision: 2,
                equivalentToCleanRun: true,
                evidence: .init(
                    strategy: .fallback,
                    fallback: .init(code: "grammar.compilationRejected")))
        }
        XCTAssertEqual(report.observations.map(\.candidateID), ["valid", "invalid"])
    }

    func testCampaignRejectsAStaleGrammarDelta() async {
        let candidate = GrammarHotReloadCandidate(
            id: "stale", sourceFingerprint: "wrong", targetFingerprint: "g2",
            documentRevision: 2, expectsActivation: true)
        do {
            _ = try await GrammarHotReloadCampaignRunner.run(
                id: "campaign", initialFingerprint: "g1",
                initialDocumentRevision: 1, candidates: [candidate]) { _ in
                    XCTFail("stale candidate must not execute")
                    throw CancellationError()
                }
            XCTFail("expected fingerprint failure")
        } catch let error as GrammarHotReloadCampaignError {
            XCTAssertEqual(error, .fingerprintMismatch(candidateID: "stale"))
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
