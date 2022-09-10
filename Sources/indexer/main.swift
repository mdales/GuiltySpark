import Foundation

import ArgumentParser
import PorterStemmer2

import FrontMatter
import shared

let fm = FileManager.default

func parseMarkdownDocument(_ path: URL, baseurl: URL) throws -> Document? {

	let document = try FrontMatterDocument(path)

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

	let things = Entry.entriesFromFrontmatter(document.frontMatter) +
		Entry.entriesFromMarkdown(document.plainText)

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

func calculateStats(_ documents: [Document]) {
	var wordFrequency: [String:Int] = [:]

	var doccount = 0
	for document in documents {
		var count = 0
		for entry in document.entries {
			switch entry.entry {
			case .content(let val):
				count = count + 1
				if let frequency = wordFrequency[val] {
					wordFrequency[val] = frequency + 1
				} else {
					wordFrequency[val] = 1
				}
			default:
				break
			}
		}
		if count > 0 {
			doccount += 1
		}
	}

	print("There are \(wordFrequency.count) unique stems in \(doccount) documents")

	let sorted = wordFrequency.sorted { $0.1 > $1.1 }
	for (index, entry) in sorted[0..<20].enumerated() {
		print("\(index + 1): \(entry.key) \(String(format: "%.2f", (Double(entry.value) / Double(documents.count)) * 100.0))%")
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

			calculateStats(corpus)

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
