import ArgumentParser
import Foundation
import MicroExpress

import shared

struct Result: Codable {
	let path: String
	let frontmatter: [String:FrontmatterValue]
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

				let parts = text.components(separatedBy: .whitespacesAndNewlines)
					.filter{$0.count > 0}.map{$0.lowercased()}

				let hits = engine.findAndRank(Set(parts))
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