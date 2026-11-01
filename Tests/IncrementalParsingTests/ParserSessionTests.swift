import XCTest
@testable import IncrementalParsing

private struct CountingParser: IncrementalParser {
    struct Output: Sendable, Equatable {
        let text: String
        let reusedPrevious: Bool
        let wasIncremental: Bool
    }

    mutating func parse(_ snapshot: SourceSnapshot, previous: Output?,
                        change: SourceChange?) throws -> Output {
        Output(text: snapshot.text, reusedPrevious: previous != nil,
               wasIncremental: change != nil)
    }
}

final class ParserSessionTests: XCTestCase {
    func testSessionSuppliesPreviousResultAndExactChange() async throws {
        let session = IncrementalParseSession(text: "let x", parser: CountingParser())
        let first = try await session.parse()
        XCTAssertFalse(first.reusedPrevious)
        XCTAssertFalse(first.wasIncremental)

        let second = try await session.apply(SourceEdit(
            baseRevision: .init(0), range: SourceRange(5, 5), replacement: " = 1"))
        XCTAssertEqual(second.text, "let x = 1")
        XCTAssertTrue(second.reusedPrevious)
        XCTAssertTrue(second.wasIncremental)
    }
}
