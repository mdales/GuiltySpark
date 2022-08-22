import Foundation

import PorterStemmer2

// Don't like having this global, but not sure where better
// to put it?
let stemmer = PorterStemmer(withLanguage: .English)!

public func normaliseString(_ term: String) -> String {
	return stemmer.stem(term.lowercased())
}

// These are the words used in *my* frontmatter, I imagine this will need to
// be in a configuration file long term
let KeyTags = "tags"
let KeyTitle = "title"

public struct Entry: Codable {
	public enum EntryType: Codable {
		case tag(String)
		case title(String)
		case content(String, Int)
	}

	let entry: EntryType

	public init(_ entry: EntryType) {
		self.entry = entry
	}

	static public func entriesFromFrontmatter(_ frontmatter: [String:FrontmatterValue]) -> [Entry] {
		var things: [Entry] = []
		if let tags = frontmatter[KeyTags] {
			switch tags {
			case .stringValue(let tag):
				things += NaiveSearchEngine.tokeniseString(tag).map {
					Entry(.tag(normaliseString($0)))
				}
			case .arrayValue(let tags):
				things += Set(tags.flatMap { NaiveSearchEngine.tokeniseString($0) }).map {
					Entry(.tag($0))
				}
			default:
				break
			}
		}

		if let title = frontmatter[KeyTitle] {
			switch title {
			case .stringValue(let title):
				let parts = NaiveSearchEngine.tokeniseString(title)
					.map { Entry(.title($0)) }
				things += parts
			default:
				break
			}
		}
		return things
	}
}

public enum FrontmatterValue: Codable, Equatable {
	case stringValue(String)
	case arrayValue([String])
	case dateValue(Date)
	case intValue(Int)
	case booleValue(Bool)

	public static func fromAny(_ before: Any) -> FrontmatterValue {
		if let value = before as? String {
			return .stringValue(value)
		} else if let value = before as? Date {
			return .dateValue(value)
		} else if let value = before as? [String] {
			return .arrayValue(value)
		} else if let value = before as? Bool {
			return .booleValue(value)
		} else if let value = before as? Int {
			return .intValue(value)
		}
		// clearly ick, but given YML is untyped the best I think we can do
		return FrontmatterValue.stringValue("\(before)")
	}
}

public struct Document: Codable {
	public let path: String
	public let frontmatter: [String:FrontmatterValue]
	let entries: [Entry]

	public init(
		path: String,
		frontmatter: [String:FrontmatterValue],
		entries: [Entry]
	) {
		self.path = path
		self.frontmatter = frontmatter
		self.entries = entries
	}

	public var publishedPath: String {
		let url = URL(fileURLWithPath: self.path)
		let filename = url.lastPathComponent
		if filename == "index.md" {
			return path.replacingOccurrences(of: ".md", with: ".html").lowercased()
		} else {
			return path.replacingOccurrences(of: ".md", with: "/index.html").lowercased()
		}
	}
}
