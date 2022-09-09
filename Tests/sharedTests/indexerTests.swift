import XCTest

import FrontMatter
@testable import shared

final class indexerTests: XCTestCase {

	func testNoFrontmatter() throws {
		let entries = Entry.entriesFromFrontmatter([:])
		XCTAssertEqual(entries.count, 0)
	}

	func testBasicTagParsing() throws {
		let frontmatter = [
			KeyTags: FrontMatterValue.arrayValue(["foo", "bar"])
		]

		let entries = Entry.entriesFromFrontmatter(frontmatter)
		XCTAssertEqual(entries.count, 2)
	}

	func testBasicTagParsingDuplication() throws {
		let frontmatter = [
			KeyTags: FrontMatterValue.arrayValue(["foo", "foo"])
		]

		let entries = Entry.entriesFromFrontmatter(frontmatter)
		XCTAssertEqual(entries.count, 1)
	}

	func testComplexTagParsing() throws {
		let frontmatter = [
			KeyTags: FrontMatterValue.arrayValue(["foo bar", "wibble"])
		]

		let entries = Entry.entriesFromFrontmatter(frontmatter)
		XCTAssertEqual(entries.count, 3)
	}

	func testComplexTagParsingDuplication() throws {
		let frontmatter = [
			KeyTags: FrontMatterValue.arrayValue(["foo bar", "bar"])
		]

		let entries = Entry.entriesFromFrontmatter(frontmatter)
		XCTAssertEqual(entries.count, 2)
	}

	func testEmptyMarkdown() throws {
		let entries = Entry.entriesFromMarkdown("")
		XCTAssertEqual(entries.count, 0)
	}

	func testSimpleMarkdown() throws {
		let entries = Entry.entriesFromMarkdown("""
hello, world!
""")
		XCTAssertEqual(entries.count, 2)
	}
}
