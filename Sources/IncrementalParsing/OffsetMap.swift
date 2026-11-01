/// Chooses a boundary when an old position lies inside replaced text.
public enum OffsetAffinity: Sendable {
    case leading
    case trailing
}

/// Maps source coordinates across a single replacement.
public struct OffsetMap: Sendable, Equatable {
    public let replacedRange: SourceRange
    public let replacementLength: Int

    public init(replacedRange: SourceRange, replacementLength: Int) {
        precondition(replacementLength >= 0)
        self.replacedRange = replacedRange
        self.replacementLength = replacementLength
    }

    public var delta: Int { replacementLength - replacedRange.length }
    public var replacementRange: SourceRange {
        SourceRange(location: replacedRange.location, length: replacementLength)
    }

    public func newOffset(forOldOffset offset: Int,
                          affinity: OffsetAffinity = .leading) -> Int {
        precondition(offset >= 0)
        if offset < replacedRange.lowerBound { return offset }
        if offset > replacedRange.upperBound { return offset + delta }
        if offset == replacedRange.lowerBound {
            if replacedRange.isEmpty, affinity == .trailing {
                return replacementRange.upperBound
            }
            return offset
        }
        if offset == replacedRange.upperBound { return replacementRange.upperBound }
        return affinity == .leading
            ? replacedRange.lowerBound
            : replacedRange.lowerBound + replacementLength
    }

    public func oldOffset(forNewOffset offset: Int,
                          affinity: OffsetAffinity = .leading) -> Int {
        precondition(offset >= 0)
        let newRange = replacementRange
        if offset < newRange.lowerBound { return offset }
        if offset > newRange.upperBound { return offset - delta }
        if offset == newRange.lowerBound {
            if newRange.isEmpty, affinity == .trailing {
                return replacedRange.upperBound
            }
            return offset
        }
        if offset == newRange.upperBound { return replacedRange.upperBound }
        return affinity == .leading
            ? replacedRange.lowerBound
            : replacedRange.upperBound
    }
}
