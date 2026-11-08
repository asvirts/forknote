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

    private var allHits: [PatternHit] {
        PatternMath.rankedHits(
            meals: meals.map(LogMapping.meal),
            symptoms: symptoms.map(LogMapping.symptom),
            symptomName: filter,
            range: range,
            calendar: calendar
        )
    }

    private var topHit: PatternHit? {
        allHits.first
    }

    // MARK: - Progress Stats

    private var rangeMeals: [Meal] {
        meals.filter { inRange($0.eatenAt) }
    }

    private var rangeSymptoms: [SymptomEvent] {
        symptoms.filter { inRange($0.occurredAt) }
    }

    private var mealDaysCount: Int {
        Set(rangeMeals.map { calendar.startOfDay(for: $0.eatenAt) }).count
    }

    private var symptomDaysCount: Int {
        Set(rangeSymptoms.map { calendar.startOfDay(for: $0.occurredAt) }).count
    }

    private var quietDaysCount: Int {
        let mealDays = Set(rangeMeals.map { calendar.startOfDay(for: $0.eatenAt) })
        let symptomDays = Set(rangeSymptoms.map { calendar.startOfDay(for: $0.occurredAt) })
        return mealDays.subtracting(symptomDays).count
    }

    private var topFoodFrequency: (food: String, count: Int)? {
        var counts: [String: (display: String, count: Int)] = [:]
        for meal in rangeMeals {
            for food in meal.foods {
                guard let key = NameKey.normalize(food), let display = NameKey.displayForm(food) else { continue }
                counts[key, default: (display, 0)].count += 1
            }
        }
        guard let best = counts.values.max(by: { $0.count < $1.count }) else { return nil }
        return (best.display, best.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    timeRangeHeader

                    if symptomNames.count > 1 {
                        symptomFilterBar
                    }

                    if let hit = topHit {
                        patternHeroCard(hit)

                        if allHits.count > 1 {
                            additionalHitsSection(Array(allHits.dropFirst()))
                        }
                    } else {
                        discoveryProgressCard
                        howItWorksCard
                    }

                    if !entitlements.isPro {
                        proUpgradeBanner
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .readableColumn()
            }
            .background(Color.surfaceBackground)
            .navigationTitle("Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .forknoteSettings()
        }
    }

    // MARK: - Header

    private var timeRangeHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                Text(entitlements.isPro ? "Full History Patterns" : "Last 7 Days Patterns")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !entitlements.isPro {
                Button("Unlock Full History") {
                    router.showPaywall = true
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)
            }
        }
    }

    private var symptomFilterBar: some View {
        Picker("Filter Symptom", selection: $filter) {
            Text("Strongest Pattern").tag(Optional<String>.none)
            ForEach(symptomNames, id: \.self) { name in
                Text(name).tag(Optional(name))
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Hero Card

    private func patternHeroCard(_ hit: PatternHit) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Observed Pattern", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Text(hit.window == .twoHour ? "Within 2 Hours" : "Within 24 Hours")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15), in: .capsule)
                    .foregroundStyle(Color.accentColor)
            }

            Text(hit.sentence)
                .font(.system(.title3, design: .serif).weight(.medium))
                .lineSpacing(4)
                .foregroundStyle(.primary)

            Text(hit.comparison)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 12) {
                metricCell(
                    value: "\(hit.symptomDaysWithFood)/\(hit.symptomDayCount)",
                    label: "Flare Days",
                    icon: "flame"
                )
                metricCell(
                    value: "\(hit.mealCount)",
                    label: "Total Meals",
                    icon: "fork.knife"
                )
                metricCell(
                    value: "\(hit.quietDaysWithFood)/\(hit.quietDayCount)",
                    label: "Quiet Days",
                    icon: "leaf"
                )
            }
        }
        .forknoteCardStyle()
    }

    private func metricCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.weight(.bold))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(uiColor: .tertiarySystemFill), in: .rect(cornerRadius: 10))
    }

    // MARK: - Additional Hits

    private func additionalHitsSection(_ hits: [PatternHit]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Other Candidate Patterns")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)

            ForEach(hits, id: \.sentence) { hit in
                VStack(alignment: .leading, spacing: 6) {
                    Text(hit.sentence)
                        .font(.subheadline.weight(.medium))
                    Text(hit.comparison)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.cardBackground, in: .rect(cornerRadius: 12))
            }
        }
    }

    // MARK: - Discovery Progress Card

    private var discoveryProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Pattern Discovery", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("\(rangeMeals.count) meals · \(rangeSymptoms.count) symptoms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Steady analyzes your meals and symptoms to spot foods that cluster before flares significantly more than on calm days.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                if let topFood = topFoodFrequency {
                    progressRow(
                        title: "Top food exposures (\(topFood.food))",
                        current: min(topFood.count, 5),
                        target: 5,
                        hint: topFood.count >= 5 ? "Ready" : "\(topFood.count) of 5 meals logged"
                    )
                } else {
                    progressRow(
                        title: "Food exposures",
                        current: 0,
                        target: 5,
                        hint: "Log meals with repeat foods"
                    )
                }

                progressRow(
                    title: "Symptom flare days",
                    current: min(symptomDaysCount, 3),
                    target: 3,
                    hint: "\(symptomDaysCount) of 3 days observed"
                )

                progressRow(
                    title: "Quiet days (symptom-free)",
                    current: min(quietDaysCount, 3),
                    target: 3,
                    hint: "\(quietDaysCount) of 3 days observed"
                )
            }
        }
        .forknoteCardStyle()
    }

    private func progressRow(title: String, current: Int, target: Int, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.weight(.medium))
                Spacer()
                Text(hint)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(current >= target ? Color.green : .secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(uiColor: .tertiarySystemFill))
                    Capsule()
                        .fill(current >= target ? Color.green : Color.accentColor)
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(current) / CGFloat(target))))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - How It Works Card

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("How Pattern Math Works", systemImage: "info.circle")
                .font(.subheadline.weight(.bold))

            VStack(alignment: .leading, spacing: 10) {
                ruleRow(number: "1", title: "5+ Exposures Required", desc: "Rare one-offs are never blamed. Steady waits until a food is eaten at least 5 times.")
                ruleRow(number: "2", title: "Quiet Day Contrast", desc: "Everyday staples (eaten on >70% of days) stay quiet, even if eaten on pain days.")
                ruleRow(number: "3", title: "2-Hour & 24-Hour Windows", desc: "Looks specifically at meals leading up to symptoms rather than random correlation.")
                ruleRow(number: "4", title: "Non-Clinical", desc: "Personal log observations only. Never claims causes or medical diagnoses.")
            }
        }
        .forknoteCardStyle()
    }

    private func ruleRow(number: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 20, height: 20)
                .background(Color.accentColor.opacity(0.12), in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(desc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Pro Banner

    private var proUpgradeBanner: some View {
        Button {
            router.showPaywall = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color.accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Full History Patterns")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Analyze your entire log beyond the last 7 days.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .forknoteCardStyle()
        }
        .buttonStyle(.plain)
    }

    private func inRange(_ date: Date) -> Bool {
        if date >= range.end { return false }
        if let start = range.start, date < start { return false }
        return true
    }
}
