import Foundation

import ArgumentParser
import PorterStemmer2
import Yams

import shared

let fm = FileManager.default

enum ParseError: Error {
	case StemmerLoadFailure
}

func parseMarkdownDocument(_ path: URL, baseurl: URL) throws -> Document? {

	let data = try Data(contentsOf: path)
	let frontmatter = try Yams.Parser(yaml: data, resolver: .default, constructor: .default, encoding: .default)
		.nextRoot()?.any as? Dictionary<String,Any>

	guard let frontmatter = frontmatter else {
		return nil
	}

	let converted = frontmatter.mapValues(FrontmatterValue.fromAny)
	let things = Entry.entriesFromFrontmatter(converted)

	return Document(
		path: String(path.path.dropFirst(baseurl.path.count)),
		frontmatter: converted,
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
	@Argument() var outputFile: String

	func run() {
		print("looking in \(contentPath)")
		let corpus_url = URL(fileURLWithPath: contentPath)

		do {
			let corpus = try recursiveProcess(corpus_url, baseurl: corpus_url)
			print("we processed \(corpus.count) documents")

			let jsonEncoder = JSONEncoder()
			let jsonData = try jsonEncoder.encode(corpus)
			try jsonData.write(to: URL(fileURLWithPath: outputFile), options: [])
		} catch {
			print("Failed to read \(contentPath): \(error)")
		}
	}
}

Indexer.main()
