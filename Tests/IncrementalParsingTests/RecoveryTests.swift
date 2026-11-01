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
}
