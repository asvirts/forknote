import ForknoteCore
import ForknoteStore
import SwiftData
import SwiftUI

struct SymptomLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Query(sort: \SymptomLabel.sortIndex) private var labels: [SymptomLabel]
    @Query(sort: \SymptomEvent.occurredAt, order: .reverse) private var symptoms: [SymptomEvent]

    @State private var selectedName: String?
    @State private var occurredAt = Date.now
    @State private var confirmation: String?
    @State private var saveCount = 0

    private var calendar: Calendar { .current }

    private var names: [String] {
        let stored = labels.map(\.name).filter { !$0.isEmpty }
        return stored.isEmpty ? SymptomDefaults.names : stored
    }

    private var todaySymptoms: [SymptomEvent] {
        symptoms.filter { calendar.isDateInToday($0.occurredAt) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    symptomCaptureCard

                    todaySymptomsCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .readableColumn()
            }
            .background(Color.surfaceBackground)
            .navigationTitle("Log a symptom")
            .navigationBarTitleDisplayMode(.inline)
            .forknoteSettings()
        }
        .sensoryFeedback(.success, trigger: saveCount)
        .onAppear {
            if let name = router.selectedSymptom {
                selectedName = name
            }
        }
        .onChange(of: router.selectedSymptom) { _, name in
            if let name {
                selectedName = name
            }
        }
    }

    // MARK: - Symptom Capture Card

    private var symptomCaptureCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Select Symptom", systemImage: "circle.lefthalf.filled")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $occurredAt)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }

            Text("Tap a symptom, then pick a strength (1–5).")
                .font(.footnote)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 10) {
                ForEach(names, id: \.self) { name in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            if selectedName == name {
                                selectedName = nil
                            } else {
                                selectedName = name
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(selectedName == name ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Text(name)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            selectedName == name
                                ? Color.accentColor.opacity(0.15)
                                : Color(uiColor: .tertiarySystemFill),
                            in: .capsule
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    selectedName == name ? Color.accentColor : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if let selectedName {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.vertical, 4)

                    HStack {
                        Text("How strong is \(selectedName)?")
                            .font(.headline)
                        Spacer()
                        Button("Cancel") {
                            withAnimation { self.selectedName = nil }
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        ForEach(SymptomSeverity.allCases, id: \.self) { level in
                            Button {
                                log(name: selectedName, severity: level.rawValue)
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(level.rawValue)")
                                        .font(.title3.weight(.bold))
                                    Text(level.title)
                                        .font(.system(size: 9, weight: .semibold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .foregroundStyle(level.color)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(level.color.opacity(0.12), in: .rect(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(level.color.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(level.title), strength \(level.rawValue) of 5")
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let confirmation {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text(confirmation)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .forknoteCardStyle()
    }

    // MARK: - Today's Symptoms Card

    private var todaySymptomsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Symptoms")
                    .font(.title3.weight(.bold))
                Spacer()
                Text("\(todaySymptoms.count) logged")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if todaySymptoms.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No symptoms logged today.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .forknoteCardStyle()
            } else {
                VStack(spacing: 8) {
                    ForEach(todaySymptoms) { event in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.12))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.orange)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.name)
                                    .font(.body.weight(.medium))
                                Text(event.occurredAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            SeverityBadge(severity: event.severity)

                            Button(role: .destructive) {
                                withAnimation {
                                    modelContext.delete(event)
                                    try? modelContext.save()
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 8)
                            .accessibilityLabel("Delete symptom")
                        }
                        .padding(12)
                        .background(Color.cardBackground, in: .rect(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private func log(name: String, severity: Int) {
        let event = SymptomEvent(name: name, severity: severity, occurredAt: occurredAt)
        modelContext.insert(event)
        try? modelContext.save()
        withAnimation {
            confirmation = "Logged \(name) · \(SymptomSeverity(rawValue: severity)?.title ?? "")"
            selectedName = nil
            occurredAt = .now
            saveCount += 1
        }
    }
}
