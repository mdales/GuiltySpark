import ArgumentParser
import Foundation
import MicroExpress

import shared

struct Result: Codable {
	let path: String
	let frontmatter: [String:FrontmatterValue]
}

struct Config: Codable {
	let corpusName: String
	let corpusFilePath: String
}

struct Searcher: ParsableCommand {
	@Argument() var corpusConfigPath: String

	func run() {
		let config_url = URL(fileURLWithPath: corpusConfigPath)
		let decoder = JSONDecoder()

		do {
			let config_data = try Data(contentsOf: config_url)
			let config = try decoder.decode([Config].self, from: config_data)
			let engines = try config.reduce(into: [String:NaiveSearchEngine]()) {
				let corpus_url = URL(fileURLWithPath: $1.corpusFilePath)
				let corpus_data = try Data(contentsOf: corpus_url)
				let corpus = try decoder.decode([Document].self, from:corpus_data)
				$0[$1.corpusName] = NaiveSearchEngine(corpus)
			}

			let server = Express()

			// Logging
			server.use { req, res, next in
			 	print("\(req.header.method):", req.header.uri)
			    next()
			}

			server.use(querystring)

			server.get("/search/") {req, res, next in

				var corpusSelection: String? = nil

				// try to find which corpus to use by header
				if let header = req.header.headers.filter{ $0.0 == "X-Corpus"}.first {
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
				guard let engine = engines[corpusSelection] else {
					res.send("Corpus not found")
					return
				}

				guard let query = req.param("q") else {
					res.send("No info")
					return
				}

				let hits = engine.findAndRank(query)
				let results = hits.map {
					Result(
						path: $0.publishedPath,
						frontmatter: $0.frontmatter
					)
				}
				res.json(results)
			}

			server.get("/") { req, res, next in
			  	res.send("Hello World")
			}

			server.listen(4242)
		} catch {
			print("Failed to open corpus: \(error)")
			return
		}
	}
}

Searcher.main()