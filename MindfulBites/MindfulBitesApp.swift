import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct MindfulBitesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodEntry.self,
            WeightEntry.self,
            Tag.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .task {
                    await NotificationService.shared.syncWithSettings()
                    await CloudProviderRegistry.shared.restorePreviousSession()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
