import Foundation

import Yams
import Markdown

public enum FrontMatterDocumentError: Error {
	case FailedToFindFirstDelimiter
	case FailedToFindSecondDelimiter
	case FailedToFindFrontmatterRoot
	case FailedToParseYAML
}

struct TextCollector: MarkupWalker {
	var plainText = ""
	mutating func visitText(_ text: Text) {
		if !text.string.isEmpty {
			plainText += text.string
			if !text.string.suffix(1).trimmingCharacters(in: .whitespaces).isEmpty {
				plainText += " "
			}
		}
		descendInto(text)
	}
}

public struct FrontMatterDocument {
	public let frontMatter: [String:FrontMatterValue]
	public let markdownDocument: Document
	public let rawMarkdown: String

	public var plainText: String {
		var collector = TextCollector()
		collector.visit(self.markdownDocument)
		let prose = collector.plainText
		if !prose.isEmpty {
			return String(prose[prose.startIndex..<((prose.index(before: prose.endIndex)))])
		} else {
			return prose
		}
	}

	init(data: Data) throws {

		// Split the file as per standard frontmatter requirements. Frontmatter isn't
		// well specified, so we just do something that is vaguely tolerant of people
		// doing different bits.
		//
		// There's a good argument that the delimiter should really be "^---\w+$" and
		// consume the return, but I'm parsing the data not the string, and currently
		// it doesn't impact my usecase either way.
		let delimiter = Data("---".utf8)

		guard let firstmark = data.range(of: delimiter) else {
			throw FrontMatterDocumentError.FailedToFindFirstDelimiter
		}
		let remainderRange: Range<Data.Index> = firstmark.upperBound..<data.count
		guard let secondmark = data.range(of: delimiter, options: [], in: remainderRange) else {
			throw FrontMatterDocumentError.FailedToFindSecondDelimiter
		}

		let frontmatterRange: Range<Data.Index> = firstmark.upperBound..<secondmark.lowerBound
		let frontmatterData = data.subdata(in: frontmatterRange)

		let yamlRoot = try Yams.Parser(yaml: frontmatterData, resolver: .default, constructor: .default, encoding: .default).singleRoot()
		guard let frontmatterNode = yamlRoot else {
			throw FrontMatterDocumentError.FailedToFindFrontmatterRoot
		}

		let frontmatter = frontmatterNode.any as? Dictionary<String,Any>
		guard let frontmatter = frontmatter else {
			throw FrontMatterDocumentError.FailedToParseYAML
		}
		self.frontMatter = frontmatter.mapValues(FrontMatterValue.fromAny)

		let markdownRange: Range<Data.Index> = secondmark.upperBound..<data.count
		let markdownData = data.subdata(in: markdownRange)
		let markdown = String(decoding: markdownData, as: UTF8.self)

		self.markdownDocument = Document(parsing: markdown)

		// Because of our delimiter choice, the markdown string starts with
		// at least a carriage return, and possibly other whitespace, which is
		// probably not expected, so we now strip any leading data to the first
		// return. This again is weak, but then frontmatter is a vague spec, and
		// we can do better later when we have suitable test cases.
		if let prefix = markdown.firstIndex(of: "\n") {
			self.rawMarkdown = String(markdown[markdown.index(after: prefix)...])
		} else {
			// didn't spot the return, so play it safe for now
			self.rawMarkdown = markdown
		}
	}

	public init(_ documentPath: URL) throws {
		let data = try Data(contentsOf: documentPath)
		try self.init(data: data)
	}
}
