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
				guard let engine = engines[corpusSelection] else {
					res.send("Corpus not found")
					return
				}

				guard let query = req.param("q") else {
					res.send("No info")
					return
				}
				guard let decoded_query = query.removingPercentEncoding else {
					res.send("Faied to decode")
					return
				}

				let hits = engine.findAndRank(decoded_query)
				let results = hits.map {
					Result(
						path: $0.publishedPath,
						frontmatter: $0.frontmatter
					)
				}

				do {
					// The MicroExpress JSON handler just does the default encoding strategy
					// with JSON codables, which means the date comes out in a Swift/Apple
					// specific value that is number of seconds since 2001.
					//
					// In theory we could just write a new extension to the MicroExpress
					// server response class, but they haven't made public all the necessary
					// methods on the class definition (most are, but not all). I'll file
					// an issue and see if I can get this fix upstreamed.
					//
					// Note that this code has been tested and works on Linux with the latest
					// Swift release, despite the compiler insisting I put a macOS warning on
					// the code :)
					let encoder = JSONEncoder()
					if #available(macOS 12.0, *) {
						encoder.dateEncodingStrategy = .iso8601
					}
					let data = try encoder.encode(results)
					res["Content-Type"]   = "application/json"
					res["Content-Length"] = "\(data.count)"
					res.send(bytes: data)
				} catch {
					res.send("Failed to encode response")
				}
			}

			server.get("/") { req, res, next in
			  	res.send("Hello, World!")
			}

			server.listen(4242)
		} catch {
			print("Failed to open corpus: \(error)")
			return
		}
	}
}

Searcher.main()