import ForknoteCore
import ForknoteStore
import Foundation
import SwiftData

@MainActor
public enum SampleDataSeeder {
    public static func seedTwoWeeks(in modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date.now

        // Clear existing meals and events
        try? modelContext.delete(model: Meal.self)
        try? modelContext.delete(model: SymptomEvent.self)

        // 14 days of realistic logs:
        // Days 14 to 8 ago: mostly quiet days with occasional foods (Rice, Toast, Eggs, Salmon)
        for dayOffset in (8...14).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let lunch = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: date) ?? date
            let dinner = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: date) ?? date

            modelContext.insert(Meal(eatenAt: lunch, foods: ["Rice", "Salmon"], note: "Home cooked lunch"))
            modelContext.insert(Meal(eatenAt: dinner, foods: ["Toast", "Avocado", "Tea"], note: ""))
        }

        // Days 7, 6, 5, 4, 3, 2, 1 ago:
        // Days 6, 4, 2, 1 have Oats clustered right before Pain/Bloating
        // Days 7, 5, 3 are quiet days
        let flareOffsets = [6, 4, 2, 1]
        let quietOffsets = [7, 5, 3]

        for dayOffset in quietOffsets {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let breakfast = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: date) ?? date
            let lunch = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: date) ?? date
            let dinner = calendar.date(bySettingHour: 19, minute: 30, second: 0, of: date) ?? date

            modelContext.insert(Meal(eatenAt: breakfast, foods: ["Eggs", "Spinach"], note: ""))
            modelContext.insert(Meal(eatenAt: lunch, foods: ["Rice", "Chicken"], note: ""))
            modelContext.insert(Meal(eatenAt: dinner, foods: ["Salad", "Olive oil"], note: "Quiet evening"))
        }

        for dayOffset in flareOffsets {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let morningMeal = calendar.date(bySettingHour: 8, minute: 15, second: 0, of: date) ?? date
            let flareTime = calendar.date(bySettingHour: 9, minute: 45, second: 0, of: date) ?? date
            let afternoonMeal = calendar.date(bySettingHour: 13, minute: 30, second: 0, of: date) ?? date

            // Oats eaten 1.5 hours before symptom
            modelContext.insert(Meal(eatenAt: morningMeal, foods: ["Oats", "Almond milk", "Blueberries"], note: "Breakfast bowl"))
            modelContext.insert(SymptomEvent(name: "Pain", severity: dayOffset > 3 ? 3 : 4, occurredAt: flareTime))
            modelContext.insert(Meal(eatenAt: afternoonMeal, foods: ["Rice", "Broccoli"], note: ""))
        }

        // Today
        let todayBreakfast = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: now) ?? now
        let todaySymptom = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now
        let todayLunch = calendar.date(bySettingHour: 13, minute: 15, second: 0, of: now) ?? now

        modelContext.insert(Meal(eatenAt: todayBreakfast, foods: ["Oats", "Banana"], note: "Quick oatmeal"))
        modelContext.insert(SymptomEvent(name: "Pain", severity: 3, occurredAt: todaySymptom))
        modelContext.insert(Meal(eatenAt: todayLunch, foods: ["Rice", "Chicken breast"], note: "Mild lunch"))

        try? modelContext.save()
    }
}
