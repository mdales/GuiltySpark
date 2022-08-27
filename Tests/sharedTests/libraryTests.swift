import XCTest

@testable import shared

final class libraryTests: XCTestCase {

	func testBasicLookup() throws {
		let library = Library(
			engines: ["site1": NaiveSearchEngine([])],
			bibliographies: ["site1": [:]]
		)

		XCTAssertEqual(try library.find(corpus: "site1", query: "test").count, 0)
	}

	func testNoMatchingCorpus() throws {
		let library = Library(
			engines: ["site1": NaiveSearchEngine([])],
			bibliographies: ["site1": [:]]
		)

		XCTAssertThrowsError(try library.find(corpus: "notsite", query: "test")) { error in
			XCTAssertEqual(error as? LibraryError, .CorpusNotFound)
		}
	}
}