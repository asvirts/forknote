import ForknoteCore
import ForknoteStore
import SwiftUI

struct MealDraft: Equatable {
    var eatenAt: Date = .now
    var foods: [String] = []
    var note: String = ""
    var foodField: String = ""

    init(meal: Meal) {
        eatenAt = meal.eatenAt
        foods = meal.foods
        note = meal.note
    }

    init() {}
}

enum LogMapping {
    static func meal(_ meal: Meal) -> MealRecord {
        MealRecord(id: meal.id, eatenAt: meal.eatenAt, foods: meal.foods, note: meal.note)
    }

    static func symptom(_ event: SymptomEvent) -> SymptomRecord {
        SymptomRecord(id: event.id, name: event.name, severity: event.severity, occurredAt: event.occurredAt)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct SettingsToolbar: ViewModifier {
    @State private var showSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        showSettings = true
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
    }
}

extension View {
    func forknoteSettings() -> some View {
        modifier(SettingsToolbar())
    }

    func readableColumn() -> some View {
        frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
    }
}
