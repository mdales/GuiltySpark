public struct NaiveSearchEngine {

	let index: [Document]
	let invertedIndex: Dictionary<String, [Int]>

	public init(_ documents: [Document]) {
		self.index = documents
		var invertedIndex = [String:[Int]]()
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
				var documentlist = invertedIndex[word.lowercased()] ?? []
				documentlist.insert(index, at: 0)
				invertedIndex[word.lowercased()] = documentlist
			}
		}
		self.invertedIndex = invertedIndex
	}

	func findMatches(_ terms: Set<String>) -> [Document] {
		return terms.flatMap{ term -> [Int] in
			self.invertedIndex[term] ?? []
		}.map{
			self.index[$0]
		}
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

	public func findAndRank(_ terms: Set<String>) -> [Document] {
		let normalised_terms = Set(terms.map { normaliseString($0) })
		return findMatches(normalised_terms).sorted {
			NaiveSearchEngine.rankMatch(terms: normalised_terms, document: $0) >
				NaiveSearchEngine.rankMatch(terms: normalised_terms, document: $1)
		}
	}
}
