import AppIntents
import ForknoteCore

public struct ForknoteIntentsPackage: AppIntentsPackage {
    public init() {}
}

public struct LogMealControlIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log a Meal"
    public static let description = IntentDescription("Opens Forknote ready to log a meal.")
    public static let openAppWhenRun = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        UserDefaults.forknote.set(true, forKey: SettingsKey.mealControlFlag)
        return .result()
    }
}
