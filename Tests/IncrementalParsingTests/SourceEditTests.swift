import XCTest
@testable import IncrementalParsing

final class SourceEditTests: XCTestCase {
    func testCompatibilityInputProjectsCanonicalRevisionAndRange() {
        let input = IncrementalInputSnapshot(
            version: 9, text: "abc",
            edit: IncrementalInputEdit(
                baseVersion: 8,
                replacedRange: SourceRange(location: 1, length: 1),
                replacementLength: 1))

        XCTAssertEqual(input.canonical.revision, SourceRevision(9))
        XCTAssertEqual(input.edit?.replacedRange.end, 2)
    }

    func testEditUsesUTF16CoordinatesAndProducesMap() throws {
        let source = SourceSnapshot(text: "a😀b", revision: .init(7))
        let edit = SourceEdit(
            baseRevision: .init(7), range: SourceRange(location: 1, length: 2),
            replacement: "xy")

        let change = try edit.applying(to: source)

        XCTAssertEqual(change.after.text, "axyb")
        XCTAssertEqual(change.after.revision, .init(8))
        XCTAssertEqual(change.newOffset(forOldOffset: 3), 3)
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

    func testAtomicBatchUsesSequentialUTF16CoordinatesAndOneRevision() throws {
        let source = SourceSnapshot(text: "abc", revision: .init(4))
        let batch = SourceEditBatch(baseRevision: .init(4), replacements: [
            .init(range: SourceRange(1, 1), replacement: "X"),
            .init(range: SourceRange(2, 3), replacement: "Y"),
        ])

        let change = try batch.applying(to: source)

        XCTAssertEqual(change.after.text, "aXYc")
        XCTAssertEqual(change.after.revision, .init(5))
        XCTAssertTrue(change.isBatch)
        XCTAssertEqual(change.newOffset(forOldOffset: 3), 4)
        XCTAssertEqual(change.oldOffset(forNewOffset: 4), 3)
    }

    func testBatchRejectsAtomicallyWhenALaterReplacementIsInvalid() {
        let source = SourceSnapshot(text: "abc")
        let batch = SourceEditBatch(baseRevision: .init(0), replacements: [
            .init(range: SourceRange(1, 1), replacement: "X"),
            .init(range: SourceRange(99, 99), replacement: "Y"),
        ])
        XCTAssertThrowsError(try batch.applying(to: source))
        XCTAssertEqual(source, SourceSnapshot(text: "abc"))
    }

    func testBatchCanPreserveAnExternalMonotonicRevision() throws {
        let source = SourceSnapshot(text: "abc", revision: .init(4))
        let change = try SourceEditBatch(
            baseRevision: .init(4), resultRevision: .init(9),
            replacements: [.init(range: SourceRange(3, 3), replacement: "d")]
        ).applying(to: source)
        XCTAssertEqual(change.after.revision, .init(9))

        XCTAssertThrowsError(try SourceEditBatch(
            baseRevision: .init(4), resultRevision: .init(4),
            replacements: [.init(range: SourceRange(3, 3), replacement: "d")]
        ).applying(to: source))
    }
}
