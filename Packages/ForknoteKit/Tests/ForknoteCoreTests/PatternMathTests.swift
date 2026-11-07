import Foundation
import Testing
@testable import ForknoteCore

@Suite struct PatternMathTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }()

    func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: day, hour: hour, minute: minute))!
    }

    func meal(_ day: Int, _ hour: Int, _ minute: Int, _ foods: String...) -> MealRecord {
        MealRecord(id: UUID(), eatenAt: date(day, hour, minute), foods: Array(foods), note: "")
    }

    func symptom(_ day: Int, _ hour: Int, _ minute: Int, name: String = "Pain", severity: Int = 3) -> SymptomRecord {
        SymptomRecord(id: UUID(), name: name, severity: severity, occurredAt: date(day, hour, minute))
    }

    var june: AnalysisRange {
        AnalysisRange(start: date(1, 0), end: date(28, 0))
    }

    func hits(meals: [MealRecord], symptoms: [SymptomRecord], name: String? = nil, range: AnalysisRange? = nil) -> [PatternHit] {
        PatternMath.rankedHits(
            meals: meals,
            symptoms: symptoms,
            symptomName: name,
            range: range ?? june,
            calendar: calendar
        )
    }

    @Test func everydayFoodOnPainDaysStaysQuiet() {
        // Cheese is on 7 of 10 meal days, including 6 of 6 pain days. That overlap must not surface.
        // Lamb is only on the pain days (6 of 10) and should.
        var meals: [MealRecord] = []
        var symptoms: [SymptomRecord] = []
        for day in 1...6 {
            meals.append(meal(day, 12, 0, "Lamb", "Cheese"))
            symptoms.append(symptom(day, 12, 30))
        }
        meals.append(meal(7, 12, 0, "Cheese"))
        for day in 8...10 {
            meals.append(meal(day, 12, 0, "Rice"))
        }

        let ranked = hits(meals: meals, symptoms: symptoms)
        #expect(ranked.contains { $0.food == "Cheese" } == false)
        #expect(ranked.contains { $0.food == "Rice" } == false)
        #expect(ranked.first?.sentence == "Lamb shows up alongside pain in 6 of your last 6 pain days, across 6 meals, within 2 hours.")
    }

    @Test func rareFoodWithFewExposuresStaysHidden() {
        // Four shrimp meals, each clustered before pain, still stay hidden.
        var meals: [MealRecord] = []
        var symptoms: [SymptomRecord] = []
        for day in 1...3 {
            meals.append(meal(day, 12, 0, "Rice"))
        }
        for day in 4...6 {
            meals.append(meal(day, 12, 0, "Shrimp"))
            symptoms.append(symptom(day, 12, 30))
        }
        meals.append(meal(4, 10, 0, "Shrimp"))

        #expect(hits(meals: meals, symptoms: symptoms).isEmpty)
    }

    @Test func foodClusteredBeforeSymptomsCanSurface() {
        var meals: [MealRecord] = []
        var symptoms: [SymptomRecord] = []
        for day in 1...6 {
            meals.append(meal(day, 12, 0, "Rice"))
        }
        for day in 7...12 {
            meals.append(meal(day, 12, 0, "Oats", "Rice"))
            symptoms.append(symptom(day, 12, 30))
        }
        meals.append(meal(7, 12, 10, "Shrimp"))
        meals.append(meal(8, 12, 10, "Shrimp"))

        let ranked = hits(meals: meals, symptoms: symptoms)
        #expect(ranked.map(\.food) == ["Oats"])
        #expect(ranked[0].window == .twoHour)
        #expect(ranked[0].sentence == "Oats shows up alongside pain in 6 of your last 6 pain days, across 6 meals, within 2 hours.")
        #expect(CopyRules.containsForbiddenClaim(ranked[0].sentence) == false)
    }

    @Test func twoHourBoundaryAndDayWindow() {
        var meals: [MealRecord] = []
        var symptoms: [SymptomRecord] = []
        for day in 1...4 {
            meals.append(meal(day, 12, 0, "Rice"))
        }
        for day in 5...10 {
            meals.append(meal(day, 11, 59, "Juice"))
            meals.append(meal(day, 12, 0, "Tea", "Rice"))
            symptoms.append(symptom(day, 14, 0))
        }

        let ranked = hits(meals: meals, symptoms: symptoms)
        let tea = ranked.first { $0.food == "Tea" }
        let juice = ranked.first { $0.food == "Juice" }
        #expect(tea?.window == .twoHour)
        #expect(tea?.sentence.contains("within 2 hours") == true)
        #expect(juice?.window == .twentyFourHour)
        #expect(juice?.sentence.contains("within 2 hours") == false)
        #expect(juice?.sentence == "Juice shows up alongside pain in 6 of your last 6 pain days, across 6 meals.")
        #expect(ranked.contains { $0.food == "Rice" } == false)
    }

    @Test func casingMergesAndKeepsTheCommonSpelling() {
        var meals: [MealRecord] = []
        var symptoms: [SymptomRecord] = []
        for day in 1...3 {
            meals.append(meal(day, 12, 0, "Rice"))
        }
        let spellings = ["Greek Yogurt", "Greek Yogurt", "Greek Yogurt", "Greek Yogurt", "greek yogurt", "greek yogurt"]
        for (offset, spelling) in spellings.enumerated() {
            let day = 4 + offset
            meals.append(meal(day, 12, 0, spelling))
            symptoms.append(symptom(day, 12, 30))
        }

        let hit = hits(meals: meals, symptoms: symptoms).first
        #expect(hit?.food == "Greek Yogurt")
        #expect(hit?.mealCount == 6)
        #expect(hit?.sentence.hasPrefix("Greek Yogurt shows up alongside pain") == true)
    }

    @Test func lastSevenDaysIgnoresOlderClusters() {
        var meals: [MealRecord] = []
        var symptoms: [SymptomRecord] = []
        for day in 1...6 {
            meals.append(meal(day, 12, 0, "Rice"))
        }
        for day in 7...12 {
            meals.append(meal(day, 12, 0, "Oats"))
            symptoms.append(symptom(day, 12, 30))
        }
        let now = date(28, 15)
        let recent = AnalysisRange.lastSevenDays(ending: now, calendar: calendar)
        let all = AnalysisRange.fullHistory(ending: now, calendar: calendar)

        #expect(hits(meals: meals, symptoms: symptoms, range: recent).isEmpty)
        #expect(hits(meals: meals, symptoms: symptoms, range: all).first?.food == "Oats")
    }

    @Test func lastSevenDaysCanSpeak() {
        var meals: [MealRecord] = []
        var symptoms: [SymptomRecord] = []
        for day in 22...24 {
            meals.append(meal(day, 12, 0, "Rice"))
        }
        for day in [25, 26] {
            meals.append(meal(day, 12, 0, "Oats"))
            meals.append(meal(day, 15, 0, "Oats"))
            symptoms.append(symptom(day, 12, 30))
        }
        meals.append(meal(27, 12, 0, "Oats"))
        symptoms.append(symptom(27, 12, 30))

        let range = AnalysisRange.lastSevenDays(ending: date(28, 15), calendar: calendar)
        let hit = hits(meals: meals, symptoms: symptoms, range: range).first
        #expect(hit?.sentence == "Oats shows up alongside pain in 3 of your last 3 pain days, across 5 meals, within 2 hours.")
    }

    @Test func tooFewQuietDaysStayHidden() {
        // Five oats meals across three pain days would surface if two quiet days were enough.
        var meals: [MealRecord] = []
        var symptoms: [SymptomRecord] = []
        for day in 1...3 {
            meals.append(meal(day, 12, 0, "Oats"))
            symptoms.append(symptom(day, 12, 30))
        }
        meals.append(meal(1, 15, 0, "Oats"))
        meals.append(meal(2, 15, 0, "Oats"))
        for day in 4...5 {
            meals.append(meal(day, 12, 0, "Rice"))
        }
        #expect(hits(meals: meals, symptoms: symptoms).isEmpty)
    }

    @Test func sentencesAndChromeAvoidClinicalClaims() {
        #expect(CopyRules.containsForbiddenClaim("because the meal was earlier") == false)
        #expect(CopyRules.containsForbiddenClaim("This causes pain") == true)
        #expect(CopyRules.containsForbiddenClaim("avoid dairy") == true)
        #expect(CopyRules.containsForbiddenClaim("It diagnoses you") == true)
        for line in PatternCopy.audited {
            #expect(CopyRules.containsForbiddenClaim(line) == false, "\(line)")
        }
    }
}

