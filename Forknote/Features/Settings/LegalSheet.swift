import ForknoteCore
import SwiftUI

enum LegalDocumentKind: String, Identifiable {
    case privacy
    case terms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: "Privacy Policy"
        case .terms: "Terms of Use"
        }
    }

    var webURL: URL {
        switch self {
        case .privacy: ForknoteConfig.privacyPolicyURL
        case .terms: ForknoteConfig.termsURL
        }
    }
}

struct LegalSheet: View {
    let kind: LegalDocumentKind
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch kind {
                    case .privacy:
                        privacy
                    case .terms:
                        terms
                    }
                    Link(destination: kind.webURL) {
                        Label("Open in Browser", systemImage: "safari")
                    }
                    .font(.subheadline.weight(.medium))
                }
                .padding(22)
                .readableColumn()
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var privacy: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Effective November 7, 2026")
                .font(.caption)
                .foregroundStyle(.secondary)
            block(
                "Data not collected",
                "Forknote does not collect, transmit, or sell your meals, symptoms, or usage. There is no account and no analytics or advertising SDK."
            )
            block(
                "On this device",
                "Your log stays in the app’s private store on this iPhone or iPad. Forknote Pro is processed by Apple. A PDF is built on the device and shared only if you choose a destination."
            )
            block(
                "Delete",
                "Settings → Delete All Local Data removes meals, symptoms, and custom names from this device."
            )
        }
    }

    private var terms: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Effective November 7, 2026 · Apple Standard EULA")
                .font(.caption)
                .foregroundStyle(.secondary)
            block(
                "Personal log",
                "Forknote is a personal log. It is not a medical device. The sentence describes what shows up in what you logged. It does not tell you what is wrong or what to change."
            )
            block(
                "Forknote Pro",
                "Forknote Pro is a one-time purchase with Family Sharing. Apple handles the payment and any refund."
            )
            block(
                "No server copy",
                "The log lives on your device. Export a PDF if you want a copy you can keep."
            )
        }
    }

    private func block(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(body).font(.footnote).foregroundStyle(.secondary)
        }
    }
}
