import Foundation

import ArgumentParser
import PorterStemmer2

import FrontMatter
import shared

let fm = FileManager.default

func parseMarkdownDocument(_ path: URL, baseurl: URL) throws -> Document? {

	let document = try FrontMatterDocument(path)

	// The Yams parser doesn't give us a clean way to get the rest of the document, so we mostly let
	// it error trying to parse the data after the frontmatter and assume that the offset it gives us
	// is where the markdown starts
	// var markdown_mark: Mark? = nil
	// do {
	// 	let next = try parser.nextRoot()
	// 	markdown_mark = next?.mark
	// } catch YamlError.parser(_, let problem, let mark, _) {
	// 	markdown_mark = mark
	// } catch YamlError.scanner(_, let problem, let mark, let yaml) {
	// 	markdown_mark = mark
	// }
	// If there's other errors we don't handle let them bubble up, hence no catchall catch


	if let draft_status = document.frontMatter[KeyDraft] {
		switch draft_status {
		case .booleValue(let is_draft):
			if is_draft {
				return nil
			}
		default:
			break
		}
	}

	let things = Entry.entriesFromFrontmatter(document.frontMatter)

// 	if let markdown_mark = markdown_mark {
// 		if let document = String(data: data, encoding: .utf8) {
// 			// We now need to use the line number/offset to work out where the parser stopped working
// 			let lines = document.split(separator: "\n")
// 			let fail_line = markdown_mark.line - 1 // This is human readable line number
// 			if lines.count > fail_line {
// 				print(lines[fail_line])
// 			} else {
// 				print("document \(path) has \(lines.count) lines, and yaml fail is at \(markdown_mark)")
// 			}
//
// 			things += Entry.entriesFromMarkdown(document)
// 		}
// 	}

	var date: Date? = nil
	if let frontmatter_date = document.frontMatter[KeyDate] {
		switch frontmatter_date {
		case .dateValue(let val):
			date = val
		default:
			break
		}
	}
	guard let date = date else {
		return nil
	}

	return Document(
		path: String(path.path.dropFirst(baseurl.path.count + 1)),
		entries: things,
		date: date
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
			if #available(macOS 10.12, *) {
				jsonEncoder.dateEncodingStrategy = .iso8601
			}
			let jsonData = try jsonEncoder.encode(corpus)
			try jsonData.write(to: URL(fileURLWithPath: outputFile), options: [])
		} catch {
			print("Failed to read \(contentPath): \(error)")
		}
	}
}

Indexer.main()
