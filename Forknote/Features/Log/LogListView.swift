import ForknoteCore
import ForknoteStore
import SwiftData
import SwiftUI

struct LogListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementManager.self) private var entitlements
    @Query(sort: \Meal.eatenAt, order: .reverse) private var meals: [Meal]
    @Query(sort: \SymptomEvent.occurredAt, order: .reverse) private var symptoms: [SymptomEvent]

    @State private var filter: LogFilter = .all
    @State private var searchText: String = ""
    @State private var editingMeal: Meal?
    @State private var exportFile: ExportFile?
    @State private var exportError: String?
    @State private var showPaywall = false

    private var calendar: Calendar { .current }

    private enum LogFilter: String, CaseIterable {
        case all = "All"
        case meals = "Meals"
        case symptoms = "Symptoms"
    }

    private var filteredMeals: [Meal] {
        guard filter != .symptoms else { return [] }
        guard !searchText.isEmpty else { return meals }
        let query = searchText.lowercased()
        return meals.filter { meal in
            meal.foods.contains { $0.lowercased().contains(query) } ||
            meal.note.lowercased().contains(query)
        }
    }

    private var filteredSymptoms: [SymptomEvent] {
        guard filter != .meals else { return [] }
        guard !searchText.isEmpty else { return symptoms }
        let query = searchText.lowercased()
        return symptoms.filter { event in
            event.name.lowercased().contains(query)
        }
    }

    private var days: [Date] {
        let mealDays = filteredMeals.map { calendar.startOfDay(for: $0.eatenAt) }
        let symptomDays = filteredSymptoms.map { calendar.startOfDay(for: $0.occurredAt) }
        return Array(Set(mealDays + symptomDays)).sorted(by: >)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryHeaderCard

                filterPicker

                if days.isEmpty {
                    emptyStateCard
                } else {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(days, id: \.self) { day in
                            daySection(day)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .readableColumn()
        }
        .background(Color.surfaceBackground)
        .searchable(text: $searchText, prompt: "Search foods or symptoms...")
        .navigationTitle("Full Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if entitlements.isPro {
                        exportPDF()
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label("Export PDF", systemImage: "doc.text")
                }
            }
        }
        .sheet(item: $editingMeal) { meal in
            MealEditCover(meal: meal)
        }
        .sheet(item: $exportFile) { file in
            ActivitySheet(url: file.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
        }
        .alert("Export Error", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    // MARK: - Summary Header Card

    private var summaryHeaderCard: some View {
        HStack(spacing: 12) {
            statBlock(count: "\(meals.count)", label: "Meals Logged", icon: "fork.knife")
            statBlock(count: "\(symptoms.count)", label: "Symptoms Logged", icon: "circle.lefthalf.filled")
            statBlock(count: "\(days.count)", label: "Days Recorded", icon: "calendar")
        }
    }

    private func statBlock(count: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
                Text(count)
                    .font(.title3.weight(.bold))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.cardBackground, in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Filter Picker

    private var filterPicker: some View {
        Picker("Filter", selection: $filter) {
            ForEach(LogFilter.allCases, id: \.self) { kind in
                Text(kind.rawValue).tag(kind)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Day Section

    private func daySection(_ day: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formattedDayHeader(day))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                let daySymptoms = filteredSymptoms.filter { calendar.isDate($0.occurredAt, inSameDayAs: day) }
                let dayMeals = filteredMeals.filter { calendar.isDate($0.eatenAt, inSameDayAs: day) }

                ForEach(daySymptoms) { event in
                    symptomCard(event)
                }

                ForEach(dayMeals) { meal in
                    mealCard(meal)
                }
            }
        }
    }

    private func mealCard(_ meal: Meal) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: "fork.knife")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.eatenAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Edit") {
                        editingMeal = meal
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                }

                Text(meal.foods.joined(separator: ", "))
                    .font(.body.weight(.medium))

                if !meal.note.isEmpty {
                    Text(meal.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: .rect(cornerRadius: 14))
        .contextMenu {
            Button("Edit Meal") {
                editingMeal = meal
            }
            Button("Delete", role: .destructive) {
                withAnimation {
                    modelContext.delete(meal)
                    try? modelContext.save()
                }
            }
        }
    }

    private func symptomCard(_ event: SymptomEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: "circle.lefthalf.filled")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.occurredAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    SeverityBadge(severity: event.severity)
                }

                Text(event.name)
                    .font(.body.weight(.medium))
            }
        }
        .padding(12)
        .background(Color.cardBackground, in: .rect(cornerRadius: 14))
        .contextMenu {
            Button("Delete", role: .destructive) {
                withAnimation {
                    modelContext.delete(event)
                    try? modelContext.save()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text(searchText.isEmpty ? "Nothing logged yet." : "No matches found.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .forknoteCardStyle()
    }

    private func formattedDayHeader(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today · " + date.formatted(date: .abbreviated, time: .omitted)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday · " + date.formatted(date: .abbreviated, time: .omitted)
        } else {
            return date.formatted(date: .complete, time: .omitted)
        }
    }

    private func exportPDF() {
        let range = AnalysisRange.fullHistory(ending: .now, calendar: calendar)
        let mealRecords = meals.map(LogMapping.meal)
        let symptomRecords = symptoms.map(LogMapping.symptom)
        let sentences = PatternMath.rankedHits(
            meals: mealRecords,
            symptoms: symptomRecords,
            range: range,
            calendar: calendar
        ).map(\.sentence)
        let report = ReportBuilder.make(
            meals: mealRecords,
            symptoms: symptomRecords,
            sentences: sentences,
            generatedAt: .now,
            calendar: calendar
        )
        do {
            exportFile = ExportFile(url: try PDFExporter.write(report))
        } catch {
            exportError = "The PDF could not be created."
        }
    }
}
