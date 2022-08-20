import XCTest

import shared

final class engineTests: XCTestCase {

	func testBasicOperation() throws {
		let documents = [
			Document(
				path: "/a",
				frontmatter: [:],
				entries: [Entry(.tag("foo"))]
			),
			Document(
				path: "/b",
				frontmatter: [:],
				entries: [Entry(.tag("bar"))]
			)
		]

		let engine = NaiveSearchEngine(documents)

		var result = engine.findMatches(["foo"])
		XCTAssertEqual(result.count, 1)
		XCTAssertEqual(result[0].path, "/a")

		result = engine.findMatches(["wibble"])
		XCTAssertEqual(result.count, 0)

		result = engine.findMatches(["foo", "wibble"])
		XCTAssertEqual(result.count, 1)
		XCTAssertEqual(result[0].path, "/a")

		result = engine.findMatches(["foo", "bar"])
		XCTAssertEqual(result.count, 2)
	}
}