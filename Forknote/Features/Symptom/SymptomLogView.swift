import ForknoteCore
import ForknoteStore
import SwiftData
import SwiftUI

struct SymptomLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomLabel.sortIndex) private var labels: [SymptomLabel]

    @State private var selectedName: String?
    @State private var occurredAt = Date.now
    @State private var confirmation: String?
    @State private var saveCount = 0

    private var names: [String] {
        let stored = labels.map(\.name).filter { !$0.isEmpty }
        return stored.isEmpty ? SymptomDefaults.names : stored
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Name, then how strong. The time is now unless you change it.")
                        .foregroundStyle(.secondary)

                    DatePicker("Time", selection: $occurredAt)
                        .datePickerStyle(.compact)

                    FlowLayout(spacing: 10) {
                        ForEach(names, id: \.self) { name in
                            Button(name) { selectedName = name }
                                .buttonStyle(.bordered)
                                .tint(selectedName == name ? Color.accentColor : nil)
                        }
                    }

                    if let selectedName {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("How strong is \(selectedName)?")
                                .font(.headline)
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { level in
                                    Button("\(level)") { log(name: selectedName, severity: level) }
                                        .buttonStyle(.borderedProminent)
                                        .frame(maxWidth: .infinity)
                                        .accessibilityLabel("Strength \(level) of 5")
                                }
                            }
                        }
                    }

                    if let confirmation {
                        Text(confirmation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
                .readableColumn()
            }
            .navigationTitle("Log a symptom")
            .navigationBarTitleDisplayMode(.large)
            .forknoteSettings()
        }
        .sensoryFeedback(.success, trigger: saveCount)
    }

    private func log(name: String, severity: Int) {
        let event = SymptomEvent(name: name, severity: severity, occurredAt: occurredAt)
        modelContext.insert(event)
        try? modelContext.save()
        confirmation = "Logged \(name), strength \(severity)."
        selectedName = nil
        occurredAt = .now
        saveCount += 1
    }
}
