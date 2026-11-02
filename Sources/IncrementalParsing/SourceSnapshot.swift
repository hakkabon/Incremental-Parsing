import Foundation

public struct SourceRevision: Sendable, Hashable, Codable, Comparable {
    public let rawValue: UInt64

    public init(_ rawValue: UInt64) { self.rawValue = rawValue }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public func successor() throws -> Self {
        guard rawValue < UInt64.max else { throw SourceEditError.revisionOverflow }
        return Self(rawValue + 1)
    }
}

/// An immutable document value that can safely cross task boundaries.
public struct SourceSnapshot: Sendable, Hashable, Codable {
    public let revision: SourceRevision
    public let text: String

    public init(text: String, revision: SourceRevision = .init(0)) {
        self.text = text
        self.revision = revision
    }

    public var utf16Count: Int { text.utf16.count }
}

public enum SourceEditError: Error, Sendable, Equatable {
    case staleRevision(expected: SourceRevision, actual: SourceRevision)
    case rangeOutOfBounds(range: SourceRange, sourceLength: Int)
    case rangeSplitsSurrogatePair(range: SourceRange)
    case emptyBatch
    case nonIncreasingRevision(base: SourceRevision, proposed: SourceRevision)
    case revisionOverflow
}

/// One UTF-16 replacement inside an atomic source transition. Replacements in
/// a batch are interpreted sequentially, matching LSP content-change arrays.
public struct SourceReplacement: Sendable, Hashable, Codable {
    public let range: SourceRange
    public let replacement: String

    public init(range: SourceRange, replacement: String) {
        self.range = range
        self.replacement = replacement
    }

    public var replacementUTF16Count: Int { replacement.utf16.count }
}

/// A replacement against one specific source revision.
public struct SourceEdit: Sendable, Hashable, Codable {
    public let baseRevision: SourceRevision
    public let range: SourceRange
    public let replacement: String

    public init(baseRevision: SourceRevision, range: SourceRange, replacement: String) {
        self.baseRevision = baseRevision
        self.range = range
        self.replacement = replacement
    }

    public var replacementUTF16Count: Int { replacement.utf16.count }

    public func applying(to snapshot: SourceSnapshot) throws -> SourceChange {
        try SourceEditBatch(
            baseRevision: baseRevision,
            replacements: [.init(range: range, replacement: replacement)]
        ).applying(to: snapshot)
    }
}

/// An atomic, ordered set of replacements against one source revision.
/// Validation and application happen on a private value; either every
/// replacement succeeds and the revision advances once, or no state changes.
public struct SourceEditBatch: Sendable, Hashable, Codable {
    public let baseRevision: SourceRevision
    public let resultRevision: SourceRevision?
    public let replacements: [SourceReplacement]

    public init(baseRevision: SourceRevision,
                resultRevision: SourceRevision? = nil,
                replacements: [SourceReplacement]) {
        self.baseRevision = baseRevision
        self.resultRevision = resultRevision
        self.replacements = replacements
    }

    public func applying(to snapshot: SourceSnapshot) throws -> SourceChange {
        guard baseRevision == snapshot.revision else {
            throw SourceEditError.staleRevision(
                expected: snapshot.revision, actual: baseRevision)
        }
        guard !replacements.isEmpty else { throw SourceEditError.emptyBatch }

        var text = snapshot.text
        var maps: [OffsetMap] = []
        maps.reserveCapacity(replacements.count)
        for replacement in replacements {
            let length = text.utf16.count
            guard replacement.range.upperBound <= length else {
                throw SourceEditError.rangeOutOfBounds(
                    range: replacement.range, sourceLength: length)
            }
            let utf16 = text.utf16
            let lowerUTF16 = utf16.index(
                utf16.startIndex, offsetBy: replacement.range.lowerBound)
            let upperUTF16 = utf16.index(
                utf16.startIndex, offsetBy: replacement.range.upperBound)
            guard let lower = String.Index(lowerUTF16, within: text),
                  let upper = String.Index(upperUTF16, within: text) else {
                throw SourceEditError.rangeSplitsSurrogatePair(
                    range: replacement.range)
            }
            text.replaceSubrange(lower..<upper, with: replacement.replacement)
            maps.append(OffsetMap(
                replacedRange: replacement.range,
                replacementLength: replacement.replacementUTF16Count))
        }
        let nextRevision: SourceRevision
        if let resultRevision {
            guard resultRevision > baseRevision else {
                throw SourceEditError.nonIncreasingRevision(
                    base: baseRevision, proposed: resultRevision)
            }
            nextRevision = resultRevision
        } else {
            nextRevision = try snapshot.revision.successor()
        }
        let updated = SourceSnapshot(text: text, revision: nextRevision)
        return SourceChange(
            before: snapshot, after: updated,
            replacements: replacements, offsetMaps: maps)
    }
}

/// The complete, validated transition produced by one source edit.
public struct SourceChange: Sendable, Equatable {
    public let before: SourceSnapshot
    public let after: SourceSnapshot
    public let replacements: [SourceReplacement]
    public let offsetMaps: [OffsetMap]

    init(before: SourceSnapshot, after: SourceSnapshot,
         replacements: [SourceReplacement], offsetMaps: [OffsetMap]) {
        self.before = before
        self.after = after
        self.replacements = replacements
        self.offsetMaps = offsetMaps
    }

    public var isBatch: Bool { replacements.count > 1 }

    /// Maps an original offset through every sequential replacement.
    public func newOffset(forOldOffset offset: Int,
                          affinity: OffsetAffinity = .leading) -> Int {
        offsetMaps.reduce(offset) { value, map in
            map.newOffset(forOldOffset: value, affinity: affinity)
        }
    }

    /// Maps a final offset back through the replacements in reverse order.
    public func oldOffset(forNewOffset offset: Int,
                          affinity: OffsetAffinity = .leading) -> Int {
        offsetMaps.reversed().reduce(offset) { value, map in
            map.oldOffset(forNewOffset: value, affinity: affinity)
        }
    }
}
