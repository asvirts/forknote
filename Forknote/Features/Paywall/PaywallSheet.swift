import ForknoteCore
import ForknoteStore
import SwiftUI

struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementManager.self) private var entitlements
    @State private var statusBanner: String?
    @State private var legal: LegalDocumentKind?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Forknote Pro")
                            .font(.largeTitle.weight(.semibold))
                        Text("Pay once. Meals and symptoms stay free.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        feature("text.quote", "Full history", "Pattern sentences across your whole log, not only the last 7 days.")
                        feature("list.bullet", "Your symptom list", "Add the words you actually use.")
                        feature("doc.text", "Plain PDF", "Meals, symptoms, and those sentences, to share at a visit.")
                        feature("lock.rectangle.stack", "Lock Screen", "A control that opens straight to a meal.")
                    }
                    .padding(18)
                    .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 18))

                    if let message = entitlements.lastError ?? statusBanner {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task {
                            let outcome = await entitlements.purchase()
                            if outcome == .purchased {
                                dismiss()
                            } else if outcome == .pending {
                                statusBanner = "Purchase is pending approval."
                            }
                        }
                    } label: {
                        Group {
                            if entitlements.isBusy {
                                ProgressView()
                            } else {
                                Text("Unlock Forknote Pro — \(entitlements.displayPrice)")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(entitlements.isBusy)

                    Button("Restore Purchases") {
                        Task {
                            let restored = await entitlements.restore()
                            if restored {
                                dismiss()
                            } else if entitlements.lastError == nil {
                                statusBanner = "No previous Forknote Pro purchase found for this Apple Account."
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(entitlements.isBusy)

                    Text("One-time purchase for iPhone and iPad. Family Sharing included. No subscription and no ads.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(PatternCopy.disclaimer)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Button("Privacy Policy") { legal = .privacy }
                        Button("Terms of Use") { legal = .terms }
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                }
                .padding(24)
                .readableColumn()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
        }
        .task { await entitlements.loadProductIfNeeded() }
        .sheet(item: $legal) { kind in
            LegalSheet(kind: kind)
        }
    }

    private func feature(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 24)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
