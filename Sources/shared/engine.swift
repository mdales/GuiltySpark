import Foundation

public struct NaiveSearchEngine {

	let index: [Document]
	let invertedIndex: [String:Set<Int>]

	public init(_ documents: [Document]) {
		self.index = documents
		var invertedIndex = [String:Set<Int>]()
		for (index, document) in documents.enumerated() {
			document.entries.forEach { entry in
				var word: String? = nil
				switch (entry.entry) {
				case let .tag(value):
					word = value
				case let .content(value, _):
					word = value
				case let .title(value):
					word = value
				}
				guard let word = word else {
					return
				}
				var documentlist = invertedIndex[word.lowercased()] ?? Set<Int>()
				documentlist.insert(index)
				invertedIndex[word.lowercased()] = documentlist
			}
		}
		self.invertedIndex = invertedIndex
	}

	public static func tokeniseString(_ query: String) -> Set<String> {
		let seperators = CharacterSet.whitespacesAndNewlines.union(CharacterSet.punctuationCharacters)
		return Set(query.components(separatedBy: seperators)
			.filter{$0.count > 0}.map{normaliseString($0)})
	}

	func findMatches(_ terms: Set<String>) -> Set<Document> {
		return Set(terms.flatMap{ term -> Set<Int> in
			self.invertedIndex[term] ?? Set<Int>()
		}.map{
			self.index[$0]
		})
	}

	static func rankMatch(terms: Set<String>, document: Document) -> Int {
		return document.entries.map { entry -> Int in
			switch entry.entry {
			case .tag(let value):
				return 100 * terms.filter{$0 == value}.count
			case .title(let value):
				return 10 * terms.filter{$0 == value}.count
			case .content(let value, _):
				return 1 * terms.filter{$0 == value}.count
			}
		}.reduce(0, +)
	}

	public func findAndRank(_ term: String) -> [Document] {
		let terms = NaiveSearchEngine.tokeniseString(term)
		return findMatches(terms).sorted {
			let lhs = NaiveSearchEngine.rankMatch(terms: terms, document: $0)
			let rhs = NaiveSearchEngine.rankMatch(terms: terms, document: $1)
			if lhs == rhs {
				return $0.date > $1.date
			} else {
				return lhs > rhs
			}
		}
	}
}
