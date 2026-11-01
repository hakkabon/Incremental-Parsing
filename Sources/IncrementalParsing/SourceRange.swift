/// A half-open range measured in UTF-16 code units.
///
/// UTF-16 is the common coordinate system used by TextKit and the Language
/// Server Protocol. Keeping it explicit prevents accidental mixing with Swift
/// `String.Index` values or user-perceived character offsets.
public struct SourceRange: Sendable, Hashable, Codable {
    public let lowerBound: Int
    public let upperBound: Int

    public init(_ lowerBound: Int, _ upperBound: Int) {
        precondition(lowerBound >= 0, "a source range cannot start before zero")
        precondition(upperBound >= lowerBound, "a source range cannot be inverted")
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    public init(location: Int, length: Int) {
        precondition(length >= 0, "a source range cannot have negative length")
        self.init(location, location + length)
    }

    public var location: Int { lowerBound }
    public var length: Int { upperBound - lowerBound }
    public var isEmpty: Bool { lowerBound == upperBound }

    public func contains(_ offset: Int) -> Bool {
        lowerBound <= offset && offset < upperBound
    }
}
