/// One revision-independent edit step in a differential campaign. The runner
/// binds it to the current source revision before applying it.
public struct DifferentialEditStep: Hashable, Codable, Sendable {
    public let id: String
    public let replacements: [SourceReplacement]

    public init(id: String, replacements: [SourceReplacement]) {
        precondition(!id.isEmpty, "a differential step ID cannot be empty")
        precondition(!replacements.isEmpty, "a differential step cannot be empty")
        self.id = id
        self.replacements = replacements
    }
}

public struct DifferentialValidationObservation: Hashable, Codable, Sendable {
    public let stepID: String
    public let revision: SourceRevision
    public let equivalent: Bool
}

public struct DifferentialValidationReport: Hashable, Codable, Sendable {
    public let observations: [DifferentialValidationObservation]

    public var isEquivalent: Bool { observations.allSatisfy(\.equivalent) }
    public var mismatchedSteps: [String] {
        observations.filter { !$0.equivalent }.map(\.stepID)
    }
}

/// Runs one stateful parser beside a newly constructed full parser at every
/// revision. Projection lets callers compare identity-neutral semantic
/// evidence while retaining engine-specific object identities in the live run.
public enum DifferentialValidation {
    public static func run<Parser: IncrementalParser, Projection: Equatable & Sendable>(
        initialText: String,
        steps: [DifferentialEditStep],
        makeParser: @Sendable () -> Parser,
        project: @Sendable (Parser.Output) -> Projection
    ) throws -> DifferentialValidationReport {
        var incrementalParser = makeParser()
        var snapshot = SourceSnapshot(text: initialText)
        var previous = try incrementalParser.parse(
            snapshot, previous: nil, change: nil)
        var fullParser = makeParser()
        let initialFull = try fullParser.parse(
            snapshot, previous: nil, change: nil)
        var observations = [DifferentialValidationObservation(
            stepID: "initial", revision: snapshot.revision,
            equivalent: project(previous) == project(initialFull))]

        for step in steps {
            let change = try SourceEditBatch(
                baseRevision: snapshot.revision,
                replacements: step.replacements
            ).applying(to: snapshot)
            let incremental = try incrementalParser.parse(
                change.after, previous: previous, change: change)
            var cleanParser = makeParser()
            let clean = try cleanParser.parse(
                change.after, previous: nil, change: nil)
            observations.append(.init(
                stepID: step.id,
                revision: change.after.revision,
                equivalent: project(incremental) == project(clean)))
            snapshot = change.after
            previous = incremental
        }
        return .init(observations: observations)
    }
}
