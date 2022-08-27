import Foundation

struct LibraryConfig: Codable {
	let corpusName: String
	let corpusFilePath: String
	let bibliographyFilePath: String
}

public enum LibraryError: Error {
	case CorpusNotFound
}

public final class Library {

	let engines: [String:NaiveSearchEngine]
	let bibliographies: [String:Bibliography]

	public init(config_url: URL) throws {
		let decoder = JSONDecoder()
		let config_data = try Data(contentsOf: config_url)
		let config = try decoder.decode([LibraryConfig].self, from: config_data)
		engines = try config.reduce(into: [String:NaiveSearchEngine]()) {
			let corpus_url = URL(fileURLWithPath: $1.corpusFilePath)
			let corpus_data = try Data(contentsOf: corpus_url)
			let corpus = try decoder.decode([Document].self, from:corpus_data)
			$0[$1.corpusName] = NaiveSearchEngine(corpus)
		}
		bibliographies = try config.reduce(into: [String:Bibliography]()) {
			$0[$1.corpusName] = try loadBibliography($1.bibliographyFilePath)
		}
	}

	public func find(corpus: String, query: String) throws -> [BibPage] {
		guard let engine = engines[corpus] else {
			throw LibraryError.CorpusNotFound
		}
		guard let bibliography = bibliographies[corpus] else {
			throw LibraryError.CorpusNotFound
		}

		return engine.findAndRank(query).compactMap { doc -> BibPage? in
			bibliography[doc.path]
		}
	}
}