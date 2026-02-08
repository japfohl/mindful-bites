import XCTest
@testable import MindfulBites

final class InsightsCalculatorTests: XCTestCase {

    // MARK: - Unique Days Logged

    func testUniqueDaysLoggedEmpty() {
        XCTAssertEqual(InsightsCalculator.uniqueDaysLogged(from: []), 0)
    }

    func testUniqueDaysLoggedSingleDay() {
        let now = Date()
        XCTAssertEqual(InsightsCalculator.uniqueDaysLogged(from: [now, now, now]), 1)
    }

    func testUniqueDaysLoggedMultipleDays() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        XCTAssertEqual(InsightsCalculator.uniqueDaysLogged(from: [today, yesterday, twoDaysAgo, today]), 3)
    }

    // MARK: - Current Streak

    func testCurrentStreakEmpty() {
        XCTAssertEqual(InsightsCalculator.currentStreak(from: []), 0)
    }

    func testCurrentStreakTodayOnly() {
        let today = Date()
        XCTAssertEqual(InsightsCalculator.currentStreak(from: [today], referenceDate: today), 1)
    }

    func testCurrentStreakYesterdayOnly() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        XCTAssertEqual(InsightsCalculator.currentStreak(from: [yesterday], referenceDate: today), 1)
    }

    func testCurrentStreakConsecutiveDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dates = (0..<5).map { calendar.date(byAdding: .day, value: -$0, to: today)! }
        XCTAssertEqual(InsightsCalculator.currentStreak(from: dates, referenceDate: today), 5)
    }

    func testCurrentStreakBrokenStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Today, yesterday, skip a day, then 3 more days
        let dates = [
            today,
            calendar.date(byAdding: .day, value: -1, to: today)!,
            calendar.date(byAdding: .day, value: -3, to: today)!,
            calendar.date(byAdding: .day, value: -4, to: today)!,
        ]
        XCTAssertEqual(InsightsCalculator.currentStreak(from: dates, referenceDate: today), 2)
    }

    func testCurrentStreakNoRecentEntries() {
        let calendar = Calendar.current
        let today = Date()
        let oldDate = calendar.date(byAdding: .day, value: -10, to: today)!
        XCTAssertEqual(InsightsCalculator.currentStreak(from: [oldDate], referenceDate: today), 0)
    }

    // MARK: - Longest Streak

    func testLongestStreakEmpty() {
        XCTAssertEqual(InsightsCalculator.longestStreak(from: []), 0)
    }

    func testLongestStreakSingleDay() {
        XCTAssertEqual(InsightsCalculator.longestStreak(from: [Date()]), 1)
    }

    func testLongestStreakMultipleStreaks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Streak 1: 3 days
        // Gap
        // Streak 2: 5 days (longest)
        let dates = [
            today,
            calendar.date(byAdding: .day, value: -1, to: today)!,
            calendar.date(byAdding: .day, value: -2, to: today)!,
            // gap at -3
            calendar.date(byAdding: .day, value: -4, to: today)!,
            calendar.date(byAdding: .day, value: -5, to: today)!,
            calendar.date(byAdding: .day, value: -6, to: today)!,
            calendar.date(byAdding: .day, value: -7, to: today)!,
            calendar.date(byAdding: .day, value: -8, to: today)!,
        ]
        XCTAssertEqual(InsightsCalculator.longestStreak(from: dates), 5)
    }

    // MARK: - Average Meals Per Day

    func testAverageMealsPerDayZeroDays() {
        XCTAssertEqual(InsightsCalculator.averageMealsPerDay(totalEntries: 10, uniqueDays: 0), "0")
    }

    func testAverageMealsPerDayNormal() {
        XCTAssertEqual(InsightsCalculator.averageMealsPerDay(totalEntries: 15, uniqueDays: 5), "3.0")
    }

    func testAverageMealsPerDayFractional() {
        XCTAssertEqual(InsightsCalculator.averageMealsPerDay(totalEntries: 7, uniqueDays: 3), "2.3")
    }

    // MARK: - Weight Trend

    func testWeightTrendNotEnoughData() {
        let result = InsightsCalculator.weightTrend(entries: [], unit: .lbs)
        XCTAssertEqual(result.trend, .notEnoughData)
        XCTAssertNil(result.changeAmount)
    }

    func testWeightTrendSingleEntry() {
        let result = InsightsCalculator.weightTrend(
            entries: [(date: Date(), weightKg: 80.0)],
            unit: .lbs
        )
        XCTAssertEqual(result.trend, .notEnoughData)
    }

    func testWeightTrendUp() {
        let now = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let result = InsightsCalculator.weightTrend(
            entries: [
                (date: threeDaysAgo, weightKg: 80.0),
                (date: now, weightKg: 82.0),
            ],
            unit: .kg,
            referenceDate: now
        )
        XCTAssertEqual(result.trend, .up)
        XCTAssertNotNil(result.changeAmount)
        XCTAssertEqual(result.changeAmount!, 2.0, accuracy: 0.01)
    }

    func testWeightTrendDown() {
        let now = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let result = InsightsCalculator.weightTrend(
            entries: [
                (date: threeDaysAgo, weightKg: 82.0),
                (date: now, weightKg: 80.0),
            ],
            unit: .kg,
            referenceDate: now
        )
        XCTAssertEqual(result.trend, .down)
        XCTAssertEqual(result.changeAmount!, -2.0, accuracy: 0.01)
    }

    func testWeightTrendStable() {
        let now = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let result = InsightsCalculator.weightTrend(
            entries: [
                (date: threeDaysAgo, weightKg: 80.0),
                (date: now, weightKg: 80.1),
            ],
            unit: .kg,
            referenceDate: now
        )
        XCTAssertEqual(result.trend, .stable)
    }

    func testWeightTrendIgnoresOldEntries() {
        let now = Date()
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        let result = InsightsCalculator.weightTrend(
            entries: [
                (date: tenDaysAgo, weightKg: 80.0),
                (date: now, weightKg: 90.0),
            ],
            unit: .kg,
            referenceDate: now
        )
        // Only the recent entry (now) is within 7 days, so not enough data
        XCTAssertEqual(result.trend, .notEnoughData)
    }

    func testWeightTrendLbsConversion() {
        let now = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let result = InsightsCalculator.weightTrend(
            entries: [
                (date: threeDaysAgo, weightKg: 80.0),
                (date: now, weightKg: 81.0),
            ],
            unit: .lbs,
            referenceDate: now
        )
        XCTAssertEqual(result.trend, .up)
        // 1 kg = ~2.2 lbs
        XCTAssertEqual(result.changeAmount!, 2.20462, accuracy: 0.01)
    }
}
