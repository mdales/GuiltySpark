import XCTest

@testable import FrontMatter

final class FrontMatterDocumentTests: XCTestCase {

	func testEmptyDocument() throws {
		XCTAssertThrowsError(try FrontMatterDocument(data: Data())) { error in
			XCTAssertEqual(error as? FrontMatterDocumentError, .FailedToParseDocument)
		}
	}

	func testEmptyFront() throws {
		let testdoc = """
---
---
"""
		// Not sure this is ideal, but for now it's not the end of the world
		XCTAssertThrowsError(try FrontMatterDocument(data: Data(testdoc.utf8))) { error in
			XCTAssertEqual(error as? FrontMatterDocumentError, .FailedToParseYAML)
		}
	}

	func testGarbageFront() throws {
		let testdoc = """
---
//123/asd23/123
---
"""
		XCTAssertThrowsError(try FrontMatterDocument(data: Data(testdoc.utf8))) { error in
			XCTAssertEqual(error as? FrontMatterDocumentError, .FailedToParseYAML)
		}
	}

	func testJSONFront() throws {
		// Originally I planned this to be a failing test, but it turns out
		// libyaml parses JSON, so it passes. We might as well roll with this
		// because Hugo accepts JSON frontmatter.
		let testdoc = """
---
{"title": "hello, world"}
---
"""
		let document = try FrontMatterDocument(data: Data(testdoc.utf8))
		XCTAssertEqual(document.frontMatter.count, 1)
	}

	func testSimpleFront() throws {
		let testdoc = """
---
title: "Hello, world"
---
"""
		let document = try FrontMatterDocument(data: Data(testdoc.utf8))
		XCTAssertEqual(document.frontMatter.count, 1)
	}
}