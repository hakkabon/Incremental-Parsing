import XCTest
@testable import IncrementalParsing

final class OffsetMapTests: XCTestCase {
    func testMapsAroundReplacementInBothDirections() {
        let map = OffsetMap(replacedRange: SourceRange(4, 7), replacementLength: 1)
        XCTAssertEqual(map.newOffset(forOldOffset: 2), 2)
        XCTAssertEqual(map.newOffset(forOldOffset: 5), 4)
        XCTAssertEqual(map.newOffset(forOldOffset: 5, affinity: .trailing), 5)
        XCTAssertEqual(map.newOffset(forOldOffset: 9), 7)
        XCTAssertEqual(map.oldOffset(forNewOffset: 7), 9)
    }

    func testAffinityDistinguishesEitherSideOfInsertion() {
        let map = OffsetMap(replacedRange: SourceRange(4, 4), replacementLength: 3)
        XCTAssertEqual(map.newOffset(forOldOffset: 4, affinity: .leading), 4)
        XCTAssertEqual(map.newOffset(forOldOffset: 4, affinity: .trailing), 7)
    }
}
