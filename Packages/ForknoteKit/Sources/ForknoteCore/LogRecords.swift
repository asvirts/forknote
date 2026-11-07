import Foundation

public struct MealRecord: Sendable, Equatable, Identifiable {
    public var id: UUID
    public var eatenAt: Date
    public var foods: [String]
    public var note: String

    public init(id: UUID, eatenAt: Date, foods: [String], note: String) {
        self.id = id
        self.eatenAt = eatenAt
        self.foods = foods
        self.note = note
    }
}

public struct SymptomRecord: Sendable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var severity: Int
    public var occurredAt: Date

    public init(id: UUID, name: String, severity: Int, occurredAt: Date) {
        self.id = id
        self.name = name
        self.severity = severity
        self.occurredAt = occurredAt
    }

    public var strength: Int { min(5, max(1, severity)) }
}

/// Half-open range `[start, end)`. A nil start means the whole log up to `end`.
public struct AnalysisRange: Sendable, Equatable {
    public var start: Date?
    public var end: Date

    public init(start: Date?, end: Date) {
        self.start = start
        self.end = end
    }

    public static func lastSevenDays(ending now: Date, calendar: Calendar) -> AnalysisRange {
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? now
        return AnalysisRange(start: start, end: end)
    }

    public static func fullHistory(ending now: Date, calendar: Calendar) -> AnalysisRange {
        let today = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? now
        return AnalysisRange(start: nil, end: end)
    }
}
