import Dispatch
import Foundation

/// Describes the machine and toolchain that produced timing observations.
/// Correctness evidence deliberately does not depend on this identity.
public struct IncrementalMeasurementEnvironment: Hashable, Codable, Sendable {
    public let hostID: String
    public let operatingSystem: String
    public let architecture: String
    public let swiftVersion: String

    public init(hostID: String, operatingSystem: String,
                architecture: String, swiftVersion: String) {
        precondition(!hostID.isEmpty && !operatingSystem.isEmpty &&
                     !architecture.isEmpty && !swiftVersion.isEmpty,
                     "measurement environment fields cannot be empty")
        self.hostID = hostID
        self.operatingSystem = operatingSystem
        self.architecture = architecture
        self.swiftVersion = swiftVersion
    }

    /// Identity used to decide whether two timing reports are comparable.
    public var comparisonIdentity: String {
        [hostID, operatingSystem, architecture, swiftVersion]
            .joined(separator: "|")
    }
}

public struct IncrementalMeasurementScenario: Hashable, Codable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        precondition(!id.isEmpty && !title.isEmpty,
                     "measurement scenario fields cannot be empty")
        self.id = id
        self.title = title
    }
}

/// Reproducible execution policy. Warmups are never included in a report.
public struct IncrementalMeasurementProtocol: Hashable, Codable, Sendable {
    public let id: String
    public let warmupIterations: Int
    public let measurementIterations: Int

    public init(id: String, warmupIterations: Int = 1,
                measurementIterations: Int = 5) {
        precondition(!id.isEmpty, "a measurement protocol ID cannot be empty")
        precondition(warmupIterations >= 0,
                     "warmup iterations cannot be negative")
        precondition(measurementIterations > 0,
                     "a measurement protocol needs measured iterations")
        self.id = id
        self.warmupIterations = warmupIterations
        self.measurementIterations = measurementIterations
    }
}

/// Result returned by a measured engine or language-kit operation.
public struct IncrementalMeasuredOperation: Hashable, Codable, Sendable {
    public let evidence: IncrementalExecutionEvidence
    public let equivalentToCleanRun: Bool

    public init(evidence: IncrementalExecutionEvidence,
                equivalentToCleanRun: Bool) {
        self.evidence = evidence
        self.equivalentToCleanRun = equivalentToCleanRun
    }
}

public struct IncrementalMeasurementSample: Hashable, Codable, Sendable {
    public let scenarioID: String
    public let iteration: Int
    public let durationNanoseconds: UInt64
    public let operation: IncrementalMeasuredOperation

    public init(scenarioID: String, iteration: Int,
                durationNanoseconds: UInt64,
                operation: IncrementalMeasuredOperation) {
        precondition(!scenarioID.isEmpty, "a sample scenario ID cannot be empty")
        precondition(iteration >= 0, "a sample iteration cannot be negative")
        self.scenarioID = scenarioID
        self.iteration = iteration
        self.durationNanoseconds = durationNanoseconds
        self.operation = operation
    }
}

public struct IncrementalMeasurementTotal: Hashable, Codable, Sendable {
    public let dimension: ReuseDimension
    public let reused: Int
    public let rebuilt: Int
    public let removed: Int

    public var reuseRatio: Double? {
        let observed = reused + rebuilt
        return observed == 0 ? nil : Double(reused) / Double(observed)
    }
}

public struct IncrementalScenarioSummary: Hashable, Codable, Sendable {
    public let scenarioID: String
    public let sampleCount: Int
    public let minimumNanoseconds: UInt64
    public let medianNanoseconds: UInt64
    public let percentile95Nanoseconds: UInt64
    public let fallbackCount: Int
    public let correctnessFailureCount: Int
    public let reuse: [IncrementalMeasurementTotal]

    public func measurement(for dimension: ReuseDimension)
        -> IncrementalMeasurementTotal? {
        reuse.first { $0.dimension == dimension }
    }
}

