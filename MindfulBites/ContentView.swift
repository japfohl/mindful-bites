import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FoodView()
                .tabItem {
                    Label("Food", systemImage: "fork.knife")
                }

            WeightView()
                .tabItem {
                    Label("Weight", systemImage: "scalemass")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(Color("AccentColor"))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodEntry.self, WeightEntry.self, Tag.self], inMemory: true)
}
