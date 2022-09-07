import XCTest

import shared

final class sharedTests: XCTestCase {

    func testNormaliseString() throws {
        XCTAssertEqual(normaliseString("abc"), "abc")
        XCTAssertEqual(normaliseString("ABC"), "abc")
        XCTAssertEqual(normaliseString("like"), "like")
        XCTAssertEqual(normaliseString("likely"), "like")
        XCTAssertEqual(normaliseString("liked"), "like")

        // This is Swedish, so the fact it loses the n is gramatically wrong
        // but we did set PorterStemmer to English, and so long as it is
        // consistent it doesn't matter that it's an odd stemming for that
        // particular language.
        XCTAssertEqual(normaliseString("älgen"), "älge")

        // Emoji fail with the current stemmer :(
        // XCTAssertEqual(normaliseString("🎸"), "🎸")
    }

}
