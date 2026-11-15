/// Facts projected by a language-specific typing campaign for one revision.
/// Construct identity and the recoverable suffix are selected by the fixture.
public struct RecoveryQualityObservation: Equatable, Codable, Sendable {
    public let revision: SourceRevision
    public let diagnostics: [LanguageProviderDiagnostic]
    public let repairs: [LanguageProviderRecoveryEdit]
    public let preservedConstructs: Set<String>

    public init(
        revision: SourceRevision, diagnostics: [LanguageProviderDiagnostic],
        repairs: [LanguageProviderRecoveryEdit], preservedConstructs: Set<String>
    ) {
        self.revision = revision
        self.diagnostics = diagnostics
        self.repairs = repairs
        self.preservedConstructs = preservedConstructs
    }
}

public struct RecoveryQualityBudget: Sendable {
    public let maximumRepairCost: Int
    public let maximumDiagnostics: Int
    public let requiredConstructs: Set<String>

    public init(
        maximumRepairCost: Int, maximumDiagnostics: Int,
        requiredConstructs: Set<String> = []
    ) {
        precondition(maximumRepairCost >= 0 && maximumDiagnostics >= 0)
        self.maximumRepairCost = maximumRepairCost
        self.maximumDiagnostics = maximumDiagnostics
        self.requiredConstructs = requiredConstructs
    }
}

public enum RecoveryQualityFailure: Equatable, Sendable {
    case freshParseMismatch
    case repairBudgetExceeded
    case invalidRepairCost
    case diagnosticBudgetExceeded
    case missingConstructs(Set<String>)
    case unlinkedDiagnostic(String)
}

public enum RecoveryQualityCampaign {
    /// Gate both differential correctness and language-specific quality.
    /// Identical incremental and fresh results can still lose valid code.
    public static func violations(
        incremental: RecoveryQualityObservation, fresh: RecoveryQualityObservation,
        budget: RecoveryQualityBudget
    ) -> [RecoveryQualityFailure] {
        var failures: [RecoveryQualityFailure] = []
        if incremental != fresh { failures.append(.freshParseMismatch) }
        var remaining = budget.maximumRepairCost
        for repair in incremental.repairs {
            guard repair.cost > 0 else {
                failures.append(.invalidRepairCost)
                break
            }
            if repair.cost > remaining {
                failures.append(.repairBudgetExceeded)
                break
            }
            remaining -= repair.cost
        }
        if incremental.diagnostics.count > budget.maximumDiagnostics {
            failures.append(.diagnosticBudgetExceeded)
        }
        let missing = budget.requiredConstructs.subtracting(incremental.preservedConstructs)
        if !missing.isEmpty { failures.append(.missingConstructs(missing)) }
        let ids = Set(incremental.diagnostics.map(\.id))
        for id in Set(incremental.repairs.compactMap(\.diagnosticID)).subtracting(ids).sorted() {
            failures.append(.unlinkedDiagnostic(id))
        }
        return failures
    }
}
