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
		let config_url = URL(fileURLWithPath: corpusConfigPath)

		do {
			let library = try Library.loadConfig(config_url: config_url)
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
					res.send("Corpus not found")
					return
				} catch {
					res.send("Unexpected error: \(error)")
					return
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
					if #available(macOS 10.12, iOS 10.0, *) {
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