import XCTest
@testable import IncrementalParsing

final class SourceEditTests: XCTestCase {
    func testEditUsesUTF16CoordinatesAndProducesMap() throws {
        let source = SourceSnapshot(text: "a😀b", revision: .init(7))
        let edit = SourceEdit(
            baseRevision: .init(7), range: SourceRange(location: 1, length: 2),
            replacement: "xy")

        let change = try edit.applying(to: source)

        XCTAssertEqual(change.after.text, "axyb")
        XCTAssertEqual(change.after.revision, .init(8))
        XCTAssertEqual(change.offsets.newOffset(forOldOffset: 3), 3)
    }

    func testRejectsStaleAndInvalidEdits() {
        let source = SourceSnapshot(text: "abc", revision: .init(2))
        XCTAssertThrowsError(try SourceEdit(
            baseRevision: .init(1), range: SourceRange(0, 1), replacement: "")
            .applying(to: source))
        XCTAssertThrowsError(try SourceEdit(
            baseRevision: .init(2), range: SourceRange(2, 4), replacement: "")
            .applying(to: source))
    }

    func testRejectsRangeSplittingSurrogatePair() {
        let source = SourceSnapshot(text: "😀")
        XCTAssertThrowsError(try SourceEdit(
            baseRevision: .init(0), range: SourceRange(0, 1), replacement: "")
            .applying(to: source))
    }
}
