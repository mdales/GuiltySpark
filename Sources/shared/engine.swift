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

	public func findMatches(_ terms: [String]) -> [Document] {
		return terms.flatMap{ term -> [Int] in
			self.invertedIndex[term.lowercased()] ?? []
		}.map{
			self.index[$0]
		}
	}
}
