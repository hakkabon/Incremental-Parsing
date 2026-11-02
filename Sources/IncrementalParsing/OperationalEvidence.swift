/// Exact identity of the grammar, table, generated parser, or other artifact
/// against which reusable state was produced.
public struct IncrementalArtifactIdentity: Hashable, Codable, Sendable {
    public let id: String
    public let revision: UInt64
    public let fingerprint: String

    public init(id: String, revision: UInt64, fingerprint: String) {
        precondition(!id.isEmpty, "an artifact identity cannot be empty")
        precondition(!fingerprint.isEmpty, "an artifact fingerprint cannot be empty")
        self.id = id
        self.revision = revision
        self.fingerprint = fingerprint
    }

    private enum CodingKeys: String, CodingKey { case id, revision, fingerprint }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let revision = try container.decode(UInt64.self, forKey: .revision)
        let fingerprint = try container.decode(String.self, forKey: .fingerprint)
        guard !id.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .id, in: container,
                debugDescription: "An artifact identity cannot be empty.")
        }
        guard !fingerprint.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .fingerprint, in: container,
                debugDescription: "An artifact fingerprint cannot be empty.")
        }
        self.id = id
        self.revision = revision
        self.fingerprint = fingerprint
    }
}

/// Open-ended reuse dimension. Standard names permit cross-engine comparison,
/// while engine packages may publish additional names without changing this
/// dependency-free contract.
public struct ReuseDimension: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "a reuse dimension cannot be empty")
        self.rawValue = rawValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard !rawValue.isEmpty else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "A reuse dimension cannot be empty.")
        }
        self.rawValue = rawValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static let tokens = Self(rawValue: "tokens")
    public static let parserStates = Self(rawValue: "parserStates")
    public static let syntaxNodes = Self(rawValue: "syntaxNodes")
    public static let chartColumns = Self(rawValue: "chartColumns")
    public static let chartFacts = Self(rawValue: "chartFacts")
    public static let forestNodes = Self(rawValue: "forestNodes")
    public static let semanticNodes = Self(rawValue: "semanticNodes")
    public static let irNodes = Self(rawValue: "irNodes")
}

public struct ReuseMeasurement: Hashable, Codable, Sendable {
    public let dimension: ReuseDimension
    public let reused: Int
    public let rebuilt: Int
    public let removed: Int
    public let strategy: String?

    public init(dimension: ReuseDimension, reused: Int,
                rebuilt: Int, removed: Int = 0,
                strategy: String? = nil) {
        precondition(reused >= 0 && rebuilt >= 0 && removed >= 0,
                     "reuse counts cannot be negative")
        precondition(strategy?.isEmpty != true,
                     "a measurement strategy cannot be empty")
        self.dimension = dimension
        self.reused = reused
        self.rebuilt = rebuilt
        self.removed = removed
        self.strategy = strategy
    }

    private enum CodingKeys: String, CodingKey {
        case dimension, reused, rebuilt, removed, strategy
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dimension = try container.decode(ReuseDimension.self, forKey: .dimension)
        let reused = try container.decode(Int.self, forKey: .reused)
        let rebuilt = try container.decode(Int.self, forKey: .rebuilt)
        let removed = try container.decode(Int.self, forKey: .removed)
        let strategy = try container.decodeIfPresent(String.self, forKey: .strategy)
        guard reused >= 0, rebuilt >= 0, removed >= 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .reused, in: container,
                debugDescription: "Reuse counts cannot be negative.")
        }
        guard strategy?.isEmpty != true else {
            throw DecodingError.dataCorruptedError(
                forKey: .strategy, in: container,
                debugDescription: "A measurement strategy cannot be empty.")
        }
        self.dimension = dimension
        self.reused = reused
        self.rebuilt = rebuilt
        self.removed = removed
        self.strategy = strategy
    }
}

public enum IncrementalExecutionStrategy: String, Hashable, Codable, Sendable {
    case full
    case incremental
    case fallback
}

/// A stable machine-readable fallback code plus optional human detail.
public struct IncrementalFallbackReason: Hashable, Codable, Sendable {
    public let code: String
    public let detail: String?

    public init(code: String, detail: String? = nil) {
        precondition(!code.isEmpty, "a fallback code cannot be empty")
        self.code = code
        self.detail = detail
    }

    private enum CodingKeys: String, CodingKey { case code, detail }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let code = try container.decode(String.self, forKey: .code)
        guard !code.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .code, in: container,
                debugDescription: "A fallback code cannot be empty.")
        }
        self.code = code
        self.detail = try container.decodeIfPresent(String.self, forKey: .detail)
    }

    public static let missingPreviousState = Self(code: "missingPreviousState")
    public static let staleRevision = Self(code: "staleRevision")
    public static let incompatibleArtifact = Self(code: "incompatibleArtifact")
    public static let invalidPreviousResult = Self(code: "invalidPreviousResult")
    public static let unsupportedEdit = Self(code: "unsupportedEdit")
    public static let missingCheckpoint = Self(code: "missingCheckpoint")
    public static let validationMismatch = Self(code: "validationMismatch")
}

/// Parser-neutral operational evidence. It describes what happened without
/// exposing an LR stack, Earley item, GSS node, or other engine-owned state.
public struct IncrementalExecutionEvidence: Hashable, Codable, Sendable {
    public let strategy: IncrementalExecutionStrategy
    public let fallback: IncrementalFallbackReason?
    public let measurements: [ReuseMeasurement]

    public init(strategy: IncrementalExecutionStrategy,
                fallback: IncrementalFallbackReason? = nil,
                measurements: [ReuseMeasurement] = []) {
        precondition((strategy == .fallback) == (fallback != nil),
                     "only fallback execution carries a fallback reason")
        var dimensions = Set<ReuseDimension>()
        precondition(measurements.allSatisfy { dimensions.insert($0.dimension).inserted },
                     "reuse dimensions must be unique")
        self.strategy = strategy
        self.fallback = fallback
        self.measurements = measurements.sorted {
            $0.dimension.rawValue < $1.dimension.rawValue
        }
    }

    private enum CodingKeys: String, CodingKey { case strategy, fallback, measurements }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let strategy = try container.decode(IncrementalExecutionStrategy.self, forKey: .strategy)
        let fallback = try container.decodeIfPresent(
            IncrementalFallbackReason.self, forKey: .fallback)
        let measurements = try container.decode(
            [ReuseMeasurement].self, forKey: .measurements)
        guard (strategy == .fallback) == (fallback != nil) else {
            throw DecodingError.dataCorruptedError(
                forKey: .fallback, in: container,
                debugDescription: "Only fallback execution may carry a fallback reason.")
        }
        var dimensions = Set<ReuseDimension>()
        guard measurements.allSatisfy({ dimensions.insert($0.dimension).inserted }) else {
            throw DecodingError.dataCorruptedError(
                forKey: .measurements, in: container,
                debugDescription: "Reuse dimensions must be unique.")
        }
        self.strategy = strategy
        self.fallback = fallback
        self.measurements = measurements.sorted {
            $0.dimension.rawValue < $1.dimension.rawValue
        }
    }
}
