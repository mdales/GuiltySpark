import XCTest

@testable import FrontMatter

final class FrontMatterDocumentTests: XCTestCase {

	func testEmptyDocument() throws {
		XCTAssertThrowsError(try FrontMatterDocument(data: Data())) { error in
			XCTAssertEqual(error as? FrontMatterDocumentError, .FailedToFindFirstDelimiter)
		}
	}

	func testEmptyFront() throws {
		let testdoc = """
---
---
"""
		// Not 100% sure this should be an error, rather than no data?
		XCTAssertThrowsError(try FrontMatterDocument(data: Data(testdoc.utf8))) { error in
			XCTAssertEqual(error as? FrontMatterDocumentError, .FailedToFindFrontmatterRoot)
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
{"title": "Hello, world"}
---
"""
		let document = try FrontMatterDocument(data: Data(testdoc.utf8))
		XCTAssertEqual(document.frontMatter.count, 1)
		XCTAssertEqual(document.frontMatter["title"], FrontMatterValue.stringValue("Hello, world"))
	}

	func testMissingFirstDelimiter() throws {
		let testdoc = """
title: "Hello, world"
---
"""
		// There is one delimiter in there, and our parser ignores data before the first
		// delimiter, so hence this is a missing second delimiter
		XCTAssertThrowsError(try FrontMatterDocument(data: Data(testdoc.utf8))) { error in
			XCTAssertEqual(error as? FrontMatterDocumentError, .FailedToFindSecondDelimiter)
		}
	}

	func testMissingSecondDelimiter() throws {
		let testdoc = """
---
title: "Hello, world"
"""
		XCTAssertThrowsError(try FrontMatterDocument(data: Data(testdoc.utf8))) { error in
			XCTAssertEqual(error as? FrontMatterDocumentError, .FailedToFindSecondDelimiter)
		}
	}

	func testEmptyMarkdownDocument() throws {
		let testdoc = """
---
title: "Hello, world"
---
"""
		let document = try FrontMatterDocument(data: Data(testdoc.utf8))
		XCTAssertEqual(document.frontMatter.count, 1)
		XCTAssertEqual(document.frontMatter["title"], FrontMatterValue.stringValue("Hello, world"))
		XCTAssertEqual(document.rawMarkdown, "")
		XCTAssertEqual(document.plainText, "")
	}

	func testSimpleDocument() throws {
		let testdoc = """
---
title: "Hello, world"
---
This is a doc
"""
		let document = try FrontMatterDocument(data: Data(testdoc.utf8))
		XCTAssertEqual(document.frontMatter.count, 1)
		XCTAssertEqual(document.frontMatter["title"], FrontMatterValue.stringValue("Hello, world"))
		XCTAssertEqual(document.rawMarkdown, "This is a doc")
		XCTAssertEqual(document.plainText, "This is a doc")
	}

	func testDocumentWithMarkdownHorizontalRule() throws {
		// Basically we want to know this wasn't treated as a frontmatter delimiter
		let testdoc = """
---
title: "Hello, world"
---
This is a doc
---
"""
		let document = try FrontMatterDocument(data: Data(testdoc.utf8))
		XCTAssertEqual(document.frontMatter.count, 1)
		XCTAssertEqual(document.frontMatter["title"], FrontMatterValue.stringValue("Hello, world"))
		XCTAssertEqual(document.rawMarkdown, "This is a doc\n---")
		XCTAssertEqual(document.plainText, "This is a doc")
	}

	func testDocumentWithMarkdownLink() throws {
		// Basically we want to know this wasn't treated as a frontmatter delimiter
		let testdoc = """
---
title: "Hello, world"
---
This is a [doc](https://example.com)
"""
		let document = try FrontMatterDocument(data: Data(testdoc.utf8))
		XCTAssertEqual(document.frontMatter.count, 1)
		XCTAssertEqual(document.frontMatter["title"], FrontMatterValue.stringValue("Hello, world"))
		XCTAssertEqual(document.rawMarkdown, "This is a [doc](https://example.com)")
		XCTAssertEqual(document.plainText, "This is a doc")
	}

	func testDocumentWithMarkdownHeading() throws {
		// Basically we want to know this wasn't treated as a frontmatter delimiter
		let testdoc = """
---
title: "Hello, world"
---
# This is a doc
"""
		let document = try FrontMatterDocument(data: Data(testdoc.utf8))
		XCTAssertEqual(document.frontMatter.count, 1)
		XCTAssertEqual(document.frontMatter["title"], FrontMatterValue.stringValue("Hello, world"))
		XCTAssertEqual(document.rawMarkdown, "# This is a doc")
		XCTAssertEqual(document.plainText, "This is a doc")
	}
}
