import XCTest
@testable import MindfulBites

final class MealTypeTests: XCTestCase {

    private var mockSettings: MockSettingsService!

    override func setUp() {
        super.setUp()
        mockSettings = MockSettingsService()
    }

    func testSuggestedBreakfastTime() {
        let date = makeDate(hour: 7, minute: 0)
        let result = MealType.suggested(for: date, using: mockSettings)
        XCTAssertEqual(result, .breakfast)
    }

    func testSuggestedLunchTime() {
        let date = makeDate(hour: 12, minute: 0)
        let result = MealType.suggested(for: date, using: mockSettings)
        XCTAssertEqual(result, .lunch)
    }

    func testSuggestedDinnerTime() {
        let date = makeDate(hour: 18, minute: 0)
        let result = MealType.suggested(for: date, using: mockSettings)
        XCTAssertEqual(result, .dinner)
    }

    func testSuggestedSnackTime() {
        let date = makeDate(hour: 3, minute: 0)
        let result = MealType.suggested(for: date, using: mockSettings)
        XCTAssertEqual(result, .snack)
    }

    func testSuggestedBetweenMealsIsSnack() {
        // 9:00 AM - between breakfast (6-8) and lunch (11-13)
        let date = makeDate(hour: 9, minute: 0)
        let result = MealType.suggested(for: date, using: mockSettings)
        XCTAssertEqual(result, .snack)
    }

    func testSuggestedBreakfastStartBoundary() {
        let date = makeDate(hour: 6, minute: 0)
        let result = MealType.suggested(for: date, using: mockSettings)
        XCTAssertEqual(result, .breakfast)
    }

    func testSuggestedBreakfastEndBoundary() {
        // 8:00 is exclusive end for breakfast
        let date = makeDate(hour: 8, minute: 0)
        let result = MealType.suggested(for: date, using: mockSettings)
        XCTAssertEqual(result, .snack)
    }

    func testSuggestedWithCustomRanges() {
        mockSettings.mealTimeRanges = MealTimeRanges(
            breakfast: MealTimeRange(startHour: 5, startMinute: 0, endHour: 10, endMinute: 0),
            lunch: MealTimeRange(startHour: 12, startMinute: 0, endHour: 14, endMinute: 0),
            dinner: MealTimeRange(startHour: 18, startMinute: 0, endHour: 21, endMinute: 0)
        )

        // 9:00 is now breakfast with custom ranges
        let date = makeDate(hour: 9, minute: 0)
        let result = MealType.suggested(for: date, using: mockSettings)
        XCTAssertEqual(result, .breakfast)
    }

    func testDisplayNames() {
        XCTAssertEqual(MealType.breakfast.displayName, "Breakfast")
        XCTAssertEqual(MealType.lunch.displayName, "Lunch")
        XCTAssertEqual(MealType.dinner.displayName, "Dinner")
        XCTAssertEqual(MealType.snack.displayName, "Snack")
    }

    func testIcons() {
        XCTAssertEqual(MealType.breakfast.icon, "sunrise")
        XCTAssertEqual(MealType.lunch.icon, "sun.max")
        XCTAssertEqual(MealType.dinner.icon, "moon")
        XCTAssertEqual(MealType.snack.icon, "leaf")
    }

    func testCodable() throws {
        for mealType in MealType.allCases {
            let data = try JSONEncoder().encode(mealType)
            let decoded = try JSONDecoder().decode(MealType.self, from: data)
            XCTAssertEqual(decoded, mealType)
        }
    }

    // MARK: - Helpers

    private func makeDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components)!
    }
}

// MARK: - Mock

private class MockSettingsService: SettingsServiceProtocol {
    var weightUnit: WeightUnit = .lbs
    var weightReminderEnabled: Bool = false
    var weightReminderHour: Int = 8
    var weightReminderMinute: Int = 0
    var weightReminderTime: Date = Date()
    var mealTimeRanges: MealTimeRanges = .defaults
    func resetMealTimeRangesToDefaults() { mealTimeRanges = .defaults }
}
