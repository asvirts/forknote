import Foundation

public enum PatternWindow: String, Sendable, Equatable {
    case twoHour
    case twentyFourHour

    public var duration: TimeInterval {
        switch self {
        case .twoHour: 2 * 60 * 60
        case .twentyFourHour: 24 * 60 * 60
        }
    }
}

public struct PatternHit: Sendable, Equatable {
    public var food: String
    public var symptom: String
    public var window: PatternWindow
    public var symptomDaysWithFood: Int
    public var symptomDayCount: Int
    public var quietDaysWithFood: Int
    public var quietDayCount: Int
    public var mealCount: Int
    public var sentence: String

    public var comparison: String {
        switch window {
        case .twoHour: PatternCopy.comparisonTwoHour
        case .twentyFourHour: PatternCopy.comparisonDay
        }
    }
}

/// One sentence about a food that shows up more before a symptom than on quiet days.
///
/// A food eaten on most meal days stays quiet even when it is also on symptom days.
/// Fewer than 5 meals stays hidden. The 2-hour window is preferred when both windows qualify,
/// so a free 7-day log can still produce a sentence (3 symptom days and 3 quiet days fit in a week).
public enum PatternMath {
    public static let minimumExposures = 5
    public static let minimumSymptomDays = 3
    public static let minimumQuietDays = 3
    public static let minimumSymptomDaysWithFood = 3

    public static func strongest(
        meals: [MealRecord],
        symptoms: [SymptomRecord],
        symptomName: String? = nil,
        range: AnalysisRange,
        calendar: Calendar
    ) -> PatternHit? {
        rankedHits(meals: meals, symptoms: symptoms, symptomName: symptomName, range: range, calendar: calendar).first
    }

    public static func rankedHits(
        meals: [MealRecord],
        symptoms: [SymptomRecord],
        symptomName: String? = nil,
        range: AnalysisRange,
        calendar: Calendar
    ) -> [PatternHit] {
        let rangeMeals = meals.filter { contains($0.eatenAt, range: range) }
        let evidenceMeals = meals.filter { isEvidence($0.eatenAt, range: range) }
        let rangeSymptoms = symptoms.filter { contains($0.occurredAt, range: range) }
        guard !rangeMeals.isEmpty, !rangeSymptoms.isEmpty else { return [] }

        let symptomKeys = keys(in: rangeSymptoms, only: symptomName)
        var hits: [PatternHit] = []

        for symptomKey in symptomKeys {
            let events = rangeSymptoms.filter { NameKey.normalize($0.name) == symptomKey }
            guard !events.isEmpty else { continue }

            let eventsByDay = Dictionary(grouping: events) { calendar.startOfDay(for: $0.occurredAt) }
            let symptomDays = Set(eventsByDay.keys)
            let mealDays = Set(rangeMeals.map { calendar.startOfDay(for: $0.eatenAt) })
            let quietDays = mealDays.subtracting(symptomDays)
            guard symptomDays.count >= minimumSymptomDays, quietDays.count >= minimumQuietDays else { continue }

            let median = medianMinute(events, calendar: calendar)
            let symptomDisplay = preferredCasing(events.map { ($0.name, $0.occurredAt) })
            var foodKeys = Set<String>()
            for meal in rangeMeals {
                for food in meal.foods {
                    if let key = NameKey.normalize(food) { foodKeys.insert(key) }
                }
            }

            for foodKey in foodKeys {
                let stats = foodStats(key: foodKey, meals: rangeMeals, calendar: calendar)
                guard stats.mealCount >= minimumExposures else { continue }
                guard !isEveryday(foodDays: stats.days.count, mealDays: mealDays.count) else { continue }

                let display = preferredCasing(stats.samples)
                guard !display.isEmpty else { continue }

                var chosen: PatternHit?
                for window in [PatternWindow.twoHour, .twentyFourHour] {
                    let symptomHits = daysWithFoodBeforeSymptom(
                        days: symptomDays,
                        eventsByDay: eventsByDay,
                        meals: evidenceMeals,
                        key: foodKey,
                        window: window.duration
                    )
                    let quietHits = quietDaysWithFood(
                        days: quietDays,
                        meals: evidenceMeals,
                        key: foodKey,
                        window: window,
                        medianMinute: median,
                        calendar: calendar
                    )
                    guard qualifies(
                        symptomHits: symptomHits,
                        symptomDays: symptomDays.count,
                        quietHits: quietHits,
                        quietDays: quietDays.count
                    ) else { continue }

                    chosen = makeHit(
                        food: display,
                        symptom: symptomDisplay,
                        window: window,
                        symptomHits: symptomHits,
                        symptomDays: symptomDays.count,
                        quietHits: quietHits,
                        quietDays: quietDays.count,
                        mealCount: stats.mealCount
                    )
                    if window == .twoHour { break }
                }
                if let chosen { hits.append(chosen) }
            }
        }

        return hits.sorted(by: isStronger)
    }

