/// Comparable evidence for one parser engine moving between grammar artifacts.
/// Grammar packages own delta construction; engines own native invalidation.
public struct GrammarEngineTransition: Hashable, Codable, Sendable {
    public let engineID: String
    public let sourceArtifact: IncrementalArtifactIdentity
    public let targetArtifact: IncrementalArtifactIdentity
    public let appliedIncrementally: Bool
    public let requiresRetokenization: Bool
    public let evidence: IncrementalExecutionEvidence

    public init(
        engineID: String,
        sourceArtifact: IncrementalArtifactIdentity,
        targetArtifact: IncrementalArtifactIdentity,
        appliedIncrementally: Bool,
        requiresRetokenization: Bool,
        evidence: IncrementalExecutionEvidence
    ) {
        precondition(!engineID.isEmpty, "a grammar transition needs an engine ID")
        precondition(sourceArtifact != targetArtifact,
                     "a grammar transition must change artifacts")
        precondition(
            evidence.measurements.contains { $0.dimension == .grammarProductions },
            "grammar transitions must report production reuse")
        precondition(appliedIncrementally == (evidence.strategy == .incremental),
                     "incremental activation and evidence must agree")
        self.engineID = engineID
        self.sourceArtifact = sourceArtifact
        self.targetArtifact = targetArtifact
        self.appliedIncrementally = appliedIncrementally
        self.requiresRetokenization = requiresRetokenization
        self.evidence = evidence
    }
}
