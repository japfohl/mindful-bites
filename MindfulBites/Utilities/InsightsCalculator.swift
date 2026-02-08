import Foundation

struct InsightsCalculator {

    // MARK: - Streak Calculations

    static func uniqueDaysLogged(from dates: [Date]) -> Int {
        Set(dates.map { Calendar.current.startOfDay(for: $0) }).count
    }

    static func currentStreak(from dates: [Date], referenceDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(dates.map { calendar.startOfDay(for: $0) })
            .sorted(by: >)

        guard !uniqueDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: referenceDate)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var currentDate: Date
        if uniqueDays.contains(today) {
            currentDate = today
        } else if uniqueDays.contains(yesterday) {
            currentDate = yesterday
        } else {
            return 0
        }

        var streak = 0
        while uniqueDays.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }

        return streak
    }

    static func longestStreak(from dates: [Date]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(dates.map { calendar.startOfDay(for: $0) })
            .sorted()

        guard !uniqueDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<uniqueDays.count {
            let previousDay = uniqueDays[i - 1]
            let currentDay = uniqueDays[i]

            if let expectedNext = calendar.date(byAdding: .day, value: 1, to: previousDay),
               calendar.isDate(currentDay, inSameDayAs: expectedNext) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    static func averageMealsPerDay(totalEntries: Int, uniqueDays: Int) -> String {
        guard uniqueDays > 0 else { return "0" }
        let average = Double(totalEntries) / Double(uniqueDays)
        return String(format: "%.1f", average)
    }

    // MARK: - Weight Trend Calculations

    struct WeightTrendResult {
        let trend: WeightTrend
        let changeAmount: Double?
    }

    static func weightTrend(
        entries: [(date: Date, weightKg: Double)],
        unit: WeightUnit,
        referenceDate: Date = Date()
    ) -> WeightTrendResult {
        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: referenceDate) else {
            return WeightTrendResult(trend: .notEnoughData, changeAmount: nil)
        }

        let recentEntries = entries.filter { $0.date >= sevenDaysAgo }
        guard recentEntries.count >= 2 else {
            return WeightTrendResult(trend: .notEnoughData, changeAmount: nil)
        }

        let sorted = recentEntries.sorted { $0.date < $1.date }
        let first = sorted.first!
        let last = sorted.last!

        let change = last.weightKg - first.weightKg
        let convertedChange = unit.convert(fromKg: change)

        let threshold = unit == .lbs ? 0.5 : 0.23

        let trend: WeightTrend
        if abs(convertedChange) < threshold {
            trend = .stable
        } else if convertedChange > 0 {
            trend = .up
        } else {
            trend = .down
        }

        return WeightTrendResult(trend: trend, changeAmount: convertedChange)
    }
}
