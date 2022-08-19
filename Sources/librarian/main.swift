import ArgumentParser
import Foundation
import MicroExpress

import shared

struct Result: Codable {
	let title: String
	let synopsis: String?
	let path: String
}

struct Searcher: ParsableCommand {
	@Argument() var corpusPath: String

	func run() {
		let corpus_url = URL(fileURLWithPath: corpusPath)
		do {
			let data = try Data(contentsOf: corpus_url)
			let corpus = try JSONDecoder().decode([Document].self, from: data)
			print("Loaded \(corpus.count) documents")
			let engine = NaiveSearchEngine(corpus)
			let server = Express()

			// Logging
			server.use { req, res, next in
			 	print("\(req.header.method):", req.header.uri)
			     next()
			}

			server.use(querystring)

			server.get("/search/") {req, res, next in
				guard let text = req.param("q") else {
					res.send("No info")
					return
				}
				let hits = engine.findMatches(term: text)
				let results = hits.map {
					Result(
						title: $0.title,
						synopsis: $0.synopsis,
						path: $0.path.replacingOccurrences(of: "md", with: "html")
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