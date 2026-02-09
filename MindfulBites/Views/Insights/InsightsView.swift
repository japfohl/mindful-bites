import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query private var foodEntries: [FoodEntry]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @State private var settings = SettingsService.shared

    // MARK: - Computed Insights

    private struct ComputedInsights {
        let currentStreak: Int
        let longestStreak: Int
        let uniqueDays: Int
        let averageMealsPerDay: String
        let weightTrend: InsightsCalculator.WeightTrendResult
    }

    private func computeInsights() -> ComputedInsights {
        let dates = foodEntries.map(\.createdAt)
        let uniqueDays = InsightsCalculator.uniqueDaysLogged(from: dates)
        return ComputedInsights(
            currentStreak: InsightsCalculator.currentStreak(from: dates),
            longestStreak: InsightsCalculator.longestStreak(from: dates),
            uniqueDays: uniqueDays,
            averageMealsPerDay: InsightsCalculator.averageMealsPerDay(totalEntries: foodEntries.count, uniqueDays: uniqueDays),
            weightTrend: InsightsCalculator.weightTrend(
                entries: weightEntries.map { (date: $0.date, weightKg: $0.weight) },
                unit: settings.weightUnit
            )
        )
    }

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
                    let insights = computeInsights()
                    ScrollView {
                        VStack(spacing: 20) {
                            streakSection(currentStreak: insights.currentStreak, longestStreak: insights.longestStreak)
                            weightTrendSection(result: insights.weightTrend)
                            activitySection(uniqueDays: insights.uniqueDays, avgMeals: insights.averageMealsPerDay)
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

    private func streakSection(currentStreak: Int, longestStreak: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logging Streak")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                StreakCard(
                    title: "Current Streak",
                    days: currentStreak,
                    icon: "flame.fill",
                    iconColor: .orange
                )

                StreakCard(
                    title: "Longest Streak",
                    days: longestStreak,
                    icon: "trophy.fill",
                    iconColor: .yellow
                )
            }
        }
    }

    // MARK: - Weight Trend Section

    private func weightTrendSection(result: InsightsCalculator.WeightTrendResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

    private func activitySection(uniqueDays: Int, avgMeals: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    value: avgMeals,
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
