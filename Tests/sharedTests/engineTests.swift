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

	func testRanking() throws {
		let document = Document(
			path: "/a",
			frontmatter: [:],
			entries: [
			Entry(.tag("tag")),
			Entry(.title("title")),
			Entry(.content("content", 42))
			]
		)

		XCTAssertEqual(NaiveSearchEngine.rankMatch(terms: ["tag"], document: document), 100)
		XCTAssertEqual(NaiveSearchEngine.rankMatch(terms: ["title"], document: document), 10)
		XCTAssertEqual(NaiveSearchEngine.rankMatch(terms: ["content"], document: document), 1)
		XCTAssertEqual(NaiveSearchEngine.rankMatch(terms: ["wibble"], document: document), 0)
		XCTAssertEqual(NaiveSearchEngine.rankMatch(terms: ["tag", "title"], document: document), 110)
	}
}
