import Foundation

/// One candidate grammar revision in a hot-reload campaign. Fingerprints are
/// supplied by the grammar owner, keeping this contract independent of any
/// grammar notation or parser package.
public struct GrammarHotReloadCandidate: Hashable, Codable, Sendable {
    public let id: String
    public let sourceFingerprint: String
    public let targetFingerprint: String?
    public let documentRevision: UInt64
    public let expectsActivation: Bool

    public init(id: String, sourceFingerprint: String,
                targetFingerprint: String?, documentRevision: UInt64,
                expectsActivation: Bool) {
        precondition(!id.isEmpty && !sourceFingerprint.isEmpty)
        precondition(targetFingerprint?.isEmpty != true)
        self.id = id
        self.sourceFingerprint = sourceFingerprint
        self.targetFingerprint = targetFingerprint
        self.documentRevision = documentRevision
        self.expectsActivation = expectsActivation
    }
}

/// Result of compiling, conditionally activating, and reanalyzing one retained
/// document. Rejected candidates must preserve the previous fingerprint and
/// document revision; activated candidates must match a clean target run.
public struct GrammarHotReloadObservation: Hashable, Codable, Sendable {
    public let candidateID: String
    public let activated: Bool
    public let activeFingerprint: String
    public let documentRevision: UInt64
    public let equivalentToCleanRun: Bool
    public let evidence: IncrementalExecutionEvidence

    public init(candidateID: String, activated: Bool,
                activeFingerprint: String, documentRevision: UInt64,
                equivalentToCleanRun: Bool,
                evidence: IncrementalExecutionEvidence) {
        precondition(!candidateID.isEmpty && !activeFingerprint.isEmpty)
        self.candidateID = candidateID
        self.activated = activated
        self.activeFingerprint = activeFingerprint
        self.documentRevision = documentRevision
        self.equivalentToCleanRun = equivalentToCleanRun
        self.evidence = evidence
    }
}

public struct GrammarHotReloadCampaignReport: Hashable, Codable, Sendable {
    public let id: String
    public let observations: [GrammarHotReloadObservation]

    public init(id: String, observations: [GrammarHotReloadObservation]) {
        precondition(!id.isEmpty)
        precondition(Set(observations.map(\.candidateID)).count == observations.count,
                     "grammar campaign candidate IDs must be unique")
        self.id = id
        self.observations = observations
    }

    public func json(prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted
            ? [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            : [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }
}

public enum GrammarHotReloadCampaignError: Error, Hashable, Sendable {
    case duplicateCandidateID(String)
    case activationMismatch(candidateID: String)
    case fingerprintMismatch(candidateID: String)
    case documentRevisionMismatch(candidateID: String)
    case documentRevisionChangedOnRejection(candidateID: String)
    case cleanValidationFailed(candidateID: String)
}

/// Executes candidates sequentially and validates activation atomically. The
/// supplied operation owns compilation and engine state; this runner owns the
/// cross-product invariants and deterministic report ordering.
public enum GrammarHotReloadCampaignRunner {
    public static func run(
        id: String,
        initialFingerprint: String,
        initialDocumentRevision: UInt64,
        candidates: [GrammarHotReloadCandidate],
        operation: (GrammarHotReloadCandidate) async throws
            -> GrammarHotReloadObservation
    ) async throws -> GrammarHotReloadCampaignReport {
        var seen = Set<String>()
        var activeFingerprint = initialFingerprint
        var documentRevision = initialDocumentRevision
        var observations: [GrammarHotReloadObservation] = []
        for candidate in candidates {
            guard seen.insert(candidate.id).inserted else {
                throw GrammarHotReloadCampaignError.duplicateCandidateID(candidate.id)
            }
            guard candidate.sourceFingerprint == activeFingerprint else {
                throw GrammarHotReloadCampaignError.fingerprintMismatch(
                    candidateID: candidate.id)
            }
            let observation = try await operation(candidate)
            guard observation.candidateID == candidate.id,
                  observation.activated == candidate.expectsActivation else {
                throw GrammarHotReloadCampaignError.activationMismatch(
                    candidateID: candidate.id)
            }
            if observation.activated {
                guard observation.activeFingerprint == candidate.targetFingerprint else {
                    throw GrammarHotReloadCampaignError.fingerprintMismatch(
                        candidateID: candidate.id)
                }
                guard observation.equivalentToCleanRun else {
                    throw GrammarHotReloadCampaignError.cleanValidationFailed(
                        candidateID: candidate.id)
                }
                guard observation.documentRevision == candidate.documentRevision else {
                    throw GrammarHotReloadCampaignError.documentRevisionMismatch(
                        candidateID: candidate.id)
                }
                activeFingerprint = observation.activeFingerprint
                documentRevision = observation.documentRevision
            } else {
                guard observation.activeFingerprint == activeFingerprint else {
                    throw GrammarHotReloadCampaignError.fingerprintMismatch(
                        candidateID: candidate.id)
                }
                guard observation.documentRevision == documentRevision else {
                    throw GrammarHotReloadCampaignError
                        .documentRevisionChangedOnRejection(candidateID: candidate.id)
                }
            }
            observations.append(observation)
        }
        return .init(id: id, observations: observations)
    }
}
