import ArgumentParser
import Foundation
import Yams

import shared

let fm = FileManager.default

func parseMarkdownDocument(_ path: URL, baseurl: URL) throws -> Document? {

	let data = try Data(contentsOf: path)
	let frontmatter = try Yams.Parser(yaml: data, resolver: .default, constructor: .default, encoding: .default)
		.nextRoot()?.any as? Dictionary<String,Any>

	guard let frontmatter = frontmatter else {
		return nil
	}

	var things: [Entry] = []
	if let tags = frontmatter["tags"] as? [String] {
		things = tags.map {
			Entry(
				entry: .tag($0)
			)
		}
	}
	return Document(
		path: String(path.path.dropFirst(baseurl.path.count)),
		title: frontmatter["title"] as? String ?? "Unknown title",
		synopsis: frontmatter["synopsis"] as? String,
		entries: things
	)
}

func recursiveProcess(_ path: URL, baseurl: URL) throws -> [Document] {
	// flatMap keeps binding to the deprecated optional version here for some reason
	// which is why I for now have a manual map/reduce
	try fm.contentsOfDirectory(at: path, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey]).flatMap { url -> [Document] in
		let properties = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
		if properties.isDirectory ?? false {
			return try recursiveProcess(url, baseurl: baseurl)
		} else if (properties.isRegularFile ?? false) && (url.pathExtension == "md") {
			if let doc = try parseMarkdownDocument(url, baseurl: baseurl) {
				return [doc]
			}
		}
		return []
	}
}

struct Indexer: ParsableCommand {
	@Argument() var contentPath: String

	func run() {
		print("looking in \(contentPath)")
		let corpus_url = URL(fileURLWithPath: contentPath)

		do {
			let corpus = try recursiveProcess(corpus_url, baseurl: corpus_url)
			print("we processed \(corpus.count) documents")

			let jsonEncoder = JSONEncoder()
			let jsonData = try jsonEncoder.encode(corpus)
			try jsonData.write(to: URL(fileURLWithPath: "corpus.json"), options: [])
		} catch {
			print("Failed to read \(contentPath): \(error)")
		}
	}
}

Indexer.main()
