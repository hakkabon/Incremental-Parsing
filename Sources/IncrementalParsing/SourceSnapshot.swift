import Foundation

public struct SourceRevision: Sendable, Hashable, Codable, Comparable {
    public let rawValue: UInt64

    public init(_ rawValue: UInt64) { self.rawValue = rawValue }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    func successor() throws -> Self {
        guard rawValue < UInt64.max else { throw SourceEditError.revisionOverflow }
        return Self(rawValue + 1)
    }
}

/// An immutable document value that can safely cross task boundaries.
public struct SourceSnapshot: Sendable, Equatable {
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
    case revisionOverflow
}

/// A replacement against one specific source revision.
public struct SourceEdit: Sendable, Equatable {
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
        guard baseRevision == snapshot.revision else {
            throw SourceEditError.staleRevision(
                expected: snapshot.revision, actual: baseRevision)
        }
        guard range.upperBound <= snapshot.utf16Count else {
            throw SourceEditError.rangeOutOfBounds(
                range: range, sourceLength: snapshot.utf16Count)
        }

        let utf16 = snapshot.text.utf16
        let lowerUTF16 = utf16.index(utf16.startIndex, offsetBy: range.lowerBound)
        let upperUTF16 = utf16.index(utf16.startIndex, offsetBy: range.upperBound)
        guard let lower = String.Index(lowerUTF16, within: snapshot.text),
              let upper = String.Index(upperUTF16, within: snapshot.text) else {
            throw SourceEditError.rangeSplitsSurrogatePair(range: range)
        }

        var text = snapshot.text
        text.replaceSubrange(lower..<upper, with: replacement)
        let updated = SourceSnapshot(
            text: text, revision: try snapshot.revision.successor())
        return SourceChange(before: snapshot, after: updated, edit: self)
    }
}

/// The complete, validated transition produced by one source edit.
public struct SourceChange: Sendable, Equatable {
    public let before: SourceSnapshot
    public let after: SourceSnapshot
    public let edit: SourceEdit
    public let offsets: OffsetMap

    init(before: SourceSnapshot, after: SourceSnapshot, edit: SourceEdit) {
        self.before = before
        self.after = after
        self.edit = edit
        self.offsets = OffsetMap(
            replacedRange: edit.range,
            replacementLength: edit.replacementUTF16Count)
    }
}
