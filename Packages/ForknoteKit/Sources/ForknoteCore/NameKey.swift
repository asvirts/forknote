import Foundation

/// How a typed food or symptom name is matched. No food database: the letters the person typed are the identity.
public enum NameKey {
    public static func displayForm(_ raw: String) -> String? {
        let collapsed = raw.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard !collapsed.isEmpty else { return nil }
        return collapsed
    }

    public static func normalize(_ raw: String) -> String? {
        displayForm(raw)?.lowercased()
    }

    /// Splits a typed or pasted field on commas and new lines, keeping the person's casing.
    public static func uniqueDisplayNames(in raw: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        let parts = raw.split { $0 == "," || $0.isNewline }
        for part in parts {
            guard let display = displayForm(String(part)), let key = normalize(display) else { continue }
            guard seen.insert(key).inserted else { continue }
            result.append(display)
        }
        return result
    }
}

public enum RecentFoods {
    public static func names(in meals: [MealRecord], limit: Int = 12) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for meal in meals.sorted(by: { $0.eatenAt > $1.eatenAt }) {
            for food in meal.foods {
                guard let display = NameKey.displayForm(food), let key = NameKey.normalize(food) else { continue }
                guard seen.insert(key).inserted else { continue }
                result.append(display)
                if result.count == limit { return result }
            }
        }
        return result
    }
}
