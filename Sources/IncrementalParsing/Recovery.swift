public enum DiagnosticSeverity: String, Sendable, Codable {
    case error
    case warning
    case information
}

public struct ParseDiagnostic<Expected: Sendable & Hashable>: Sendable, Equatable,
    Identifiable {
    public let id: String
    public let severity: DiagnosticSeverity
    public let message: String
    public let range: SourceRange
    public let expected: [Expected]

    public init(id: String? = nil, severity: DiagnosticSeverity, message: String,
                range: SourceRange, expected: [Expected] = []) {
        self.id = id ?? "\(range.location):\(range.length):\(message)"
        self.severity = severity
        self.message = message
        self.range = range
        self.expected = expected
    }

    public func relocated(by delta: Int) -> Self {
        Self(
            id: id, severity: severity, message: message,
            range: SourceRange(
                location: range.location + delta, length: range.length),
            expected: expected)
    }
}

/// A parser-neutral repair. Token identity is deliberately generic so engines
/// can retain their own stable token IDs without exposing token implementations.
public enum RecoveryAction<TokenKind: Sendable & Hashable,
                           TokenID: Sendable & Hashable>: Sendable, Equatable {
    case insert(TokenKind, at: Int)
    case delete(TokenID, range: SourceRange)
    case replace(TokenID, range: SourceRange, with: TokenKind)
    case skip([TokenID], range: SourceRange)

    public var range: SourceRange {
        switch self {
        case let .insert(_, offset): SourceRange(location: offset, length: 0)
        case let .delete(_, range), let .replace(_, range, _),
             let .skip(_, range): range
        }
    }
}

public struct RecoveryStep<TokenKind: Sendable & Hashable,
                           TokenID: Sendable & Hashable>: Sendable, Equatable {
    public let action: RecoveryAction<TokenKind, TokenID>
    public let expected: Set<TokenKind>
    public let cost: Int
    public let diagnosticID: String?

    public init(action: RecoveryAction<TokenKind, TokenID>,
                expected: Set<TokenKind> = [], cost: Int = 1,
                diagnosticID: String? = nil) {
        precondition(cost > 0, "recovery steps must make positive progress")
        self.action = action
        self.expected = expected
        self.cost = cost
        self.diagnosticID = diagnosticID
    }
}

public struct RecoveryPlan<TokenKind: Sendable & Hashable,
                           TokenID: Sendable & Hashable>: Sendable, Equatable {
    public let steps: [RecoveryStep<TokenKind, TokenID>]
    public let maximumCost: Int

    public init(steps: [RecoveryStep<TokenKind, TokenID>], maximumCost: Int) throws {
        guard maximumCost >= 0 else { throw RecoveryPlanError.invalidBudget }
        let total = steps.reduce(0) { $0 + $1.cost }
        guard total <= maximumCost else {
            throw RecoveryPlanError.budgetExceeded(cost: total, maximum: maximumCost)
        }
        self.steps = steps
        self.maximumCost = maximumCost
    }

    public var totalCost: Int { steps.reduce(0) { $0 + $1.cost } }
    public var isClean: Bool { steps.isEmpty }
}

public enum RecoveryPlanError: Error, Sendable, Equatable {
    case invalidBudget
    case budgetExceeded(cost: Int, maximum: Int)
}