/// A quality gate remains separate from the measurement protocol so the same
/// raw report can be evaluated by local, CI, and release policies.
public struct IncrementalMeasurementBudget: Hashable, Codable, Sendable {
    public let scenarioID: String
    public let requireCleanEquivalence: Bool
    public let maximumFallbackCount: Int?
    public let maximumMedianNanoseconds: UInt64?
    public let maximumPercentile95Nanoseconds: UInt64?
    public let minimumReuseRatios: [ReuseDimension: Double]

    public init(scenarioID: String, requireCleanEquivalence: Bool = true,
                maximumFallbackCount: Int? = nil,
                maximumMedianNanoseconds: UInt64? = nil,
                maximumPercentile95Nanoseconds: UInt64? = nil,
                minimumReuseRatios: [ReuseDimension: Double] = [:]) {
        precondition(!scenarioID.isEmpty, "a budget scenario ID cannot be empty")
        precondition(maximumFallbackCount.map { $0 >= 0 } ?? true,
                     "a fallback budget cannot be negative")
        precondition(minimumReuseRatios.values.allSatisfy { $0 >= 0 && $0 <= 1 },
                     "reuse-ratio budgets must be between zero and one")
        self.scenarioID = scenarioID
        self.requireCleanEquivalence = requireCleanEquivalence
        self.maximumFallbackCount = maximumFallbackCount
        self.maximumMedianNanoseconds = maximumMedianNanoseconds
        self.maximumPercentile95Nanoseconds = maximumPercentile95Nanoseconds
        self.minimumReuseRatios = minimumReuseRatios
    }

    private enum CodingKeys: String, CodingKey {
        case scenarioID, requireCleanEquivalence, maximumFallbackCount
        case maximumMedianNanoseconds, maximumPercentile95Nanoseconds
        case minimumReuseRatios
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let scenarioID = try container.decode(String.self, forKey: .scenarioID)
        let requireCleanEquivalence = try container.decode(
            Bool.self, forKey: .requireCleanEquivalence)
        let maximumFallbackCount = try container.decodeIfPresent(
            Int.self, forKey: .maximumFallbackCount)
        let maximumMedianNanoseconds = try container.decodeIfPresent(
            UInt64.self, forKey: .maximumMedianNanoseconds)
        let maximumPercentile95Nanoseconds = try container.decodeIfPresent(
            UInt64.self, forKey: .maximumPercentile95Nanoseconds)
        let minimumReuseRatios = try container.decode(
            [ReuseDimension: Double].self, forKey: .minimumReuseRatios)
        guard !scenarioID.isEmpty,
              maximumFallbackCount.map({ $0 >= 0 }) ?? true,
              minimumReuseRatios.values.allSatisfy({ $0 >= 0 && $0 <= 1 }) else {
            throw DecodingError.dataCorruptedError(
                forKey: .scenarioID, in: container,
                debugDescription: "Invalid measurement budget.")
        }
        self.scenarioID = scenarioID
        self.requireCleanEquivalence = requireCleanEquivalence
        self.maximumFallbackCount = maximumFallbackCount
        self.maximumMedianNanoseconds = maximumMedianNanoseconds
        self.maximumPercentile95Nanoseconds = maximumPercentile95Nanoseconds
        self.minimumReuseRatios = minimumReuseRatios
    }
}

public struct IncrementalMeasurementBudgetEvaluation: Hashable, Codable, Sendable {
    public let passed: Bool
    public let violations: [String]
}

public enum IncrementalMeasurementError: Error, Equatable, Sendable {
    case duplicateScenario(String)
    case invalidReport(String)
}

/// Portable product-level record. The evidence fingerprint excludes host and
/// timing; the measurement fingerprint binds both, preventing invalid timing
/// comparisons while retaining cross-host correctness comparison.
public struct IncrementalMeasurementReport: Hashable, Codable, Sendable {
    public static let schemaVersion = 1

    public let schemaVersion: Int
    public let protocolValue: IncrementalMeasurementProtocol
    public let environment: IncrementalMeasurementEnvironment
    public let artifact: IncrementalArtifactIdentity?
    public let scenarios: [IncrementalMeasurementScenario]
    public let samples: [IncrementalMeasurementSample]
    public let summaries: [IncrementalScenarioSummary]
    public let evidenceFingerprint: String
    public let measurementFingerprint: String

