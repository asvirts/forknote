import Foundation
import SwiftData
import ForknoteCore

public enum PersistenceController {
    public static let schema = Schema([Meal.self, SymptomEvent.self, SymptomLabel.self])

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    /// Removes meals, symptom events, and symptom names, then restores the starter list.
    @MainActor
    public static func eraseLocalLog(_ context: ModelContext) throws {
        try context.delete(model: Meal.self)
        try context.delete(model: SymptomEvent.self)
        try context.delete(model: SymptomLabel.self)
        try context.save()
        SymptomLibrary.seedIfNeeded(context)
    }
}

@MainActor
public enum SymptomLibrary {
    public static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<SymptomLabel>())) ?? []
        guard existing.isEmpty else { return }
        for (index, name) in SymptomDefaults.names.enumerated() {
            context.insert(SymptomLabel(name: name, sortIndex: index))
        }
        try? context.save()
    }

    public static func rename(_ label: SymptomLabel, to rawName: String, in context: ModelContext) -> Bool {
        guard let display = NameKey.displayForm(rawName), let newKey = NameKey.normalize(display) else { return false }
        let labels = (try? context.fetch(FetchDescriptor<SymptomLabel>())) ?? []
        let taken = labels.contains { $0.id != label.id && NameKey.normalize($0.name) == newKey }
        guard !taken else { return false }
        let oldKey = NameKey.normalize(label.name)
        label.name = display
        if let oldKey, oldKey != newKey {
            let events = (try? context.fetch(FetchDescriptor<SymptomEvent>())) ?? []
            for event in events where NameKey.normalize(event.name) == oldKey {
                event.name = display
            }
        }
        try? context.save()
        return true
    }
}
