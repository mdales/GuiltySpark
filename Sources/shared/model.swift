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

public enum Entry: Codable {
	case tag(String)
	case title(String)
	case content(String)

	static public func entriesFromFrontmatter(_ frontmatter: [String:FrontMatterValue]) -> [Entry] {
		var things: [Entry] = []
		if let tags = frontmatter[KeyTags] {
			switch tags {
			case .stringValue(let tag):
				things += NaiveSearchEngine.tokeniseString(tag).map {
					Entry.tag($0)
				}
			case .arrayValue(let tags):
				things += Set(tags.flatMap { NaiveSearchEngine.tokeniseString($0) }).map {
					Entry.tag($0)
				}
			default:
				break
			}
		}

		if let title = frontmatter[KeyTitle] {
			switch title {
			case .stringValue(let title):
				let parts = NaiveSearchEngine.tokeniseString(title)
					.map { Entry.title($0) }
				things += parts
			default:
				break
			}
		}
		return things
	}

	static public func entriesFromMarkdown(_ markdown: String) -> [Entry] {
		return NaiveSearchEngine.tokeniseString(markdown).map {Entry.content($0)}
	}
}

public struct Document: Codable, Hashable {
	public let path: String
	public let entries: [Entry]
	public let date: Date

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

	static public func calculateCommonStems(_ documents: [Document]) -> [String] {
		var wordFrequency: [String:Int] = [:]

		var contributingDocs = 0
		for document in documents {
			var contributed = false
			for entry in document.entries {
				switch entry {
				case .content(let val):
					if let frequency = wordFrequency[val] {
						wordFrequency[val] = frequency + 1
					} else {
						wordFrequency[val] = 1
					}
					contributed = true
				default:
					break
				}
				if contributed {
					contributingDocs += 1
				}
			}
		}

		// How to define common is difficult. The aim here is to remove words of high
		// frequency but not remove words that are of import. E.g., my blog about guitars
		// has a very high occurrence of the word guitar, but people expect to find
		// results if they search for that term.
		//
		// It might be also tempting to say go by what is in say above 90% of pages or
		// some other watermark, but then I have another site where 20% or so of pages
		// don't contain "proper" sentences, and so push down the occurrence of the obvious
		// words from high nineties to mid seventies percent wise.
		//
		// There is no perfect here, we just want something that works okay and stops
		// the corpus becoming pointlessly bloated.
		let documentFrequncyThreshold = Int(Double(contributingDocs) * 0.80)
    	return wordFrequency
			.filter{$0.value < documentFrequncyThreshold}
			.filter{$0.key.count < 5}
			.sorted{$0.1 > $1.1}
			.map{$0.key}
	}
}
