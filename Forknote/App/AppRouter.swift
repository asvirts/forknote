import ForknoteCore
import SwiftUI

enum AppTab: Hashable {
    case meal
    case symptom
    case pattern
}

@MainActor @Observable
final class AppRouter {
    var tab: AppTab = .meal
    var showPaywall = false
    var focusMealField = false
    var selectedSymptom: String?
    var triggerSeed = false

    func consumeMealControl(isPro: Bool) {
        let defaults = UserDefaults.forknote
        guard defaults.bool(forKey: SettingsKey.mealControlFlag) else { return }
        defaults.set(false, forKey: SettingsKey.mealControlFlag)
        if isPro {
            tab = .meal
            focusMealField = true
        } else {
            showPaywall = true
        }
    }

    func handle(_ url: URL) {
        guard url.scheme == ForknoteConfig.urlScheme else { return }
        switch url.host {
        case "symptom":
            tab = .symptom
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let name = components.queryItems?.first(where: { $0.name == "name" })?.value {
                selectedSymptom = name
            }
        case "pattern":
            tab = .pattern
        case "paywall":
            showPaywall = true
        case "seed":
            triggerSeed = true
        default:
            tab = .meal
            focusMealField = true
        }
    }
}
