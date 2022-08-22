import XCTest

import shared

final class sharedTests: XCTestCase {

    func testBasicPathMangling() throws {
        let doc = Document(
            path: "/test/PaTh/index.md",
            frontmatter: [:],
            entries: []
        )

        // tests extention has changed and all to lowercase
        XCTAssertEqual(doc.publishedPath, "/test/path/index.html")
    }

    func testFrontmatterValueFromString() throws {
        let testval = "test"
        let val = FrontmatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontmatterValue.stringValue(testval))
    }

    func testFrontmatterValueFromDate() throws {
        let testval = Date()
        let val = FrontmatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontmatterValue.dateValue(testval))
    }

    func testFrontmatterValueFromStringArray() throws {
        let testval = ["hello", "world"]
        let val = FrontmatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontmatterValue.arrayValue(testval))
    }

    func testFrontmatterValueFromBoole() throws {
        let testval = false
        let val = FrontmatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontmatterValue.booleValue(testval))
    }

    func testFrontmatterValueFromInt() throws {
        let testval = 42
        let val = FrontmatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontmatterValue.intValue(testval))
    }

    func testFrontmatterValueFromUnsupported() throws {
        let testval = [1, 2, 3]
        let val = FrontmatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontmatterValue.stringValue("\(testval)"))
    }

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

    func testHugoNameMangling() throws {
        var document = Document(path: "a/b/index.md", frontmatter: [:], entries: [])
        XCTAssertEqual(document.publishedPath, "a/b/index.html")

        document = Document(path: "a/b.md", frontmatter: [:], entries: [])
        XCTAssertEqual(document.publishedPath, "a/b/index.html")
    }

}
