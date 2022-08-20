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
}