    public static func sentence(
        food: String,
        symptom: String,
        window: PatternWindow,
        symptomHits: Int,
        symptomDays: Int,
        mealCount: Int
    ) -> String {
        let symptomWord = symptom.lowercased(with: Locale(identifier: "en"))
        let timing = window == .twoHour ? ", within 2 hours" : ""
        return "\(food) shows up alongside \(symptomWord) in \(symptomHits) of your last \(symptomDays) \(symptomWord) days, across \(mealCount) meals\(timing)."
    }

    // MARK: - Gates

    /// Eaten on at least 70% of days that have a meal. Compared in integers so 7 of 10 is exact.
    static func isEveryday(foodDays: Int, mealDays: Int) -> Bool {
        guard mealDays > 0 else { return false }
        return foodDays * 10 >= mealDays * 7
    }

    static func qualifies(symptomHits: Int, symptomDays: Int, quietHits: Int, quietDays: Int) -> Bool {
        guard symptomHits >= minimumSymptomDaysWithFood else { return false }
        guard symptomHits * 2 >= symptomDays else { return false }
        let numerator = symptomHits * quietDays - quietHits * symptomDays
        guard numerator > 0 else { return false }
        let denominator = symptomDays * quietDays
        return numerator * 10 >= denominator * 3
    }

    // MARK: - Windows

    private static func contains(_ date: Date, range: AnalysisRange) -> Bool {
        if date >= range.end { return false }
        if let start = range.start, date < start { return false }
        return true
    }

    /// Meals up to 24 hours before the range can still sit inside a symptom's lookback window.
    private static func isEvidence(_ date: Date, range: AnalysisRange) -> Bool {
        if date >= range.end { return false }
        guard let start = range.start else { return true }
        let floor = start.addingTimeInterval(-PatternWindow.twentyFourHour.duration)
        return date >= floor
    }

    private static func daysWithFoodBeforeSymptom(
        days: Set<Date>,
        eventsByDay: [Date: [SymptomRecord]],
        meals: [MealRecord],
        key: String,
        window: TimeInterval
    ) -> Int {
        var count = 0
        for day in days {
            guard let events = eventsByDay[day] else { continue }
            let hit = events.contains { event in
                let start = event.occurredAt.addingTimeInterval(-window)
                return meals.contains { meal in
                    meal.eatenAt >= start
                        && meal.eatenAt <= event.occurredAt
                        && mealHas(meal, key: key)
                }
            }
            if hit { count += 1 }
        }
        return count
    }

    private static func quietDaysWithFood(
        days: Set<Date>,
        meals: [MealRecord],
        key: String,
        window: PatternWindow,
        medianMinute: Int,
        calendar: Calendar
    ) -> Int {
        var count = 0
        for day in days {
            let hit: Bool
            switch window {
            case .twentyFourHour:
                hit = meals.contains { calendar.startOfDay(for: $0.eatenAt) == day && mealHas($0, key: key) }
            case .twoHour:
                guard let end = calendar.date(byAdding: .minute, value: medianMinute, to: day) else { continue }
                let start = end.addingTimeInterval(-window.duration)
                hit = meals.contains { $0.eatenAt >= start && $0.eatenAt <= end && mealHas($0, key: key) }
            }
            if hit { count += 1 }
        }
        return count
    }

    private static func mealHas(_ meal: MealRecord, key: String) -> Bool {
        meal.foods.contains { NameKey.normalize($0) == key }
    }

