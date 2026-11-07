import ForknoteCore
import ForknoteStore
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementManager.self) private var entitlements
    @Query(sort: \SymptomLabel.sortIndex) private var labels: [SymptomLabel]
    @Query(sort: \Meal.eatenAt) private var meals: [Meal]
    @Query(sort: \SymptomEvent.occurredAt) private var symptoms: [SymptomEvent]

    @State private var showPaywall = false
    @State private var newName = ""
    @State private var renameTarget: SymptomLabel?
    @State private var renameText = ""
    @State private var statusBanner: String?
    @State private var exportFile: ExportFile?
    @State private var exportError: String?
    @State private var legal: LegalDocumentKind?
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                symptomSection
                exportSection
                legalSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallSheet() }
            .sheet(item: $exportFile) { file in
                ActivitySheet(url: file.url)
                    .ignoresSafeArea()
            }
            .alert("Rename symptom", isPresented: renamePresented) {
                TextField("Name", text: $renameText)
                Button("Save") { commitRename() }
                Button("Cancel", role: .cancel) { renameTarget = nil }
            }
            .alert("Export", isPresented: exportErrorPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
            .sheet(item: $legal) { kind in
                LegalSheet(kind: kind)
            }
            .alert("Delete all local data?", isPresented: $confirmDelete) {
                Button("Delete All Local Data", role: .destructive, action: deleteAll)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Meals, symptoms, and custom names on this device will be removed.")
            }
        }
    }

    private var renamePresented: Binding<Bool> {
        Binding(get: { renameTarget != nil }, set: { if !$0 { renameTarget = nil } })
    }

    private var exportErrorPresented: Binding<Bool> {
        Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })
    }

    private var proSection: some View {
        Section {
            if entitlements.isPro {
                Text("You have Forknote Pro.")
            } else {
                Button("Unlock Forknote Pro — \(entitlements.displayPrice)") {
                    showPaywall = true
                }
            }
            Button("Restore Purchases") {
                Task {
                    let restored = await entitlements.restore()
                    if !restored, entitlements.lastError == nil {
                        statusBanner = "No previous Forknote Pro purchase found for this Apple Account."
                    } else {
                        statusBanner = entitlements.lastError
                    }
                }
            }
            .disabled(entitlements.isBusy)
            if let statusBanner {
                Text(statusBanner)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Forknote Pro")
        } footer: {
            Text("One-time purchase. Family Sharing included.")
        }
    }

    private var symptomSection: some View {
        Section {
            if labels.isEmpty {
                Text("Your starter list appears the first time you open the app.")
                    .foregroundStyle(.secondary)
            } else if entitlements.isPro {
                ForEach(labels) { label in
                    Button(label.name) {
                        renameTarget = label
                        renameText = label.name
                    }
                    .foregroundStyle(.primary)
                }
                .onDelete(perform: deleteLabels)
            } else {
                ForEach(labels) { label in
                    Text(label.name)
                }
            }

            if entitlements.isPro {
                HStack {
                    TextField("Add a symptom", text: $newName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .onSubmit(addLabel)
                    Button("Add", action: addLabel)
                        .disabled(NameKey.displayForm(newName) == nil)
                }
            } else {
                Button(PatternCopy.proSymptoms) { showPaywall = true }
            }
        } header: {
            Text("Symptoms")
        } footer: {
            Text(entitlements.isPro ? "Keep at least one. Renaming updates earlier logs of that name." : PatternCopy.proSymptoms)
        }
    }

    private var exportSection: some View {
        Section {
            if entitlements.isPro {
                Button("Export PDF") { exportPDF() }
            } else {
                Button(PatternCopy.proPDF) { showPaywall = true }
            }
        } header: {
            Text("PDF")
        } footer: {
            Text("A plain page of meals, symptoms, and sentences.")
        }
    }

    private var legalSection: some View {
        Section {
            Button("Privacy Policy") { legal = .privacy }
            Button("Terms of Use") { legal = .terms }
            Link("Support", destination: ForknoteConfig.supportURL)
            Link("Email Support", destination: ForknoteConfig.supportMailtoURL)
            Button("Delete All Local Data", role: .destructive) {
                confirmDelete = true
            }
        } header: {
            Text("Legal")
        }
    }

    private var aboutSection: some View {
        Section {
            Text(PatternCopy.disclaimer)
            Text("Meals and symptoms stay on this device. Forknote does not collect data.")
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("Version \(version)")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About")
        }
    }

    private func addLabel() {
        guard let display = NameKey.displayForm(newName), let key = NameKey.normalize(display) else { return }
        guard !labels.contains(where: { NameKey.normalize($0.name) == key }) else {
            statusBanner = "You already have that one."
            return
        }
        let next = (labels.map(\.sortIndex).max() ?? -1) + 1
        modelContext.insert(SymptomLabel(name: display, sortIndex: next))
        try? modelContext.save()
        newName = ""
    }

    private func deleteLabels(at offsets: IndexSet) {
        guard labels.count - offsets.count >= 1 else { return }
        for index in offsets {
            modelContext.delete(labels[index])
        }
        try? modelContext.save()
    }

    private func commitRename() {
        guard let renameTarget else { return }
        if !SymptomLibrary.rename(renameTarget, to: renameText, in: modelContext) {
            statusBanner = "You already have that one."
        }
        self.renameTarget = nil
    }

    private func deleteAll() {
        do {
            try PersistenceController.eraseLocalLog(modelContext)
            statusBanner = "Local data deleted."
        } catch {
            statusBanner = "The log could not be deleted."
        }
    }

    private func exportPDF() {
        let calendar = Calendar.current
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
