import ArgumentParser
import Foundation
import MicroExpress

import shared

struct Config: Codable {
	let corpusName: String
	let corpusFilePath: String
	let bibliographyFilePath: String
}

struct Searcher: ParsableCommand {
	@Argument() var corpusConfigPath: String

	func run() {
		let library: Library
		do {
			library = try Library.loadConfig(configPath: corpusConfigPath)
		} catch {
			print("Failed to load corpus: \(error)")
			return
		}

		let server = Express()
		server.use { req, res, next in
		 	print("\(req.header.method):", req.header.uri)
		    next()
		}
		server.use(querystring)
		server.get("/search/") {req, res, next in

			var corpusSelection: String? = nil

			// try to find which corpus to use by header
			if let header = req.header.headers.filter({ $0.0 == "X-Corpus"}).first {
				corpusSelection = header.1
			}
			// query arg takes precedence over header
			if let corpus_arg = req.param("corpus") {
				corpusSelection = corpus_arg;
			}
			guard let corpusSelection = corpusSelection else {
				res.send("No corpus secified")
				return
			}

			guard let query = req.param("q") else {
				res.send("No info")
				return
			}
			guard let decoded_query = query.removingPercentEncoding else {
				res.send("Failed to decode")
				return
			}

			let results: [BibPage]
			do {
				results = try library.find(corpus: corpusSelection, query: decoded_query)
			} catch LibraryError.CorpusNotFound {
				res.send("Corpus \(corpusSelection) not found")
				return
			} catch {
				res.send("Unexpected error: \(error)")
				return
			}

			res.json(results)
		}

		server.get("/") { req, res, next in
		  	res.send("Hello, World!")
		}

		server.listen(4242)
	}
}

Searcher.main()