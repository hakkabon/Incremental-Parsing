/// A parser implementation owns its private caches. The shared contract only
/// supplies immutable source and the exact transition from the preceding run.
public protocol IncrementalParser: Sendable {
    associatedtype Output: Sendable

    mutating func parse(
        _ snapshot: SourceSnapshot,
        previous: Output?,
        change: SourceChange?
    ) throws -> Output
}

/// Serializes document changes and parser cache access while permitting parser
/// implementations to remain ordinary value types.
public actor IncrementalParseSession<Parser: IncrementalParser> {
    private var parser: Parser
    public private(set) var snapshot: SourceSnapshot
    public private(set) var result: Parser.Output?

    public init(text: String = "", parser: Parser) {
        self.snapshot = SourceSnapshot(text: text)
        self.parser = parser
    }

    @discardableResult
    public func parse() throws -> Parser.Output {
        let output = try parser.parse(snapshot, previous: result, change: nil)
        result = output
        return output
    }

    @discardableResult
    public func apply(_ edit: SourceEdit) throws -> Parser.Output {
        let change = try edit.applying(to: snapshot)
        let output = try parser.parse(
            change.after, previous: result, change: change)
        snapshot = change.after
        result = output
        return output
    }

    /// Replaces externally synchronized text and deliberately withholds a
    /// change description, forcing parsers to take their full-parse path.
    @discardableResult
    public func replaceText(_ text: String) throws -> Parser.Output {
        let revision = try snapshot.revision.successor()
        let replacement = SourceSnapshot(text: text, revision: revision)
        let output = try parser.parse(replacement, previous: result, change: nil)
        snapshot = replacement
        result = output
        return output
    }
}
