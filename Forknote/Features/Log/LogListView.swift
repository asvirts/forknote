import ForknoteStore
import SwiftData
import SwiftUI

struct LogListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.eatenAt, order: .reverse) private var meals: [Meal]
    @Query(sort: \SymptomEvent.occurredAt, order: .reverse) private var symptoms: [SymptomEvent]
    @State private var editingMeal: Meal?

    private var calendar: Calendar { .current }

    private var days: [Date] {
        let mealDays = meals.map { calendar.startOfDay(for: $0.eatenAt) }
        let symptomDays = symptoms.map { calendar.startOfDay(for: $0.occurredAt) }
        return Array(Set(mealDays + symptomDays)).sorted(by: >)
    }

    var body: some View {
        List {
            if days.isEmpty {
                Text("Nothing logged yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(days, id: \.self) { day in
                    Section(day.formatted(date: .abbreviated, time: .omitted)) {
                        ForEach(symptoms.filter { calendar.isDate($0.occurredAt, inSameDayAs: day) }) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.occurredAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(event.name) · \(event.severity)")
                            }
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    modelContext.delete(event)
                                    try? modelContext.save()
                                }
                            }
                        }
                        ForEach(meals.filter { calendar.isDate($0.eatenAt, inSameDayAs: day) }) { meal in
                            Button {
                                editingMeal = meal
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(meal.eatenAt.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(meal.foods.joined(separator: ", "))
                                        .foregroundStyle(.primary)
                                    if !meal.note.isEmpty {
                                        Text(meal.note)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    modelContext.delete(meal)
                                    try? modelContext.save()
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Full log")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingMeal) { meal in
            MealEditCover(meal: meal)
        }
    }
}
