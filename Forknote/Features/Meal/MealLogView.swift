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
    @State private var editingID: UUID?
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
            VStack(spacing: 0) {
                if let last = meals.first {
                    Button {
                        repeatMeal(last)
                    } label: {
                        Label("Repeat last meal", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .accessibilityHint("Logs the same foods again, with the time set to now.")
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        MealEditorForm(
                            draft: $draft,
                            recents: recents,
                            saveTitle: "Save meal",
                            foodFocused: $foodFocused,
                            onSave: saveNewMeal
                        )
                        todaySection
                    }
                    .padding(20)
                    .readableColumn()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Add a meal")
            .navigationBarTitleDisplayMode(.large)
            .forknoteSettings()
            .safeAreaInset(edge: .bottom) {
                if undoID != nil {
                    undoBar
                }
            }
        }
        .sensoryFeedback(.success, trigger: saveCount)
        .task(id: undoID) {
            guard undoID != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            undoID = nil
        }
        .onAppear { foodFocused = true }
        .onChange(of: router.focusMealField) { _, shouldFocus in
            guard shouldFocus else { return }
            foodFocused = true
            router.focusMealField = false
        }
        .sheet(isPresented: editingPresented) {
            if let editingID, let meal = meals.first(where: { $0.id == editingID }) {
                MealEditCover(meal: meal)
            }
        }
    }

    private var editingPresented: Binding<Bool> {
        Binding(
            get: { editingID != nil },
            set: { if !$0 { editingID = nil } }
        )
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today")
                    .font(.title3.weight(.semibold))
                Spacer()
                NavigationLink("Full log") {
                    LogListView()
                }
                .font(.subheadline)
            }

            if todayMeals.isEmpty && todaySymptoms.isEmpty {
                Text("Nothing logged today yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(todaySymptoms) { event in
                    symptomRow(event)
                }
                ForEach(todayMeals) { meal in
                    mealRow(meal)
                }
            }
        }
        .padding(.top, 8)
    }

    private func mealRow(_ meal: Meal) -> some View {
        HStack(alignment: .top) {
            Button {
                editingID = meal.id
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.eatenAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(meal.foods.joined(separator: ", "))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    if !meal.note.isEmpty {
                        Text(meal.note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            Button(role: .destructive) {
                modelContext.delete(meal)
                try? modelContext.save()
            } label: {
                Image(systemName: "trash")
            }
            .accessibilityLabel("Delete meal")
        }
    }

    private func symptomRow(_ event: SymptomEvent) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.occurredAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(event.name) · \(event.severity)")
            }
            Spacer(minLength: 8)
            Button(role: .destructive) {
                modelContext.delete(event)
                try? modelContext.save()
            } label: {
                Image(systemName: "trash")
            }
            .accessibilityLabel("Delete symptom")
        }
    }

    private var undoBar: some View {
        HStack {
            Text("Repeated your last meal.")
            Spacer()
            Button("Undo") { undoRepeat() }
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: .rect(cornerRadius: 14))
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
        draft = MealDraft()
        saveCount += 1
        foodFocused = true
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
        draft.foods.append(name)
    }

    private func repeatMeal(_ meal: Meal) {
        let copy = Meal(eatenAt: .now, foods: meal.foods, note: "")
        modelContext.insert(copy)
        try? modelContext.save()
        undoID = copy.id
        saveCount += 1
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

struct MealEditorForm: View {
    @Binding var draft: MealDraft
    let recents: [String]
    let saveTitle: String
    var foodFocused: FocusState<Bool>.Binding
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DatePicker("Time", selection: $draft.eatenAt)
                .datePickerStyle(.compact)

            if !draft.foods.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(draft.foods, id: \.self) { food in
                        HStack(spacing: 6) {
                            Text(food)
                            Button {
                                draft.foods.removeAll { $0 == food }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.weight(.bold))
                            }
                            .accessibilityLabel("Remove \(food)")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.quaternary.opacity(0.45), in: .capsule)
                    }
                }
            }

            TextField("Food name", text: $draft.foodField)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused(foodFocused)
                .onSubmit(commitField)
                .padding(14)
                .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 12))

            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 8) {
                        ForEach(recents, id: \.self) { name in
                            Button(name) { append(name) }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }
                }
            }

            TextField("Note, optional", text: $draft.note, axis: .vertical)
                .lineLimit(1...3)
                .textInputAutocapitalization(.sentences)

            Button(saveTitle, action: onSave)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(draft.foods.isEmpty && NameKey.uniqueDisplayNames(in: draft.foodField).isEmpty)
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
        draft.foods.append(NameKey.displayForm(name) ?? name)
    }
}

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
                MealEditorForm(
                    draft: $draft,
                    recents: recents,
                    saveTitle: "Save changes",
                    foodFocused: $foodFocused,
                    onSave: save
                )
                .padding(20)
                .readableColumn()
            }
            .navigationTitle("Edit meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        for name in NameKey.uniqueDisplayNames(in: draft.foodField) {
            if let key = NameKey.normalize(name), !draft.foods.contains(where: { NameKey.normalize($0) == key }) {
                draft.foods.append(name)
            }
        }
        guard !draft.foods.isEmpty else { return }
        meal.eatenAt = draft.eatenAt
        meal.foods = draft.foods
        meal.note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        try? modelContext.save()
        dismiss()
    }
}
