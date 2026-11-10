import XCTest
@testable import IncrementalParsing

final class RecoveryTests: XCTestCase {
    func testDiagnosticKeepsExpectationOrderAndIdentityWhenRelocated() {
        let diagnostic = ParseDiagnostic(
            severity: .error,
            message: "expected expression",
            range: SourceRange(location: 4, length: 1),
            expected: ["identifier", "number"])

        let relocated = diagnostic.relocated(by: 6)

        XCTAssertEqual(diagnostic.expected, ["identifier", "number"])
        XCTAssertEqual(relocated.id, diagnostic.id)
        XCTAssertEqual(relocated.range, SourceRange(location: 10, length: 1))
    }

    enum Kind: Hashable, Sendable { case identifier, semicolon }

    func testPlanEnforcesCostBudget() throws {
        let step = RecoveryStep<Kind, Int>(
            action: .insert(.semicolon, at: 3), expected: [.semicolon], cost: 2)
        let plan = try RecoveryPlan(steps: [step], maximumCost: 2)
        XCTAssertEqual(plan.totalCost, 2)
        XCTAssertThrowsError(try RecoveryPlan(steps: [step], maximumCost: 1))
    }

    func testSkipRetainsAffectedStableTokensAndDiagnosticLink() {
        let step = RecoveryStep<Kind, Int>(
            action: .skip([4, 5], range: SourceRange(10, 14)),
            expected: [.semicolon], cost: 2, diagnosticID: "d1")
        XCTAssertEqual(step.action.range, SourceRange(10, 14))
        XCTAssertEqual(step.diagnosticID, "d1")
    }
}