    fileprivate init(protocolValue: IncrementalMeasurementProtocol,
                     environment: IncrementalMeasurementEnvironment,
                     artifact: IncrementalArtifactIdentity?,
                     scenarios: [IncrementalMeasurementScenario],
                     samples: [IncrementalMeasurementSample]) {
        self.schemaVersion = Self.schemaVersion
        self.protocolValue = protocolValue
        self.environment = environment
        self.artifact = artifact
        self.scenarios = scenarios.sorted { $0.id < $1.id }
        self.samples = samples.sorted {
            ($0.scenarioID, $0.iteration) < ($1.scenarioID, $1.iteration)
        }
        self.summaries = Self.makeSummaries(samples: self.samples)
        self.evidenceFingerprint = Self.fingerprint(Self.evidenceMaterial(
            protocolValue: protocolValue, artifact: artifact,
            scenarios: self.scenarios, samples: self.samples))
        self.measurementFingerprint = Self.fingerprint(Self.measurementMaterial(
            evidenceFingerprint: evidenceFingerprint, environment: environment,
            samples: self.samples))
    }

    public var allOperationsEquivalent: Bool {
        summaries.allSatisfy { $0.correctnessFailureCount == 0 }
    }

    public func isTimingComparable(to other: Self) -> Bool {
        environment.comparisonIdentity == other.environment.comparisonIdentity &&
        protocolValue == other.protocolValue
    }

    public func evaluate(_ budgets: [IncrementalMeasurementBudget])
        -> IncrementalMeasurementBudgetEvaluation {
        var violations: [String] = []
        let byID = Dictionary(uniqueKeysWithValues: summaries.map { ($0.scenarioID, $0) })
        for budget in budgets.sorted(by: { $0.scenarioID < $1.scenarioID }) {
            guard let summary = byID[budget.scenarioID] else {
                violations.append("\(budget.scenarioID): missing scenario")
                continue
            }
            if budget.requireCleanEquivalence && summary.correctnessFailureCount > 0 {
                violations.append("\(budget.scenarioID): clean equivalence failed \(summary.correctnessFailureCount) time(s)")
            }
            if let maximum = budget.maximumFallbackCount,
               summary.fallbackCount > maximum {
                violations.append("\(budget.scenarioID): \(summary.fallbackCount) fallbacks exceed \(maximum)")
            }
            if let maximum = budget.maximumMedianNanoseconds,
               summary.medianNanoseconds > maximum {
                violations.append("\(budget.scenarioID): median \(summary.medianNanoseconds) ns exceeds \(maximum) ns")
            }
            if let maximum = budget.maximumPercentile95Nanoseconds,
               summary.percentile95Nanoseconds > maximum {
                violations.append("\(budget.scenarioID): p95 \(summary.percentile95Nanoseconds) ns exceeds \(maximum) ns")
            }
            for (dimension, minimum) in budget.minimumReuseRatios.sorted(
                by: { $0.key.rawValue < $1.key.rawValue }) {
                guard let ratio = summary.measurement(for: dimension)?.reuseRatio else {
                    violations.append("\(budget.scenarioID): missing \(dimension.rawValue) reuse evidence")
                    continue
                }
                if ratio < minimum {
                    violations.append("\(budget.scenarioID): \(dimension.rawValue) reuse \(ratio) is below \(minimum)")
                }
            }
        }
        return .init(passed: violations.isEmpty, violations: violations)
    }

