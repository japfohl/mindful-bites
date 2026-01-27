import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query private var foodEntries: [FoodEntry]
    @Query private var weightEntries: [WeightEntry]

    var body: some View {
        NavigationStack {
            Group {
                if foodEntries.isEmpty && weightEntries.isEmpty {
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "chart.bar",
                        description: Text("Start logging food and weight to see your insights")
                    )
                } else {
                    List {
                        Section("Streaks") {
                            LabeledContent("Current Streak", value: "0 days")
                            LabeledContent("Longest Streak", value: "0 days")
                        }

                        Section("Activity") {
                            LabeledContent("Total Days Logged", value: "\(foodEntries.count)")
                            LabeledContent("Weight Entries", value: "\(weightEntries.count)")
                        }
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [FoodEntry.self, WeightEntry.self, Tag.self], inMemory: true)
}
