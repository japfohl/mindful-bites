import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query private var foodEntries: [FoodEntry]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @State private var settings = SettingsService.shared

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
                    ScrollView {
                        VStack(spacing: 20) {
                            streakSection
                            weightTrendSection
                            activitySection
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Insights")
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logging Streak")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                StreakCard(
                    title: "Current Streak",
                    days: InsightsCalculator.currentStreak(from: foodEntries.map(\.createdAt)),
                    icon: "flame.fill",
                    iconColor: .orange
                )

                StreakCard(
                    title: "Longest Streak",
                    days: InsightsCalculator.longestStreak(from: foodEntries.map(\.createdAt)),
                    icon: "trophy.fill",
                    iconColor: .yellow
                )
            }
        }
    }

    // MARK: - Weight Trend Section

    private var weightTrendSection: some View {
        let result = InsightsCalculator.weightTrend(
            entries: weightEntries.map { (date: $0.date, weightKg: $0.weight) },
            unit: settings.weightUnit
        )
        return VStack(alignment: .leading, spacing: 12) {
            Text("Weight Trend")
                .font(.headline)
                .padding(.horizontal, 4)

            TrendCard(
                trend: result.trend,
                changeAmount: result.changeAmount,
                unit: settings.weightUnit
            )
        }
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        let uniqueDays = InsightsCalculator.uniqueDaysLogged(from: foodEntries.map(\.createdAt))
        return VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                StatCard(
                    title: "Days Logged",
                    value: "\(uniqueDays)",
                    icon: "calendar",
                    iconColor: .blue
                )

                StatCard(
                    title: "Avg Meals/Day",
                    value: InsightsCalculator.averageMealsPerDay(totalEntries: foodEntries.count, uniqueDays: uniqueDays),
                    icon: "fork.knife",
                    iconColor: .green
                )

                StatCard(
                    title: "Total Entries",
                    value: "\(foodEntries.count)",
                    icon: "square.stack.fill",
                    iconColor: .purple
                )

                StatCard(
                    title: "Weight Logs",
                    value: "\(weightEntries.count)",
                    icon: "scalemass.fill",
                    iconColor: .pink
                )
            }
        }
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [FoodEntry.self, WeightEntry.self, Tag.self], inMemory: true)
}
