import XCTest

import shared

final class sharedTests: XCTestCase {

    func testNormaliseString() throws {
        XCTAssertEqual(normaliseString("abc"), "abc")
        XCTAssertEqual(normaliseString("ABC"), "abc")
        XCTAssertEqual(normaliseString("like"), "like")
        XCTAssertEqual(normaliseString("likely"), "like")
        XCTAssertEqual(normaliseString("liked"), "like")

        // This is Swedish, so the fact it loses the n is gramatically wrong
        // but we did set PorterStemmer to English, and so long as it is
        // consistent it doesn't matter that it's an odd stemming for that
        // particular language.
        XCTAssertEqual(normaliseString("älgen"), "älge")

        // Emoji fail with the current stemmer :(
        // XCTAssertEqual(normaliseString("🎸"), "🎸")
    }

    func testCalculateCommonStemsEmpty() {
        let stems = Document.calculateCommonStems([])
        XCTAssertEqual(stems.count, 0)
    }

    func testCalculateCommonStemsOneDoc() {
        let documents = [
            Document(
                path: "/a",
                entries: [Entry.content("hi"), Entry.content("world")],
                date: Date()
            )
        ]
        let stems = Document.calculateCommonStems(documents)
        XCTAssertEqual(stems.count, 0)
    }

    func testCalculateCommonStemsManyDocs() {
        let documents = (0..<4).indices.map{
            Document(
                path: "\($0)",
                entries: [Entry.content("hi"), Entry.content("world")],
                date: Date()
            )
        }
        let stems = Document.calculateCommonStems(documents)
        // world is not filtered due to length, but hi is as it is in over 80% of docs
        XCTAssertEqual(stems, ["hi"])
    }

    func testCalculateCommonStemsIgnoresTags() {
        let documents = (0..<4).indices.map{
            Document(
                path: "\($0)",
                entries: [Entry.tag("hi"), Entry.tag("world")],
                date: Date()
            )
        }
        let stems = Document.calculateCommonStems(documents)
        XCTAssertEqual(stems.count, 0)
    }

    func testCalculateCommonStemsIgnoresTitles() {
        let documents = (0..<4).indices.map{
            Document(
                path: "\($0)",
                entries: [Entry.title("hi"), Entry.title("world")],
                date: Date()
            )
        }
        let stems = Document.calculateCommonStems(documents)
        XCTAssertEqual(stems.count, 0)
    }
}
