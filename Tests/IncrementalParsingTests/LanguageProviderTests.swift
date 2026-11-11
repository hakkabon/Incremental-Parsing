import XCTest
@testable import IncrementalParsing

final class LanguageProviderTests: XCTestCase {
    func testEmbeddedRegionsAreOrderedAndSurviveAnalysisCoding() throws {
        let analysis = LanguageProviderAnalysis(
            languageID: "html", revision: .init(3),
            embeddedRegions: [
                .init(id: "json.0", languageID: "json",
                      range: .init(location: 20, length: 4)),
                .init(id: "css.0", languageID: "css",
                      range: .init(location: 5, length: 8)),
            ])

        XCTAssertEqual(analysis.embeddedRegions.map(\.id), ["css.0", "json.0"])
        let data = try JSONEncoder().encode(analysis)
        XCTAssertEqual(try JSONDecoder().decode(
            LanguageProviderAnalysis.self, from: data).embeddedRegions,
            analysis.embeddedRegions)
    }

    func testProviderAnalysisKeepsOperationEvidenceIndependent() throws {
        let analysis = LanguageProviderAnalysis(
            languageID: "sample",
            revision: .init(3),
            tokens: [.init(
                range: .init(location: 0, length: 3),
                classification: "keyword")],
            recoveryEdits: [
                .init(
                    action: .insert(terminal: ";", atUTF16Offset: 3),
                    expected: [";"], diagnosticID: "sample.0"),
                .init(action: .delete(
                    terminal: "noise", range: .init(location: 4, length: 5))),
            ],
            operations: [
                .init(operation: "semantics", evidence: .init(
                    strategy: .incremental,
                    measurements: [.init(
                        dimension: .semanticNodes, reused: 2, rebuilt: 1)])),
                .init(operation: "lexing", evidence: .init(
                    strategy: .incremental,
                    measurements: [.init(
                        dimension: .tokens, reused: 4, rebuilt: 1)])),
            ])

        XCTAssertEqual(analysis.operations.map(\.operation), ["lexing", "semantics"])
        XCTAssertEqual(
            analysis.evidence(for: "lexing")?.measurements.first?.dimension,
            .tokens)
        XCTAssertEqual(
            analysis.evidence(for: "semantics")?.measurements.first?.dimension,
            .semanticNodes)
        XCTAssertEqual(analysis.recoveryEdits.count, 2)
        XCTAssertEqual(analysis.recoveryEdits[0].range.location, 3)
        XCTAssertEqual(try JSONDecoder().decode(
            LanguageProviderAnalysis.self,
            from: JSONEncoder().encode(analysis)), analysis)
    }

    func testDescriptorCanonicalizesExtensions() {
        let descriptor = LanguageProviderDescriptor(
            id: "markdown", displayName: "Markdown",
            fileExtensions: ["md", "markdown", "md"],
            distribution: .bundledPermanent,
            capabilities: [.syntaxHighlighting, .preview])

        XCTAssertEqual(descriptor.fileExtensions, ["markdown", "md"])
        XCTAssertEqual(descriptor.distribution, .bundledPermanent)
    }

    func testRecoveryPlanProjectsToPortableSourceCoordinates() throws {
        let plan = try RecoveryPlan<String, String>(steps: [
            .init(
                action: .replace(
                    "token.0", range: .init(location: 4, length: 2),
                    with: ";"),
                expected: [";"], cost: 2, diagnosticID: "parser.0"),
        ], maximumCost: 2)

        let edits = plan.languageProviderEdits(
            terminalName: { $0 }, tokenName: { _ in "identifier" })
        XCTAssertEqual(edits, [.init(
            action: .replace(
                terminal: "identifier",
                range: .init(location: 4, length: 2), with: ";"),
            expected: [";"], cost: 2, diagnosticID: "parser.0")])
    }
}
