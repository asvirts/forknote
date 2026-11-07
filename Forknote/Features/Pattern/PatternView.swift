import ForknoteCore
import ForknoteStore
import SwiftData
import SwiftUI

struct PatternView: View {
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router
    @Query(sort: \Meal.eatenAt) private var meals: [Meal]
    @Query(sort: \SymptomEvent.occurredAt) private var symptoms: [SymptomEvent]

    @State private var filter: String?

    private var calendar: Calendar { .current }

    private var range: AnalysisRange {
        entitlements.isPro
            ? .fullHistory(ending: .now, calendar: calendar)
            : .lastSevenDays(ending: .now, calendar: calendar)
    }

    private var symptomNames: [String] {
        var seen = Set<String>()
        var names: [String] = []
        for event in symptoms where inRange(event.occurredAt) {
            guard let key = NameKey.normalize(event.name), let display = NameKey.displayForm(event.name) else { continue }
            guard seen.insert(key).inserted else { continue }
            names.append(display)
        }
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var hit: PatternHit? {
        PatternMath.strongest(
            meals: meals.map(LogMapping.meal),
            symptoms: symptoms.map(LogMapping.symptom),
            symptomName: filter,
            range: range,
            calendar: calendar
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(entitlements.isPro ? PatternCopy.spanFullLog : PatternCopy.spanSevenDays)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if symptomNames.count > 1 {
                        Picker("Symptom", selection: $filter) {
                            Text("Strongest").tag(Optional<String>.none)
                            ForEach(symptomNames, id: \.self) { name in
                                Text(name).tag(Optional(name))
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if let hit {
                        Text(hit.sentence)
                            .font(.system(.title2, design: .serif))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityAddTraits(.isHeader)
                        Text(hit.comparison)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(PatternCopy.screenEmpty)
                            .font(.system(.title2, design: .serif))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(PatternCopy.screenEmptyDetail)
                            .foregroundStyle(.secondary)
                    }

                    if !entitlements.isPro {
                        Button {
                            router.showPaywall = true
                        } label: {
                            Text(PatternCopy.proHistory)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(20)
                .readableColumn()
            }
            .navigationTitle("Pattern")
            .navigationBarTitleDisplayMode(.large)
            .forknoteSettings()
        }
    }

    private func inRange(_ date: Date) -> Bool {
        if date >= range.end { return false }
        if let start = range.start, date < start { return false }
        return true
    }
}
