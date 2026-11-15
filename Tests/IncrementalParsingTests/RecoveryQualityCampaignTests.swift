import IncrementalParsing
import XCTest

final class RecoveryQualityCampaignTests: XCTestCase {
    func testEquivalentResultsCanFailIndependentQualityGates() {
        let observation = RecoveryQualityObservation(
            revision: .init(1),
            diagnostics: [.init(severity: .error, message: "Missing delimiter",
                                range: .zero)],
            repairs: [.init(action: .insert(terminal: ";", atUTF16Offset: 0),
                            diagnosticID: "missing-link")],
            preservedConstructs: [])
        XCTAssertEqual(RecoveryQualityCampaign.violations(
            incremental: observation, fresh: observation,
            budget: .init(maximumRepairCost: 0, maximumDiagnostics: 0,
                          requiredConstructs: ["following statement"])),
            [.repairBudgetExceeded, .diagnosticBudgetExceeded,
             .missingConstructs(["following statement"]), .unlinkedDiagnostic("missing-link")])
    }
}
