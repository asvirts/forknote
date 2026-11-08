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
    @State private var confirmSample = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                symptomSection
                exportSection
                sampleDataSection
                legalSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallSheet() }
            .sheet(item: $exportFile) { file in
                ActivitySheet(url: file.url)
                    .ignoresSafeArea()
            }
            .alert("Rename Symptom", isPresented: renamePresented) {
                TextField("Name", text: $renameText)
                Button("Save") { commitRename() }
                Button("Cancel", role: .cancel) { renameTarget = nil }
            }
            .alert("Export Error", isPresented: exportErrorPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
            .sheet(item: $legal) { kind in
                LegalSheet(kind: kind)
            }
            .alert("Delete All Local Data?", isPresented: $confirmDelete) {
                Button("Delete All Local Data", role: .destructive, action: deleteAll)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Meals, symptoms, and custom names on this device will be removed.")
            }
            .alert("Load 2-Week Sample Data?", isPresented: $confirmSample) {
                Button("Load Sample Data", action: loadSampleData)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This replaces existing logs with 14 days of realistic meals and symptoms to preview pattern analysis and reports.")
            }
        }
    }

    private var renamePresented: Binding<Bool> {
        Binding(get: { renameTarget != nil }, set: { if !$0 { renameTarget = nil } })
    }

    private var exportErrorPresented: Binding<Bool> {
        Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })
    }

    // MARK: - Sections

    private var proSection: some View {
        Section {
            if entitlements.isPro {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Forknote Pro Active")
                            .font(.headline)
                        Text("Full history patterns, custom symptoms, and PDF export unlocked.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.accentColor)
                        Text("Unlock Forknote Pro — \(entitlements.displayPrice)")
                            .font(.headline)
                    }
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
            Label("Membership", systemImage: "crown")
        } footer: {
            Text("One-time purchase for iPhone and iPad. Family Sharing included. No subscription.")
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
                    TextField("Add a custom symptom", text: $newName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .onSubmit(addLabel)
                    Button("Add", action: addLabel)
                        .disabled(NameKey.displayForm(newName) == nil)
                }
            } else {
                Button(PatternCopy.proSymptoms) { showPaywall = true }
                    .foregroundStyle(Color.accentColor)
            }
        } header: {
            Label("Symptoms List", systemImage: "list.bullet")
        } footer: {
            Text(entitlements.isPro ? "Keep at least one. Renaming updates earlier logs of that name." : "Upgrade to Pro to customize symptom names.")
        }
    }

    private var exportSection: some View {
        Section {
            if entitlements.isPro {
                Button {
                    exportPDF()
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Export Clinician PDF")
                    }
                }
            } else {
                Button(PatternCopy.proPDF) { showPaywall = true }
                    .foregroundStyle(Color.accentColor)
            }
        } header: {
            Label("Reports", systemImage: "square.and.arrow.up")
        } footer: {
            Text("Generates a clean, 1-page report of meals, symptoms, and observed patterns to share at a visit.")
        }
    }

    private var sampleDataSection: some View {
        Section {
            Button {
                confirmSample = true
            } label: {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(Color.accentColor)
                    Text("Load 2-Week Sample Data")
                }
            }

            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear All Local Data")
                }
            }
        } header: {
            Label("Demo & Data", systemImage: "tray.2")
        } footer: {
            Text("Sample data populates 14 days of realistic logs to preview how pattern discovery and clinician reports work.")
        }
    }

    private var legalSection: some View {
        Section {
            Button("Privacy Policy") { legal = .privacy }
            Button("Terms of Use") { legal = .terms }
            Link("Online Support", destination: ForknoteConfig.supportURL)
            Link("Email Support", destination: ForknoteConfig.supportMailtoURL)
        } header: {
            Label("Legal & Support", systemImage: "hand.raised")
        }
    }

    private var aboutSection: some View {
        Section {
            Text(PatternCopy.disclaimer)
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Text("Privacy")
                Spacer()
                Text("Data Not Collected")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Storage")
                Spacer()
                Text("100% On-Device")
                    .foregroundStyle(.secondary)
            }
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(version)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("About", systemImage: "info.circle")
        }
    }

    // MARK: - Actions

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

    private func loadSampleData() {
        SampleDataSeeder.seedTwoWeeks(in: modelContext)
        statusBanner = "Loaded 2 weeks of sample meals and symptoms."
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
