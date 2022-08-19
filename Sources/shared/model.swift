import Foundation


public struct Entry: Codable {
	public enum EntryType: Codable {
		case tag(String)
		case content(String, Int)
	}

	let entry: EntryType

	public init(entry: EntryType) {
		self.entry = entry
	}
}

public struct Document: Codable {
	public let path: String
	public let title: String
	public let synopsis: String?
	let entries: [Entry]

	public init(
		path: String,
		title: String,
		synopsis: String?,
		entries: [Entry]
	) {
		self.path = path
		self.title = title
		self.synopsis = synopsis
		self.entries = entries
	}
}
