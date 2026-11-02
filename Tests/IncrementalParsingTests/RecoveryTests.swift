import XCTest
@testable import IncrementalParsing

final class RecoveryTests: XCTestCase {
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
