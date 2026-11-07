import AppIntents
import ForknoteCore
import ForknoteIntents
import SwiftUI
import WidgetKit

struct ForknoteWidgetIntentsInclusion: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [ForknoteIntentsPackage.self]
    }
}

@main
struct ForknoteWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LogMealControl()
    }
}

struct LogMealControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: ForknoteConfig.mealControlKind) {
            ControlWidgetButton(action: LogMealControlIntent()) {
                Label("Log a meal", systemImage: "fork.knife")
            }
        }
        .displayName("Log a Meal")
        .description("Open Forknote to log a meal. Part of Forknote Pro.")
    }
}
