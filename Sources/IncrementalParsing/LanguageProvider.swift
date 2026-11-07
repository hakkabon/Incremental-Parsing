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

public struct LanguageProviderDiagnostic: Hashable, Codable, Sendable {
    public let severity: DiagnosticSeverity
    public let message: String
    public let range: SourceRange
    public let expected: [String]

    public init(severity: DiagnosticSeverity, message: String,
                range: SourceRange, expected: [String] = []) {
        precondition(!message.isEmpty, "a provider diagnostic needs a message")
        self.severity = severity
        self.message = message
        self.range = range
        self.expected = Array(Set(expected)).sorted()
    }
}

/// Parser-neutral repair evidence exposed at the language-provider boundary.
/// Token positions are used because providers already publish the token stream;
/// source ranges remain available on deletion diagnostics and tokens.
public enum LanguageProviderRecoveryEdit: Hashable, Codable, Sendable {
    case insert(terminal: String, atToken: Int)
    case delete(terminal: String, atToken: Int)
    case skip(terminals: [String], fromToken: Int)
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
    public let operations: [LanguageProviderOperationEvidence]

    public init(
        languageID: String,
        revision: SourceRevision,
        artifact: IncrementalArtifactIdentity? = nil,
        tokens: [LanguageProviderToken] = [],
        diagnostics: [LanguageProviderDiagnostic] = [],
        recoveryEdits: [LanguageProviderRecoveryEdit] = [],
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
        self.operations = operations.sorted { $0.operation < $1.operation }
    }

    public func evidence(for operation: String) -> IncrementalExecutionEvidence? {
        operations.first { $0.operation == operation }?.evidence
    }

    private enum CodingKeys: String, CodingKey {
        case languageID, revision, artifact, tokens, diagnostics, recoveryEdits, operations
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