    public func json() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }

    public static func decode(_ data: Data) throws -> Self {
        let value = try JSONDecoder().decode(Self.self, from: data)
        guard value.schemaVersion == schemaVersion,
              !value.protocolValue.id.isEmpty,
              value.protocolValue.warmupIterations >= 0,
              value.protocolValue.measurementIterations > 0,
              !value.environment.hostID.isEmpty,
              !value.environment.operatingSystem.isEmpty,
              !value.environment.architecture.isEmpty,
              !value.environment.swiftVersion.isEmpty else {
            throw IncrementalMeasurementError.invalidReport(
                "unsupported schema version or invalid protocol/environment")
        }
        let scenarioIDs = value.scenarios.map(\.id)
        let sampleKeys = value.samples.map { "\($0.scenarioID)\u{0}\($0.iteration)" }
        guard !scenarioIDs.isEmpty,
              value.scenarios.allSatisfy({ !$0.id.isEmpty && !$0.title.isEmpty }),
              Set(scenarioIDs).count == scenarioIDs.count,
              value.samples.count == scenarioIDs.count * value.protocolValue.measurementIterations,
              Set(sampleKeys).count == sampleKeys.count,
              value.samples.allSatisfy({ sample in
                  scenarioIDs.contains(sample.scenarioID) && sample.iteration >= 0 &&
                  sample.iteration < value.protocolValue.measurementIterations
              }) else {
            throw IncrementalMeasurementError.invalidReport(
                "scenario and sample identities are inconsistent")
        }
        let rebuilt = Self(protocolValue: value.protocolValue,
                           environment: value.environment,
                           artifact: value.artifact,
                           scenarios: value.scenarios, samples: value.samples)
        guard rebuilt.scenarios == value.scenarios,
              rebuilt.samples == value.samples,
              rebuilt.summaries == value.summaries,
              rebuilt.evidenceFingerprint == value.evidenceFingerprint,
              rebuilt.measurementFingerprint == value.measurementFingerprint else {
            throw IncrementalMeasurementError.invalidReport(
                "derived summaries or fingerprints do not match the samples")
        }
        return value
    }

    private static func makeSummaries(samples: [IncrementalMeasurementSample])
        -> [IncrementalScenarioSummary] {
        Dictionary(grouping: samples, by: \.scenarioID).map { id, values in
            let durations = values.map(\.durationNanoseconds).sorted()
            var totals: [ReuseDimension: (Int, Int, Int)] = [:]
            for measurement in values.flatMap({ $0.operation.evidence.measurements }) {
                let current = totals[measurement.dimension] ?? (0, 0, 0)
                totals[measurement.dimension] = (
                    current.0 + measurement.reused,
                    current.1 + measurement.rebuilt,
                    current.2 + measurement.removed)
            }
            let reuse = totals.map { dimension, count in
                IncrementalMeasurementTotal(
                    dimension: dimension, reused: count.0,
                    rebuilt: count.1, removed: count.2)
            }.sorted { $0.dimension.rawValue < $1.dimension.rawValue }
            return IncrementalScenarioSummary(
                scenarioID: id, sampleCount: values.count,
                minimumNanoseconds: durations[0],
                medianNanoseconds: percentile(durations, numerator: 50),
                percentile95Nanoseconds: percentile(durations, numerator: 95),
                fallbackCount: values.filter { $0.operation.evidence.strategy == .fallback }.count,
                correctnessFailureCount: values.filter { !$0.operation.equivalentToCleanRun }.count,
                reuse: reuse)
        }.sorted { $0.scenarioID < $1.scenarioID }
    }

    private static func percentile(_ sorted: [UInt64], numerator: Int) -> UInt64 {
        let rank = (numerator * sorted.count + 99) / 100
        return sorted[max(0, min(sorted.count - 1, rank - 1))]
    }

    private static func evidenceMaterial(
        protocolValue: IncrementalMeasurementProtocol,
        artifact: IncrementalArtifactIdentity?,
        scenarios: [IncrementalMeasurementScenario],
        samples: [IncrementalMeasurementSample]) -> String {
        let scenarioMaterial = scenarios.map { "\($0.id)|\($0.title)" }.joined(separator: "\n")
        let sampleMaterial = samples.map { sample in
            let measurements = sample.operation.evidence.measurements.map {
                "\($0.dimension.rawValue):\($0.reused):\($0.rebuilt):\($0.removed):\($0.strategy ?? "-")"
            }.joined(separator: ",")
            return "\(sample.scenarioID)|\(sample.iteration)|\(sample.operation.equivalentToCleanRun)|\(sample.operation.evidence.strategy.rawValue)|\(sample.operation.evidence.fallback?.code ?? "-")|\(measurements)"
        }.joined(separator: "\n")
        let artifactMaterial = artifact.map { "\($0.id)|\($0.revision)|\($0.fingerprint)" } ?? "-"
        return "\(protocolValue.id)|\(protocolValue.warmupIterations)|\(protocolValue.measurementIterations)\n\(artifactMaterial)\n\(scenarioMaterial)\n\(sampleMaterial)"
    }

    private static func measurementMaterial(
        evidenceFingerprint: String,
        environment: IncrementalMeasurementEnvironment,
        samples: [IncrementalMeasurementSample]) -> String {
        let timings = samples.map {
            "\($0.scenarioID)|\($0.iteration)|\($0.durationNanoseconds)"
        }.joined(separator: "\n")
        return "\(evidenceFingerprint)\n\(environment.comparisonIdentity)\n\(timings)"
    }

    private static func fingerprint(_ value: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return String(format: "%016llx", hash)
    }
}

