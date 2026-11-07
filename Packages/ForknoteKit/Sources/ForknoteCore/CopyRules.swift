import Foundation

public enum PatternCopy {
    public static let screenEmpty = "Nothing stands out alongside your symptoms yet."
    public static let screenEmptyDetail = "Keep logging meals and how you feel. Everyday foods stay quiet, and a food needs several meals before it can show up in a sentence."
    public static let reportEmpty = "No food stands out alongside your symptoms in this log."
    public static let comparisonTwoHour = "Compared with quiet days, within 2 hours."
    public static let comparisonDay = "Compared with quiet days, within 24 hours."
    public static let disclaimer = "This is a personal log. It is not a medical device."
    public static let proHistory = "Patterns over your full history are part of Forknote Pro."
    public static let proPDF = "A plain PDF of your log is part of Forknote Pro."
    public static let proSymptoms = "Your own symptom list is part of Forknote Pro."
    public static let proControl = "The Lock Screen control is part of Forknote Pro."
    public static let spanSevenDays = "Last 7 days"
    public static let spanFullLog = "Full log"

    public static var audited: [String] {
        [
            screenEmpty,
            screenEmptyDetail,
            reportEmpty,
            comparisonTwoHour,
            comparisonDay,
            disclaimer,
            proHistory,
            proPDF,
            proSymptoms,
            proControl,
            spanSevenDays,
            spanFullLog,
        ]
    }
}

public enum CopyRules {
    /// Flags the claims this log must never make. "because" is allowed; the banned words are matched whole.
    public static func containsForbiddenClaim(_ text: String) -> Bool {
        let words = text.lowercased().split { !$0.isLetter }.map(String.init)
        return words.contains { word in
            switch word {
            case "cause", "causes", "caused", "causing", "avoid", "avoids", "avoided", "avoiding":
                return true
            default:
                return word.hasPrefix("diagnos")
            }
        }
    }
}
