import AppIntents
import ForknoteCore
import ForknoteIntents
import ForknoteStore
import SwiftData
import SwiftUI

struct ForknoteAppIntentsInclusion: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [ForknoteIntentsPackage.self]
    }
}

@main
struct ForknoteApp: App {
    private let container: ModelContainer
    @State private var router = AppRouter()
    @State private var entitlements = EntitlementManager()

    init() {
        do {
            container = try PersistenceController.makeContainer()
        } catch {
            assertionFailure("Failed to open store: \(error)")
            container = try! PersistenceController.makeContainer(inMemory: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(entitlements)
                .onOpenURL { router.handle($0) }
                .task {
                    await entitlements.start()
                    router.consumeMealControl(isPro: entitlements.isPro)
                }
        }
        .modelContainer(container)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Add a Meal") {
                    router.tab = .meal
                    router.focusMealField = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            MealLogView()
                .tabItem { Label("Meal", systemImage: "fork.knife") }
                .tag(AppTab.meal)
            SymptomLogView()
                .tabItem { Label("Symptom", systemImage: "circle.lefthalf.filled") }
                .tag(AppTab.symptom)
            PatternView()
                .tabItem { Label("Pattern", systemImage: "text.quote") }
                .tag(AppTab.pattern)
        }
        .sheet(isPresented: $router.showPaywall) {
            PaywallSheet()
        }
        .task {
            SymptomLibrary.seedIfNeeded(modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                router.consumeMealControl(isPro: entitlements.isPro)
            }
        }
        .onChange(of: router.triggerSeed) { _, shouldSeed in
            guard shouldSeed else { return }
            router.triggerSeed = false
            seedData()
        }
    }

    private func seedData() {
        let calendar = Calendar.current
        let now = Date.now

        try? modelContext.delete(model: Meal.self)
        try? modelContext.delete(model: SymptomEvent.self)

        for daysAgo in [5, 4, 3] {
            if let dayDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                let mealTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: dayDate) ?? dayDate
                modelContext.insert(Meal(eatenAt: mealTime, foods: ["Rice"], note: ""))
            }
        }

        for daysAgo in [2, 1] {
            if let dayDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                let meal1 = calendar.date(bySettingHour: 11, minute: 45, second: 0, of: dayDate) ?? dayDate
                let meal2 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dayDate) ?? dayDate
                let symptomTime = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: dayDate) ?? dayDate
                modelContext.insert(Meal(eatenAt: meal1, foods: ["Oats", "Blueberries"], note: ""))
                modelContext.insert(Meal(eatenAt: meal2, foods: ["Oats"], note: ""))
                modelContext.insert(SymptomEvent(name: "Pain", severity: 3, occurredAt: symptomTime))
            }
        }

        let todayMeal = calendar.date(bySettingHour: 11, minute: 45, second: 0, of: now) ?? now
        let todaySymptom = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now) ?? now
        modelContext.insert(Meal(eatenAt: todayMeal, foods: ["Oats", "Almond milk", "Blueberries"], note: "Breakfast bowl"))
        modelContext.insert(SymptomEvent(name: "Pain", severity: 3, occurredAt: todaySymptom))

        try? modelContext.save()
        router.tab = .meal
    }
}
