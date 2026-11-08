import ForknoteCore
import SwiftUI

// MARK: - Severity

public enum SymptomSeverity: Int, CaseIterable, Sendable {
    case mild = 1
    case mildModerate = 2
    case moderate = 3
    case strong = 4
    case severe = 5

    public var title: String {
        switch self {
        case .mild: "Mild"
        case .mildModerate: "Mild-moderate"
        case .moderate: "Moderate"
        case .strong: "Strong"
        case .severe: "Severe"
        }
    }

    public var color: Color {
        switch self {
        case .mild: Color.green
        case .mildModerate: Color.teal
        case .moderate: Color.orange
        case .strong: Color.deepOrange
        case .severe: Color.red
        }
    }
}

extension Color {
    static let deepOrange = Color(red: 0.95, green: 0.40, blue: 0.15)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let surfaceBackground = Color(uiColor: .systemGroupedBackground)
}

// MARK: - Severity Badge

struct SeverityBadge: View {
    let severity: Int
    var compact: Bool = false

    private var level: SymptomSeverity {
        SymptomSeverity(rawValue: severity) ?? .moderate
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(level.color)
                .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)
            if !compact {
                Text("\(severity) · \(level.title)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(level.color)
            } else {
                Text("\(severity)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(level.color)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 2 : 4)
        .background(level.color.opacity(0.12), in: .capsule)
    }
}

// MARK: - Food Chip

struct FoodChipView: View {
    let name: String
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(name)")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.accentColor.opacity(0.12), in: .capsule)
        .overlay(
            Capsule()
                .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Card Container

struct ForknoteCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .background(Color.cardBackground, in: .rect(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    func forknoteCardStyle() -> some View {
        self
            .padding(18)
            .background(Color.cardBackground, in: .rect(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}
