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
        case "pattern":
            tab = .pattern
        case "paywall":
            showPaywall = true
        default:
            tab = .meal
            focusMealField = true
        }
    }
}
