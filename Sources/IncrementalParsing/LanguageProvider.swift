/// Describes how a provider reaches a consumer. Distribution is deliberately
/// separate from capabilities: bundled providers and external kits use the
/// same session API.
public enum LanguageProviderDistribution: String, Hashable, Codable, Sendable {
    case bundledPermanent
    case externalLanguageKit
    case hostDefined
}

public enum LanguageProviderCapability: String, Hashable, Codable, Sendable {
    case syntaxHighlighting
    case incrementalAnalysis
    case diagnostics
    case recovery
    case formatting
    case preview
    case semantics
    case compilation
    case execution
    case embeddedLanguages
}

public struct LanguageProviderDescriptor: Hashable, Codable, Sendable {
    public let id: String
    public let displayName: String
    public let fileExtensions: [String]
    public let distribution: LanguageProviderDistribution
    public let capabilities: Set<LanguageProviderCapability>

    public init(
        id: String,
        displayName: String,
        fileExtensions: [String],
        distribution: LanguageProviderDistribution,
        capabilities: Set<LanguageProviderCapability>
    ) {
        precondition(!id.isEmpty && !displayName.isEmpty,
                     "language provider identity cannot be empty")
        precondition(fileExtensions.allSatisfy { !$0.isEmpty },
                     "language provider extensions cannot be empty")
        self.id = id
        self.displayName = displayName
        self.fileExtensions = Array(Set(fileExtensions)).sorted()
        self.distribution = distribution
        self.capabilities = capabilities
    }
}

public struct LanguageProviderToken: Hashable, Codable, Sendable {
    public let range: SourceRange
    /// Open classification name such as `keyword`, `comment`, or
    /// `symbol.variable`. Rendering remains a consumer responsibility.
    public let classification: String
    public let modifiers: Set<String>

    public init(range: SourceRange, classification: String,
                modifiers: Set<String> = []) {
        precondition(!classification.isEmpty,
                     "a provider token needs a classification")
        self.range = range
        self.classification = classification
        self.modifiers = modifiers
    }
}

public struct LanguageProviderDiagnostic: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let severity: DiagnosticSeverity
    public let message: String
    public let range: SourceRange
    public let expected: [String]

    public init(id: String? = nil, severity: DiagnosticSeverity, message: String,
                range: SourceRange, expected: [String] = []) {
        precondition(!message.isEmpty, "a provider diagnostic needs a message")
        self.id = id ?? "\(range.location):\(range.length):\(message)"
        self.severity = severity
        self.message = message
        self.range = range
        self.expected = Array(Set(expected)).sorted()
    }

    public func relocated(by delta: Int, idPrefix: String? = nil) -> Self {
        .init(
            id: idPrefix.map { "\($0).\(id)" } ?? id,
            severity: severity, message: message,
            range: .init(location: range.location + delta, length: range.length),
            expected: expected)
    }
}

/// A half-open region whose contents are owned by another language provider.
/// Delimiters remain owned by the host; `range` covers only the embedded text.
public struct EmbeddedLanguageRegion: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let languageID: String
    public let range: SourceRange

    public init(id: String, languageID: String, range: SourceRange) {
        precondition(!id.isEmpty && !languageID.isEmpty)
        self.id = id
        self.languageID = languageID
        self.range = range
    }

    public func relocated(by delta: Int) -> Self {
        Self(
            id: id, languageID: languageID,
            range: .init(
                location: range.location + delta, length: range.length))
    }
}

/// A parser-neutral repair expressed entirely in UTF-16 source coordinates.
/// Token indices remain an engine concern and must be projected before a
/// repair crosses the language-provider boundary.
public enum LanguageProviderRecoveryAction: Hashable, Codable, Sendable {
    case insert(terminal: String, atUTF16Offset: Int)
    case delete(terminal: String, range: SourceRange)
    case replace(terminal: String, range: SourceRange, with: String)
    case skip(terminals: [String], range: SourceRange)