@Suite struct LogTextTests {
    @Test func storePagesUseThePublicSite() {
        #expect(ForknoteConfig.privacyPolicyURL.absoluteString == "https://asvirts.github.io/forknote/privacy.html")
        #expect(ForknoteConfig.supportURL.absoluteString == "https://asvirts.github.io/forknote/support.html")
        #expect(ForknoteConfig.termsURL.absoluteString == "https://asvirts.github.io/forknote/terms.html")
        #expect(ForknoteConfig.marketingURL.absoluteString == "https://asvirts.github.io/forknote/")
    }

    @Test func identifiersMatchTheAppName() {
        #expect(ForknoteConfig.bundleID == "com.asvirts.forknote")
        #expect(ForknoteConfig.appGroupID == "group.com.asvirts.forknote")
        #expect(ForknoteConfig.proProductID == "com.asvirts.forknote.pro")
        #expect(ForknoteConfig.mealControlKind == "com.asvirts.forknote.control.meal")
        #expect(ForknoteConfig.urlScheme == "forknote")
    }

    @Test func typedFoodsSplitAndCollapse() {
        #expect(NameKey.uniqueDisplayNames(in: " eggs, toast , , coffee ") == ["eggs", "toast", "coffee"])
        #expect(NameKey.uniqueDisplayNames(in: "Greek  Yogurt") == ["Greek Yogurt"])
        #expect(NameKey.uniqueDisplayNames(in: "Oats, oats, Toast") == ["Oats", "Toast"])
        #expect(NameKey.normalize("  Greek   yogurt ") == "greek yogurt")
    }

