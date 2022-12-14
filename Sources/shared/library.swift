import Foundation

struct LibraryConfig: Codable {
	let corpusName: String
	let corpusFilePath: String
	let bibliographyFilePath: String
}

public enum LibraryError: Error {
	case CorpusNotFound
}

public struct Library {

	let engines: [String:NaiveSearchEngine]
	let bibliographies: [String:Bibliography]

	public static func loadConfig(configPath: String) throws -> Library {
		let config_url = URL(fileURLWithPath: configPath)
		let decoder = JSONDecoder()
		if #available(macOS 10.12, *) {
			decoder.dateDecodingStrategy = .iso8601
		}
		let config_data = try Data(contentsOf: config_url)
		let config = try decoder.decode([LibraryConfig].self, from: config_data)
		let engines = try config.reduce(into: [String:NaiveSearchEngine]()) {
			let corpus_url = URL(fileURLWithPath: $1.corpusFilePath)
			let corpus_data = try Data(contentsOf: corpus_url)
			let corpus = try decoder.decode([Document].self, from:corpus_data)
			$0[$1.corpusName] = NaiveSearchEngine(corpus)
		}
		let bibliographies = try config.reduce(into: [String:Bibliography]()) {
			$0[$1.corpusName] = try loadBibliography($1.bibliographyFilePath)
		}

		return Library(engines: engines, bibliographies: bibliographies)
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