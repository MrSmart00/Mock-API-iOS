{% include "Includes/Header.stencil" %}

import Foundation

public typealias File = Data

public struct DateDay: Codable, Comparable {

    /// The date formatter used for encoding and decoding
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.calendar = .current
        return formatter
    }()

    public let date: Date
    public let year: Int
    public let month: Int
    public let day: Int

    public init(date: Date = Date()) {
        self.date = date
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date)
        guard let year = dateComponents.year,
            let month = dateComponents.month,
            let day = dateComponents.day else {
                fatalError("Date does not contain correct components")
        }
        self.year = year
        self.month = month
        self.day = day
    }

    public init(year: Int, month: Int, day: Int) {
        let dateComponents = DateComponents(calendar: .current, year: year, month: month, day: day)
        guard let date = dateComponents.date else {
            fatalError("Could not create date in current calendar")
        }
        self.date = date
        self.year = year
        self.month = month
        self.day = day
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let date = DateDay.dateFormatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date not in correct format of \(DateDay.dateFormatter.dateFormat ?? "")")
        }
        self.init(date: date)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let string = DateDay.dateFormatter.string(from: date)
        try container.encode(string)
    }

    public static func == (lhs: DateDay, rhs: DateDay) -> Bool {
        return lhs.year == rhs.year &&
            lhs.month == rhs.month &&
            lhs.day == rhs.day
    }

    public static func < (lhs: DateDay, rhs: DateDay) -> Bool {
        return lhs.date < rhs.date
    }
}

extension DateDay {
    func encode() -> Any {
        return DateDay.dateFormatter.string(from: date)
    }
}

extension URL {
    func encode() -> Any {
        return absoluteString
    }
}

extension RawRepresentable {
    func encode() -> Any {
        return rawValue
    }
}

extension Array where Element: RawRepresentable {
    func encode() -> [Any] {
        return map { $0.rawValue }
    }
}

extension Dictionary where Key == String, Value: RawRepresentable {
    func encode() -> [String: Any] {
        return mapValues { $0.rawValue }
    }
}

extension UUID {
    func encode() -> Any {
        return uuidString
    }
}

extension String {
    func encode() -> Any {
        return self
    }
}

extension Data {

    func encode() -> Any {
        return self
    }
}

extension Int {
    func encode() -> Any {
        return self
    }
}
