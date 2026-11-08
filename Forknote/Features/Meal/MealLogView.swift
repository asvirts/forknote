import ForknoteCore
import ForknoteStore
import SwiftData
import SwiftUI

struct MealLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Query(sort: \Meal.eatenAt, order: .reverse) private var meals: [Meal]
    @Query(sort: \SymptomEvent.occurredAt, order: .reverse) private var symptoms: [SymptomEvent]

    @State private var draft = MealDraft()
    @State private var editingMeal: Meal?
    @State private var undoID: UUID?
    @State private var saveCount = 0
    @FocusState private var foodFocused: Bool

    private var calendar: Calendar { .current }

    private var todayMeals: [Meal] {
        meals.filter { calendar.isDateInToday($0.eatenAt) }
    }

    private var todaySymptoms: [SymptomEvent] {
        symptoms.filter { calendar.isDateInToday($0.occurredAt) }
    }

    private var recents: [String] {
        RecentFoods.names(in: meals.map(LogMapping.meal)).filter { name in
            guard let key = NameKey.normalize(name) else { return false }
            return !draft.foods.contains { NameKey.normalize($0) == key }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let last = meals.first {
                        repeatMealCard(last)
                    }

                    mealEditorCard

                    todaySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .readableColumn()
            }
            .background(Color.surfaceBackground)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add a meal")
            .navigationBarTitleDisplayMode(.inline)
            .forknoteSettings()
            .safeAreaInset(edge: .bottom) {
                if undoID != nil {
                    undoBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sensoryFeedback(.success, trigger: saveCount)
        .task(id: undoID) {
            guard undoID != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                undoID = nil
            }
        }
        .onAppear {
            foodFocused = true
        }
        .onChange(of: router.focusMealField) { _, shouldFocus in
            guard shouldFocus else { return }
            foodFocused = true
            router.focusMealField = false
        }
        .sheet(item: $editingMeal) { meal in
            MealEditCover(meal: meal)
        }
    }

    // MARK: - Repeat Last Meal Card

    private func repeatMealCard(_ meal: Meal) -> some View {
        Button {
            repeatMeal(meal)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.clockwise")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Repeat Last Meal")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(meal.foods.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
            .forknoteCardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Logs the same foods again with the current time.")
    }

    // MARK: - Meal Editor Card

    private var mealEditorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("New Meal", systemImage: "fork.knife")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $draft.eatenAt)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }

            if !draft.foods.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(draft.foods, id: \.self) { food in
                        FoodChipView(name: food) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                draft.foods.removeAll { $0 == food }
                            }
                        }
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: draft.foods)
            }

            HStack {
                Image(systemName: "text.badge.plus")
                    .foregroundStyle(.secondary)
                TextField("Food name (e.g. Oats, Coffee)...", text: $draft.foodField)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($foodFocused)
                    .onSubmit(commitField)
                if !draft.foodField.isEmpty {
                    Button(action: commitField) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .padding(14)
            .background(Color(uiColor: .tertiarySystemFill), in: .rect(cornerRadius: 12))

            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick add recent:")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 8) {
                        ForEach(recents.prefix(8), id: \.self) { name in
                            Button {
                                append(name)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.caption2.weight(.bold))
                                    Text(name)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(uiColor: .tertiarySystemFill), in: .capsule)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            TextField("Note, optional (e.g. Oat milk latte, breakfast)", text: $draft.note, axis: .vertical)
                .lineLimit(1...3)
                .font(.subheadline)
                .padding(12)
                .background(Color(uiColor: .tertiarySystemFill), in: .rect(cornerRadius: 12))

            Button(action: saveNewMeal) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                    Text("Save Meal")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(draft.foods.isEmpty && NameKey.uniqueDisplayNames(in: draft.foodField).isEmpty)
        }
        .forknoteCardStyle()
    }

    // MARK: - Today Section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Log")
                    .font(.title3.weight(.bold))
                Spacer()
                NavigationLink {
                    LogListView()
                } label: {
                    HStack(spacing: 4) {
                        Text("Full History")
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.medium))
                }
            }

            if todayMeals.isEmpty && todaySymptoms.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("Nothing logged today yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .forknoteCardStyle()
            } else {
                VStack(spacing: 10) {
                    ForEach(todayItems) { item in
                        switch item {
                        case .meal(let meal):
                            mealRow(meal)
                        case .symptom(let event):
                            symptomRow(event)
                        }
                    }
                }
            }
        }
    }

    private enum TodayItem: Identifiable {
        case meal(Meal)
        case symptom(SymptomEvent)

        var id: UUID {
            switch self {
            case .meal(let m): m.id
            case .symptom(let s): s.id
            }
        }

        var timestamp: Date {
            switch self {
            case .meal(let m): m.eatenAt
            case .symptom(let s): s.occurredAt
            }
        }
    }

    private var todayItems: [TodayItem] {
        let m = todayMeals.map { TodayItem.meal($0) }
        let s = todaySymptoms.map { TodayItem.symptom($0) }
        return (m + s).sorted { $0.timestamp > $1.timestamp }
    }

    private func mealRow(_ meal: Meal) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "fork.knife")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.eatenAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        editingMeal = meal
                    } label: {
                        Text("Edit")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.accentColor)
                    }
                }

                Text(meal.foods.joined(separator: ", "))
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                if !meal.note.isEmpty {
                    Text(meal.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: .rect(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.04), lineWidth: 1)
        )
        .contextMenu {
            Button("Edit Meal") {
                editingMeal = meal
            }
            Button("Repeat Meal") {
                repeatMeal(meal)
            }
            Button("Delete", role: .destructive) {
                withAnimation {
                    modelContext.delete(meal)
                    try? modelContext.save()
                }
            }
        }
    }

    private func symptomRow(_ event: SymptomEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "circle.lefthalf.filled")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.occurredAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    SeverityBadge(severity: event.severity, compact: false)
                }

                Text(event.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
            }
        }
        .padding(14)
        .background(Color.cardBackground, in: .rect(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.04), lineWidth: 1)
        )
        .contextMenu {
            Button("Delete", role: .destructive) {
                withAnimation {
                    modelContext.delete(event)
                    try? modelContext.save()
                }
            }
        }
    }

    // MARK: - Actions

    private var undoBar: some View {
        HStack {
            Image(systemName: "arrow.clockwise")
                .foregroundStyle(Color.accentColor)
            Text("Repeated last meal")
                .font(.subheadline.weight(.medium))
            Spacer()
            Button("Undo") {
                withAnimation { undoRepeat() }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func saveNewMeal() {
        commitField()
        let foods = draft.foods
        guard !foods.isEmpty else { return }
        let meal = Meal(
            eatenAt: draft.eatenAt,
            foods: foods,
            note: draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(meal)
        try? modelContext.save()
        withAnimation {
            draft = MealDraft()
            saveCount += 1
            foodFocused = true
        }
    }

    private func commitField() {
        for name in NameKey.uniqueDisplayNames(in: draft.foodField) {
            append(name)
        }
        draft.foodField = ""
    }

    private func append(_ name: String) {
        guard let key = NameKey.normalize(name) else { return }
        guard !draft.foods.contains(where: { NameKey.normalize($0) == key }) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            draft.foods.append(NameKey.displayForm(name) ?? name)
        }
    }

    private func repeatMeal(_ meal: Meal) {
        let copy = Meal(eatenAt: .now, foods: meal.foods, note: meal.note)
        modelContext.insert(copy)
        try? modelContext.save()
        withAnimation {
            undoID = copy.id
            saveCount += 1
        }
    }

    private func undoRepeat() {
        guard let undoID, let meal = meals.first(where: { $0.id == undoID }) else {
            self.undoID = nil
            return
        }
        modelContext.delete(meal)
        try? modelContext.save()
        self.undoID = nil
    }
}

// MARK: - Meal Edit Cover

struct MealEditCover: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.eatenAt, order: .reverse) private var meals: [Meal]

    let meal: Meal
    @State private var draft: MealDraft
    @FocusState private var foodFocused: Bool

    init(meal: Meal) {
        self.meal = meal
        _draft = State(initialValue: MealDraft(meal: meal))
    }

    private var recents: [String] {
        RecentFoods.names(in: meals.map(LogMapping.meal)).filter { name in
            guard let key = NameKey.normalize(name) else { return false }
            return !draft.foods.contains { NameKey.normalize($0) == key }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DatePicker("Time", selection: $draft.eatenAt)
                        .datePickerStyle(.compact)

                    if !draft.foods.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(draft.foods, id: \.self) { food in
                                FoodChipView(name: food) {
                                    draft.foods.removeAll { $0 == food }
                                }
                            }
                        }
                    }

                    TextField("Add food name...", text: $draft.foodField)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(commitField)
                        .padding(14)
                        .background(Color(uiColor: .tertiarySystemFill), in: .rect(cornerRadius: 12))

                    if !recents.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recent")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            FlowLayout(spacing: 8) {
                                ForEach(recents.prefix(6), id: \.self) { name in
                                    Button(name) {
                                        if let key = NameKey.normalize(name), !draft.foods.contains(where: { NameKey.normalize($0) == key }) {
                                            draft.foods.append(name)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }

                    TextField("Note, optional", text: $draft.note, axis: .vertical)
                        .lineLimit(1...3)
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemFill), in: .rect(cornerRadius: 12))
                }
                .padding(20)
                .readableColumn()
            }
            .navigationTitle("Edit meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    private func commitField() {
        for name in NameKey.uniqueDisplayNames(in: draft.foodField) {
            if let key = NameKey.normalize(name), !draft.foods.contains(where: { NameKey.normalize($0) == key }) {
                draft.foods.append(name)
            }
        }
        draft.foodField = ""
    }

    private func save() {
        commitField()
        guard !draft.foods.isEmpty else { return }
        meal.eatenAt = draft.eatenAt
        meal.foods = draft.foods
        meal.note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        try? modelContext.save()
        dismiss()
    }
}