    public var range: SourceRange {
        switch self {
        case .insert(_, let offset): .init(location: offset, length: 0)
        case .delete(_, let range), .replace(_, let range, _),
             .skip(_, let range): range
        }
    }

    public func relocated(by delta: Int) -> Self {
        let moved = SourceRange(
            location: range.location + delta, length: range.length)
        switch self {
        case .insert(let terminal, _):
            return .insert(terminal: terminal, atUTF16Offset: moved.location)
        case .delete(let terminal, _):
            return .delete(terminal: terminal, range: moved)
        case .replace(let terminal, _, let replacement):
            return .replace(terminal: terminal, range: moved, with: replacement)
        case .skip(let terminals, _):
            return .skip(terminals: terminals, range: moved)
        }
    }
}

/// One portable recovery step. Expected terminals, cost, and diagnostic
/// identity stay attached so consumers do not need parser-specific side data.
public struct LanguageProviderRecoveryEdit: Hashable, Codable, Sendable {
    public let action: LanguageProviderRecoveryAction
    public let expected: [String]
    public let cost: Int
    public let diagnosticID: String?

    public init(
        action: LanguageProviderRecoveryAction,
        expected: [String] = [],
        cost: Int = 1,
        diagnosticID: String? = nil
    ) {
        precondition(cost > 0, "provider recovery must make positive progress")
        self.action = action
        self.expected = Array(Set(expected)).sorted()
        self.cost = cost
        self.diagnosticID = diagnosticID
    }

    public var range: SourceRange { action.range }

    public func relocated(by delta: Int, diagnosticIDPrefix: String? = nil) -> Self {
        .init(action: action.relocated(by: delta), expected: expected,
              cost: cost,
              diagnosticID: diagnosticID.map { id in
                  diagnosticIDPrefix.map { "\($0).\(id)" } ?? id
              })
    }
}

public extension RecoveryPlan {
    /// Projects an engine-neutral recovery plan onto the provider boundary
    /// without reintroducing token coordinates. Token names are supplied by
    /// the owning lexer because stable token identities are intentionally
    /// opaque to this package.
    func languageProviderEdits(
        terminalName: (TokenKind) -> String,
        tokenName: (TokenID) -> String
    ) -> [LanguageProviderRecoveryEdit] {
        steps.map { step in
            let action: LanguageProviderRecoveryAction
            switch step.action {
            case .insert(let terminal, let offset):
                action = .insert(
                    terminal: terminalName(terminal), atUTF16Offset: offset)
            case .delete(let id, let range):
                action = .delete(terminal: tokenName(id), range: range)
            case .replace(let id, let range, let replacement):
                action = .replace(
                    terminal: tokenName(id), range: range,
                    with: terminalName(replacement))
            case .skip(let ids, let range):
                action = .skip(terminals: ids.map(tokenName), range: range)
            }
            return .init(
                action: action,
                expected: step.expected.map(terminalName),
                cost: step.cost,
                diagnosticID: step.diagnosticID)
        }
    }
}

/// Evidence is named by operation so consumers never merge unlike native
/// units into a single reuse number.
public struct LanguageProviderOperationEvidence: Hashable, Codable, Sendable {
    public let operation: String
    public let evidence: IncrementalExecutionEvidence

    public init(operation: String, evidence: IncrementalExecutionEvidence) {
        precondition(!operation.isEmpty, "provider evidence needs an operation")
        self.operation = operation
        self.evidence = evidence
    }
}

public struct LanguageProviderAnalysis: Hashable, Codable, Sendable {
    public let languageID: String
    public let revision: SourceRevision
    public let artifact: IncrementalArtifactIdentity?
    public let tokens: [LanguageProviderToken]
    public let diagnostics: [LanguageProviderDiagnostic]
    public let recoveryEdits: [LanguageProviderRecoveryEdit]
    public let embeddedRegions: [EmbeddedLanguageRegion]
    public let operations: [LanguageProviderOperationEvidence]

