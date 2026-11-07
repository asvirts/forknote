import Foundation

public enum ForknoteConfig {
    public static let displayName = "Forknote"
    public static let appStoreTitle = "Forknote: Food & Symptom Log"
    public static let subtitle = "Meals, flares. Pay once."
    public static let bundleID = "com.asvirts.forknote"
    public static let appGroupID = "group.com.asvirts.forknote"
    public static let proProductID = "com.asvirts.forknote.pro"
    public static let mealControlKind = "com.asvirts.forknote.control.meal"
    public static let proPriceFallback = "$8.99"
    public static let urlScheme = "forknote"
    public static let mealControlFlag = "openedFromMealControl"
    public static let isProCached = "isProCached"
    public static let privacyPolicyURL = URL(string: "https://asvirts.github.io/forknote/privacy.html")!
    public static let supportURL = URL(string: "https://asvirts.github.io/forknote/support.html")!
    public static let termsURL = URL(string: "https://asvirts.github.io/forknote/terms.html")!
    public static let marketingURL = URL(string: "https://asvirts.github.io/forknote/")!
    public static let supportMailtoURL = URL(string: "mailto:asvirts@outlook.com?subject=Forknote%20Support")!
}

public enum SettingsKey {
    public static let isProCached = ForknoteConfig.isProCached
    public static let mealControlFlag = ForknoteConfig.mealControlFlag
}

public extension UserDefaults {
    /// App Group defaults so the Lock Screen control and the app share one flag.
    /// Falls back to `.standard` when the group isn't provisioned. UserDefaults is thread-safe.
    nonisolated(unsafe) static let forknote: UserDefaults =
        UserDefaults(suiteName: ForknoteConfig.appGroupID) ?? .standard
}

public enum SymptomDefaults {
    public static let names = [
        "Pain",
        "Bloating",
        "Nausea",
        "Headache",
        "Fatigue",
        "Rash",
        "Reflux",
        "Brain fog",
    ]
}