public enum IncrementalMeasurementRunner {
    public static func run(
        protocol protocolValue: IncrementalMeasurementProtocol,
        environment: IncrementalMeasurementEnvironment,
        artifact: IncrementalArtifactIdentity? = nil,
        scenarios: [IncrementalMeasurementScenario],
        clock: () -> UInt64 = { DispatchTime.now().uptimeNanoseconds },
        operation: (IncrementalMeasurementScenario, Int) throws
            -> IncrementalMeasuredOperation
    ) throws -> IncrementalMeasurementReport {
        var ids = Set<String>()
        guard !scenarios.isEmpty else {
            throw IncrementalMeasurementError.invalidReport(
                "a measurement run needs at least one scenario")
        }
        for scenario in scenarios where !ids.insert(scenario.id).inserted {
            throw IncrementalMeasurementError.duplicateScenario(scenario.id)
        }
        let ordered = scenarios.sorted { $0.id < $1.id }
        var samples: [IncrementalMeasurementSample] = []
        for scenario in ordered {
            for iteration in 0..<protocolValue.warmupIterations {
                _ = try operation(scenario, iteration - protocolValue.warmupIterations)
            }
            for iteration in 0..<protocolValue.measurementIterations {
                let start = clock()
                let result = try operation(scenario, iteration)
                let end = clock()
                samples.append(.init(
                    scenarioID: scenario.id, iteration: iteration,
                    durationNanoseconds: end >= start ? end - start : 0,
                    operation: result))
            }
        }
        return .init(protocolValue: protocolValue, environment: environment,
                     artifact: artifact, scenarios: ordered, samples: samples)
    }

    /// Async counterpart for actor-backed editor and language-server sessions.
    /// Timing includes the awaited operation and excludes runner bookkeeping.
    public static func run(
        protocol protocolValue: IncrementalMeasurementProtocol,
        environment: IncrementalMeasurementEnvironment,
        artifact: IncrementalArtifactIdentity? = nil,
        scenarios: [IncrementalMeasurementScenario],
        clock: () -> UInt64 = { DispatchTime.now().uptimeNanoseconds },
        operation: (IncrementalMeasurementScenario, Int) async throws
            -> IncrementalMeasuredOperation
    ) async throws -> IncrementalMeasurementReport {
        var ids = Set<String>()
        guard !scenarios.isEmpty else {
            throw IncrementalMeasurementError.invalidReport(
                "a measurement run needs at least one scenario")
        }
        for scenario in scenarios where !ids.insert(scenario.id).inserted {
            throw IncrementalMeasurementError.duplicateScenario(scenario.id)
        }
        let ordered = scenarios.sorted { $0.id < $1.id }
        var samples: [IncrementalMeasurementSample] = []
        for scenario in ordered {
            for iteration in 0..<protocolValue.warmupIterations {
                _ = try await operation(
                    scenario, iteration - protocolValue.warmupIterations)
            }
            for iteration in 0..<protocolValue.measurementIterations {
                let start = clock()
                let result = try await operation(scenario, iteration)
                let end = clock()
                samples.append(.init(
                    scenarioID: scenario.id, iteration: iteration,
                    durationNanoseconds: end >= start ? end - start : 0,
                    operation: result))
            }
        }
        return .init(protocolValue: protocolValue, environment: environment,
                     artifact: artifact, scenarios: ordered, samples: samples)
    }
}
