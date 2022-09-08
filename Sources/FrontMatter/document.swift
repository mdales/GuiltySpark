import Foundation

import Yams

public enum FrontMatterDocumentError: Error {
	case FailedToParseDocument
	case FailedToParseYAML
}

public struct FrontMatterDocument {
	public let frontMatter: [String:FrontMatterValue]

	init(data: Data) throws {
		let parser = try Yams.Parser(yaml: data, resolver: .default, constructor: .default, encoding: .default)
		guard let frontmatterNode = try parser.nextRoot() else {
			throw FrontMatterDocumentError.FailedToParseDocument
		}

		let frontmatter = frontmatterNode.any as? Dictionary<String,Any>
		guard let frontmatter = frontmatter else {
			throw FrontMatterDocumentError.FailedToParseYAML
		}
		self.frontMatter = frontmatter.mapValues(FrontMatterValue.fromAny)
	}

	public init(_ documentPath: URL) throws {
		let data = try Data(contentsOf: documentPath)
		try self.init(data: data)
	}
}