    @Test func recentsKeepTheNewestSpelling() {
        let meals = [
            MealRecord(id: UUID(), eatenAt: Date(timeIntervalSince1970: 20), foods: ["greek yogurt"], note: ""),
            MealRecord(id: UUID(), eatenAt: Date(timeIntervalSince1970: 30), foods: ["Greek Yogurt", "Oats"], note: ""),
            MealRecord(id: UUID(), eatenAt: Date(timeIntervalSince1970: 10), foods: ["Rice"], note: ""),
        ]
        #expect(RecentFoods.names(in: meals, limit: 2) == ["Greek Yogurt", "Oats"])
    }

    @Test func reportListsMealsSymptomsAndSentences() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        let eaten = calendar.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 12))!
        let felt = calendar.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 13))!
        let meals = [MealRecord(id: UUID(), eatenAt: eaten, foods: ["Oats", "Rice"], note: "Left at home")]
        let symptoms = [SymptomRecord(id: UUID(), name: "Pain", severity: 3, occurredAt: felt)]
        let sentence = "Oats shows up alongside pain in 6 of your last 6 pain days, across 6 meals, within 2 hours."
        let report = ReportBuilder.make(
            meals: meals,
            symptoms: symptoms,
            sentences: [sentence],
            generatedAt: felt,
            calendar: calendar
        )
        #expect(report.plainText.contains("Oats, Rice"))
        #expect(report.plainText.contains("Left at home"))
        #expect(report.plainText.contains("Pain, strength 3 of 5"))
        #expect(report.plainText.contains(sentence))
        #expect(report.plainText.contains(PatternCopy.disclaimer))
        #expect(report.plainText.contains("1 meal, 1 symptom."))
        #expect(CopyRules.containsForbiddenClaim(sentence) == false)
    }
}