    public init(
        languageID: String,
        revision: SourceRevision,
        artifact: IncrementalArtifactIdentity? = nil,
        tokens: [LanguageProviderToken] = [],
        diagnostics: [LanguageProviderDiagnostic] = [],
        recoveryEdits: [LanguageProviderRecoveryEdit] = [],
        embeddedRegions: [EmbeddedLanguageRegion] = [],
        operations: [LanguageProviderOperationEvidence] = []
    ) {
        precondition(!languageID.isEmpty, "provider analysis needs a language ID")
        precondition(Set(operations.map(\.operation)).count == operations.count,
                     "provider operation names must be unique")
        self.languageID = languageID
        self.revision = revision
        self.artifact = artifact
        self.tokens = tokens
        self.diagnostics = diagnostics
        self.recoveryEdits = recoveryEdits
        precondition(Set(embeddedRegions.map(\.id)).count == embeddedRegions.count,
                     "embedded region IDs must be unique")
        self.embeddedRegions = embeddedRegions.sorted {
            ($0.range.location, $0.id) < ($1.range.location, $1.id)
        }
        self.operations = operations.sorted { $0.operation < $1.operation }
    }

    public func evidence(for operation: String) -> IncrementalExecutionEvidence? {
        operations.first { $0.operation == operation }?.evidence
    }

    private enum CodingKeys: String, CodingKey {
        case languageID, revision, artifact, tokens, diagnostics, recoveryEdits,
             embeddedRegions, operations
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            languageID: try values.decode(String.self, forKey: .languageID),
            revision: try values.decode(SourceRevision.self, forKey: .revision),
            artifact: try values.decodeIfPresent(
                IncrementalArtifactIdentity.self, forKey: .artifact),
            tokens: try values.decodeIfPresent(
                [LanguageProviderToken].self, forKey: .tokens) ?? [],
            diagnostics: try values.decodeIfPresent(
                [LanguageProviderDiagnostic].self, forKey: .diagnostics) ?? [],
            recoveryEdits: try values.decodeIfPresent(
                [LanguageProviderRecoveryEdit].self, forKey: .recoveryEdits) ?? [],
            embeddedRegions: try values.decodeIfPresent(
                [EmbeddedLanguageRegion].self, forKey: .embeddedRegions) ?? [],
            operations: try values.decodeIfPresent(
                [LanguageProviderOperationEvidence].self, forKey: .operations) ?? [])
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(languageID, forKey: .languageID)
        try values.encode(revision, forKey: .revision)
        try values.encodeIfPresent(artifact, forKey: .artifact)
        try values.encode(tokens, forKey: .tokens)
        try values.encode(diagnostics, forKey: .diagnostics)
        try values.encode(recoveryEdits, forKey: .recoveryEdits)
        try values.encode(embeddedRegions, forKey: .embeddedRegions)
        try values.encode(operations, forKey: .operations)
    }
}

public enum LanguageProviderError: Error, Hashable, Sendable {
    case unsupportedCapability(LanguageProviderCapability)
    case inconsistentChange
}

/// One provider instance is immutable and cheap. Mutable document state belongs
/// to the actor returned by `makeSession()`.
public protocol LanguageProvider: Sendable {
    var descriptor: LanguageProviderDescriptor { get }
    func makeSession() -> any LanguageProviderSession
}

public protocol LanguageProviderSession: Actor {
    func analyze(_ snapshot: SourceSnapshot, change: SourceChange?) async throws
        -> LanguageProviderAnalysis
    func format(_ snapshot: SourceSnapshot) async throws -> String
    func previewHTML(_ snapshot: SourceSnapshot) async throws -> String?
}

public extension LanguageProviderSession {
    func analyze(_ snapshot: SourceSnapshot) async throws
        -> LanguageProviderAnalysis {
        try await analyze(snapshot, change: nil)
    }

    func format(_ snapshot: SourceSnapshot) async throws -> String {
        throw LanguageProviderError.unsupportedCapability(.formatting)
    }

    func previewHTML(_ snapshot: SourceSnapshot) async throws -> String? {
        throw LanguageProviderError.unsupportedCapability(.preview)
    }
}
