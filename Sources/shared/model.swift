import Foundation

import PorterStemmer2

import FrontMatter

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
public let KeyDate = "date"
public let KeyDraft = "draft"

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

	static public func entriesFromFrontmatter(_ frontmatter: [String:FrontMatterValue]) -> [Entry] {
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

	static public func entriesFromMarkdown(_ markdown: String) -> [Entry] {
		return []
	}
}

public struct Document: Codable, Hashable {
	public let path: String
	let entries: [Entry]
	let date: Date

	public init(
		path: String,
		entries: [Entry],
		date: Date
	) {
		self.path = path
		self.entries = entries
		self.date = date
	}

	public static func == (lhs: Document, rhs: Document) -> Bool {
		return lhs.path == rhs.path
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(path)
	}
}
