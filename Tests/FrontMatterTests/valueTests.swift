import XCTest

import FrontMatter

final class valueTests: XCTestCase {

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

    func testFrontmatterSerialisation() throws {
        let testval = Date()
        let val = FrontmatterValue.fromAny(testval)
        XCTAssertEqual(val, FrontmatterValue.dateValue(testval))

        let jsonData = try JSONEncoder().encode(val)
        let new_val = try JSONDecoder().decode(FrontmatterValue.self, from: jsonData)
        XCTAssertEqual(val, new_val)
    }
}