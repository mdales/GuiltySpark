import Foundation

import ArgumentParser
import PorterStemmer2
import Yams

import shared

let fm = FileManager.default

// These are the words used in *my* frontmatter, I imagine this will need to
// be in a configuration file long term
let KeyTags = "tags"
let KeyTitle = "title"

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
	var things: [Entry] = []
	if let tags = converted[KeyTags] {
		switch tags {
		case .stringValue(let tag):
			things = [Entry(.tag(normaliseString(tag)))]
		case .arrayValue(let tags):
			things = Set(tags.map { normaliseString($0) }).map {
				Entry(.tag($0))
			}
		default:
			break
		}
	}

	if let title = converted[KeyTitle] {
		switch title {
		case .stringValue(let title):
			let parts = Set(title.components(separatedBy: .whitespacesAndNewlines)
				.filter { $0.count > 0 }
				.map { normaliseString($0) })
				.map { Entry(.title($0)) }
			things += parts
		default:
			break
		}
	}

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
