import Foundation

public struct ClinicianReport: Sendable, Equatable {
    public var plainText: String

    public init(plainText: String) {
        self.plainText = plainText
    }
}

public enum ReportBuilder {
    public static func make(
        meals: [MealRecord],
        symptoms: [SymptomRecord],
        sentences: [String],
        generatedAt: Date,
        calendar: Calendar
    ) -> ClinicianReport {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"

        var lines: [String] = []
        lines.append("Forknote food and symptom log")
        lines.append("Generated \(formatter.string(from: generatedAt))")
        lines.append(PatternCopy.disclaimer)
        lines.append("")
        lines.append("\(count(meals.count, "meal", "meals")), \(count(symptoms.count, "symptom", "symptoms")).")
        lines.append("")
        lines.append("Meals")
        if meals.isEmpty {
            lines.append("No meals in this log.")
        } else {
            for meal in meals.sorted(by: { $0.eatenAt > $1.eatenAt }) {
                let foods = meal.foods.map { NameKey.displayForm($0) ?? $0 }.joined(separator: ", ")
                lines.append("\(formatter.string(from: meal.eatenAt)) — \(foods)")
                let note = meal.note.trimmingCharacters(in: .whitespacesAndNewlines)
                if !note.isEmpty { lines.append(note) }
            }
        }
        lines.append("")
        lines.append("Symptoms")
        if symptoms.isEmpty {
            lines.append("No symptoms in this log.")
        } else {
            for event in symptoms.sorted(by: { $0.occurredAt > $1.occurredAt }) {
                lines.append(
                    "\(formatter.string(from: event.occurredAt)) — \(event.name), strength \(event.strength) of 5"
                )
            }
        }
        lines.append("")
        lines.append("Sentences")
        if sentences.isEmpty {
            lines.append(PatternCopy.reportEmpty)
        } else {
            lines.append(contentsOf: sentences)
        }
        return ClinicianReport(plainText: lines.joined(separator: "\n"))
    }

    private static func count(_ value: Int, _ singular: String, _ plural: String) -> String {
        "\(value) \(value == 1 ? singular : plural)"
    }
}
