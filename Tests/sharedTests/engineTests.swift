import XCTest

@testable import shared

final class engineTests: XCTestCase {

	func testBasicOperation() throws {
		let documents = [
			Document(
				path: "/a",
				entries: [Entry.tag("foo")],
				date: Date()
			),
			Document(
				path: "/b",
				entries: [Entry.tag("bar")],
				date: Date()
			)
		]

		let engine = NaiveSearchEngine(documents)

		var result = engine.findMatches(["foo"])
		XCTAssertEqual(result.count, 1)
		XCTAssertEqual(result.first!.path, "/a")

		result = engine.findMatches(["wibble"])
		XCTAssertEqual(result.count, 0)

		result = engine.findMatches(["foo", "wibble"])
		XCTAssertEqual(result.count, 1)
		XCTAssertEqual(result.first!.path, "/a")

		result = engine.findMatches(["foo", "bar"])
		XCTAssertEqual(result.count, 2)
	}

	func testNotRegularEnglishCharactersOperation() throws {
		let documents = [
			Document(
				path: "/a",
				entries: [Entry.tag("älgen")],
				date: Date()
			),
			Document(
				path: "/b",
				entries: [Entry.tag("🎸")],
				date: Date()
			)
		]

		let engine = NaiveSearchEngine(documents)

		var result = engine.findMatches(["älgen"])
		XCTAssertEqual(result.count, 1)
		XCTAssertEqual(result.first!.path, "/a")

		result = engine.findMatches(["🎸"])
		XCTAssertEqual(result.count, 1)
		XCTAssertEqual(result.first!.path, "/b")
	}

	func testNoDuplicateResultsBetweenEntryTypes() throws {
		let documents = [
			Document(
				path: "/a",
				entries: [Entry.tag("foo"), Entry.title("foo"), Entry.content("foo")],
				date: Date()
			),
		]

		let engine = NaiveSearchEngine(documents)

		// Before we used sets in the index we'd get two hits for this document,
		// once for the tag and once for the title
		let result = engine.findMatches(["foo"])
		XCTAssertEqual(result.count, 1)
		XCTAssertEqual(result.first!.path, "/a")
	}

	func testNoDuplicateResultsWithinEntryTypes() throws {
		let documents = [
			Document(
				path: "/a",
				entries: [Entry.tag("foo"), Entry.tag("bar")],
				date: Date()
			),
		]

		let engine = NaiveSearchEngine(documents)

		let result = engine.findMatches(["foo", "bar"])
		XCTAssertEqual(result.count, 1)
		XCTAssertEqual(result.first!.path, "/a")
	}

	func testRanking() throws {
		let document = Document(
			path: "/a",
			entries: [
				Entry.tag("tag"),
				Entry.title("title"),
				Entry.content("content")
			],
			date: Date()
		)

		XCTAssertEqual(NaiveSearchEngine.rankMatch(terms: Set(["tag"]), document: document), 100)
		XCTAssertEqual(NaiveSearchEngine.rankMatch(terms: Set(["title"]), document: document), 10)
		XCTAssertEqual(NaiveSearchEngine.rankMatch(terms: Set(["content"]), document: document), 1)
		XCTAssertEqual(NaiveSearchEngine.rankMatch(terms: Set(["wibble"]), document: document), 0)
		XCTAssertEqual(NaiveSearchEngine.rankMatch(terms: Set(["tag", "title"]), document: document), 110)
	}

	func testTokenisation() throws {
		XCTAssertEqual(
			NaiveSearchEngine.tokeniseString("Hello, World!"),
			Set(["hello", "world"])
		)
		XCTAssertEqual(
			NaiveSearchEngine.tokeniseString("    abc123   "),
			Set(["abc123"])
		)
	}

	func testCombinedOperation() throws {
		let documents = [
			Document(
				path: "/a",
				entries: [Entry.tag(normaliseString("foo"))],
				date: Date()
			),
			Document(
				path: "/b",
				entries: [Entry.tag(normaliseString("bar"))],
				date: Date()
			),
			Document(
				path: "/c",
				entries: [Entry.tag(normaliseString("älgen"))],
				date: Date()
			)
		]

		let engine = NaiveSearchEngine(documents)

		var result = engine.findAndRank("foo")
		XCTAssertEqual(result.count, 1)
		XCTAssertEqual(result[0].path, "/a")

		result = engine.findAndRank("wibble")
		XCTAssertEqual(result.count, 0)

		result = engine.findAndRank("foo bar")
		XCTAssertEqual(result.count, 2)

		result = engine.findAndRank("älgen")
		XCTAssertEqual(result.count, 1)
		XCTAssertEqual(result[0].path, "/c")
	}

	func testResultOrderByDate() throws {
		let documents = [
			Document(
				path: "/a",
				entries: [Entry.tag("foo")],
				date: Date() - 100
			),
			Document(
				path: "/b",
				entries: [Entry.tag("foo")],
				date: Date()
			)
		]
		let engine = NaiveSearchEngine(documents)

		// Expect newest items first
		let result = engine.findAndRank("foo")
		XCTAssertEqual(result.count, 2)
		XCTAssertEqual(result.first!.path, "/b")
		XCTAssertEqual(result.last!.path, "/a")
	}

	func testResultOrderByType() throws {
		let documents = [
			Document(
				path: "/a",
				entries: [Entry.title("foo")],
				date: Date()
			),
			Document(
				path: "/b",
				entries: [Entry.tag("foo")],
				date: Date()
			),
			Document(
				path: "/c",
				entries: [Entry.content("foo")],
				date: Date()
			)
		]
		let engine = NaiveSearchEngine(documents)

		// Expect newest items first
		let result = engine.findAndRank("foo")
		XCTAssertEqual(result.count, 3)
		XCTAssertEqual(result.first!.path, "/b")
		XCTAssertEqual(result.last!.path, "/c")
	}
}
