import XCTest

import FrontMatter

final class FrontMatterValueTests: XCTestCase {

    func testFrontMatterValueFromString() throws {
        let testval = "test"
        let val = FrontMatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontMatterValue.stringValue(testval))
    }

    func testFrontMatterValueFromDate() throws {
        let testval = Date()
        let val = FrontMatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontMatterValue.dateValue(testval))
    }

    func testFrontMatterValueFromStringArray() throws {
        let testval = ["hello", "world"]
        let val = FrontMatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontMatterValue.arrayValue(testval))
    }

    func testFrontMatterValueFromBoole() throws {
        let testval = false
        let val = FrontMatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontMatterValue.booleValue(testval))
    }

    func testFrontMatterValueFromInt() throws {
        let testval = 42
        let val = FrontMatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontMatterValue.intValue(testval))
    }

    func testFrontMatterValueFromUnsupported() throws {
        let testval = [1, 2, 3]
        let val = FrontMatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontMatterValue.stringValue("\(testval)"))
    }

    func testFrontmatterSerialisation() throws {
        let testval = Date()
        let val = FrontMatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontMatterValue.dateValue(testval))

        let jsonData = try JSONEncoder().encode(val)
        let new_val = try JSONDecoder().decode(FrontMatterValue.self, from: jsonData)
        XCTAssertEqual(val, new_val)
    }
}