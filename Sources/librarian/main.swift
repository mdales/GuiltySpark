import ArgumentParser
import Foundation
import MicroExpress

import shared

struct Config: Codable {
	let corpusName: String
	let corpusFilePath: String
	let bibliographyFilePath: String
}

final class Server {

	let corpusConfigPath: String
	let library: Library
	let server: Express
	let port = 4242

	init(_ corpusConfigPath: String) throws {
		self.corpusConfigPath = corpusConfigPath
		self.library = try Library.loadConfig(configPath: corpusConfigPath)

		server = Express()
		server.use { req, res, next in
			 print("\(req.header.method):", req.header.uri)
			next()
		}
		server.use(querystring)
		server.get("/search", middleware: searchHandler)
	}

	func run() {
		server.listen(port)
	}

	func searchHandler (req: IncomingMessage, res: ServerResponse, next: Next) -> Void {
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
}

struct Searcher: ParsableCommand {
	@Argument() var corpusConfigPath: String

	func run() {
		let server: Server
		do {
			server = try Server(corpusConfigPath)
		} catch {
			print("Failed to construct server: \(error)")
			return
		}
		server.run()
	}
}

Searcher.main()