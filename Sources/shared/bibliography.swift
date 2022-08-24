import Foundation

public struct Thumbnail: Codable {
	let at1x: String
	let at2x: String

	private enum CodingKeys : String, CodingKey {
		case at1x = "1x"
		case at2x = "2x"
	}
}

public struct BibPage: Codable {
	let origin: String
	let link: String
	let title: String
	let date: Date
	let tags: [String]
	let thumbnail: Thumbnail?
	let synopsis: String?
}

public typealias Bibliography = [String:BibPage]

struct BibFile: Codable {
	let pages: [BibPage]
}

public func loadBibliography(_ path: String) throws -> Bibliography {
	let url = URL(fileURLWithPath: path)
	let data = try Data(contentsOf: url)
	let decoder = JSONDecoder()
	if #available(macOS 10.12, *) {
		decoder.dateDecodingStrategy = .iso8601
	}
	let bibfile = try decoder.decode(BibFile.self, from: data)
	return bibfile.pages.reduce(into: [String:BibPage]()) {
		$0[$1.origin] = $1
	}
}
