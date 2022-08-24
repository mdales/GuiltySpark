import XCTest

@testable import shared

final class bibliographyTests: XCTestCase {

	func testFullItemDecode() throws {
		let json = """
		{
		  "title": "Some notes",
		  "link": "/blog/some-notes/",
		  "date": "2022-04-21T09:13:56Z",
		  "synopsis": "A look at stuff.",
		  "thumbnail": {
			"1x": "120x120_fit_box.png",
			"2x": "240x240_fit_box.png"
		  },
		  "tags": [
			"stuff",
			"notes"
		  ],
		  "origin": "blog/some-notes/index.md"
		}
		"""
		let data = Data(json.utf8)
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		let item = try decoder.decode(BibPage.self, from: data)
		XCTAssertEqual(item.title, "Some notes")
		XCTAssertNotNil(item.synopsis)
		XCTAssertNotNil(item.thumbnail)
		XCTAssertEqual(item.tags.count, 2)
	}

	func testMinimalItemDecode() throws {
		let json = """
		{
		  "title": "Search",
		  "link": "/search/",
		  "date": "2022-08-21T15:22:55+0100",
		  "tags": [],
		  "origin": "search/index.md"
		}
		"""
		let data = Data(json.utf8)
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		let item = try decoder.decode(BibPage.self, from: data)
		XCTAssertEqual(item.title, "Search")
		XCTAssertNil(item.synopsis)
		XCTAssertNil(item.thumbnail)
		XCTAssertEqual(item.tags.count, 0)
	}
}