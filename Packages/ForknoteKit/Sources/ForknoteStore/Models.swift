import Foundation
import SwiftData

@Model
public final class Meal {
    public var id: UUID = UUID()
    public var eatenAt: Date = Date.now
    public var note: String = ""
    public var foods: [String] = []
    public var createdAt: Date = Date.now

    public init(eatenAt: Date = .now, foods: [String], note: String = "", createdAt: Date = .now) {
        self.id = UUID()
        self.eatenAt = eatenAt
        self.foods = foods
        self.note = note
        self.createdAt = createdAt
    }
}

@Model
public final class SymptomEvent {
    public var id: UUID = UUID()
    public var name: String = ""
    public var severity: Int = 1
    public var occurredAt: Date = Date.now
    public var createdAt: Date = Date.now

    public init(name: String, severity: Int, occurredAt: Date = .now, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.severity = min(5, max(1, severity))
        self.occurredAt = occurredAt
        self.createdAt = createdAt
    }
}

@Model
public final class SymptomLabel {
    public var id: UUID = UUID()
    public var name: String = ""
    public var sortIndex: Int = 0

    public init(name: String, sortIndex: Int) {
        self.id = UUID()
        self.name = name
        self.sortIndex = sortIndex
    }
}
