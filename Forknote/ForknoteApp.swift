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
                .tabItem { Label("Pattern", systemImage: "sparkles") }
                .tag(AppTab.pattern)
            NavigationStack {
                LogListView()
                    .forknoteSettings()
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(AppTab.history)
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
            SampleDataSeeder.seedTwoWeeks(in: modelContext)
            router.tab = .meal
        }
    }
}
