import Foundation

public enum FrontMatterValue: Codable, Equatable {
	case stringValue(String)
	case arrayValue([String])
	case dateValue(Date)
	case intValue(Int)
	case booleValue(Bool)

	public static func fromAny(_ before: Any) -> FrontMatterValue {
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
		return FrontMatterValue.stringValue("\(before)")
	}
}