    // MARK: - Names and ranking

    private struct FoodStats {
        var mealCount = 0
        var days = Set<Date>()
        var samples: [(String, Date)] = []
    }

    private static func foodStats(key: String, meals: [MealRecord], calendar: Calendar) -> FoodStats {
        var stats = FoodStats()
        for meal in meals {
            let matches = meal.foods.filter { NameKey.normalize($0) == key }
            guard !matches.isEmpty else { continue }
            stats.mealCount += 1
            stats.days.insert(calendar.startOfDay(for: meal.eatenAt))
            for raw in matches {
                stats.samples.append((raw, meal.eatenAt))
            }
        }
        return stats
    }

    private struct CasingTally {
        var count = 0
        var latest = Date.distantPast
    }

    private static func preferredCasing(_ samples: [(String, Date)]) -> String {
        var tallies: [String: CasingTally] = [:]
        for (raw, date) in samples {
            guard let display = NameKey.displayForm(raw) else { continue }
            var tally = tallies[display] ?? CasingTally()
            tally.count += 1
            if date >= tally.latest { tally.latest = date }
            tallies[display] = tally
        }
        let best = tallies.max { lhs, rhs in
            if lhs.value.count != rhs.value.count { return lhs.value.count < rhs.value.count }
            if lhs.value.latest != rhs.value.latest { return lhs.value.latest < rhs.value.latest }
            return lhs.key > rhs.key
        }
        return best?.key ?? ""
    }

    private static func keys(in symptoms: [SymptomRecord], only symptomName: String?) -> [String] {
        if let symptomName {
            return NameKey.normalize(symptomName).map { [$0] } ?? []
        }
        var seen = Set<String>()
        return symptoms.compactMap { event in
            guard let key = NameKey.normalize(event.name), seen.insert(key).inserted else { return nil }
            return key
        }
    }

    private static func medianMinute(_ events: [SymptomRecord], calendar: Calendar) -> Int {
        let minutes = events.map { clockMinute($0.occurredAt, calendar: calendar) }.sorted()
        guard !minutes.isEmpty else { return 0 }
        let mid = minutes.count / 2
        if minutes.count.isMultiple(of: 2) {
            return (minutes[mid - 1] + minutes[mid]) / 2
        }
        return minutes[mid]
    }

    private static func clockMinute(_ date: Date, calendar: Calendar) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    private static func makeHit(
        food: String,
        symptom: String,
        window: PatternWindow,
        symptomHits: Int,
        symptomDays: Int,
        quietHits: Int,
        quietDays: Int,
        mealCount: Int
    ) -> PatternHit {
        PatternHit(
            food: food,
            symptom: symptom,
            window: window,
            symptomDaysWithFood: symptomHits,
            symptomDayCount: symptomDays,
            quietDaysWithFood: quietHits,
            quietDayCount: quietDays,
            mealCount: mealCount,
            sentence: sentence(
                food: food,
                symptom: symptom,
                window: window,
                symptomHits: symptomHits,
                symptomDays: symptomDays,
                mealCount: mealCount
            )
        )
    }

    private static func isStronger(_ lhs: PatternHit, _ rhs: PatternHit) -> Bool {
        let left = gap(lhs)
        let right = gap(rhs)
        let crossLeft = left.numerator * right.denominator
        let crossRight = right.numerator * left.denominator
        if crossLeft != crossRight { return crossLeft > crossRight }
        if lhs.symptomDaysWithFood != rhs.symptomDaysWithFood {
            return lhs.symptomDaysWithFood > rhs.symptomDaysWithFood
        }
        if lhs.window != rhs.window { return lhs.window == .twoHour }
        if lhs.food != rhs.food { return lhs.food < rhs.food }
        return lhs.symptom < rhs.symptom
    }

    private static func gap(_ hit: PatternHit) -> (numerator: Int, denominator: Int) {
        let numerator = hit.symptomDaysWithFood * hit.quietDayCount - hit.quietDaysWithFood * hit.symptomDayCount
        let denominator = max(hit.symptomDayCount * hit.quietDayCount, 1)
        return (numerator, denominator)
    }
}
