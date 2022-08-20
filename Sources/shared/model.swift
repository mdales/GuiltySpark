import Foundation

public struct Entry: Codable {
	public enum EntryType: Codable {
		case tag(String)
		case content(String, Int)
	}

	let entry: EntryType

	public init(_ entry: EntryType) {
		self.entry = entry
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
		path.replacingOccurrences(of: ".md", with: ".html").lowercased()
	}
}
