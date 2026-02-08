import XCTest
@testable import MindfulBites

final class MealTimeRangeTests: XCTestCase {

    func testContainsTimeInMinutes() {
        let range = MealTimeRange(startHour: 6, startMinute: 0, endHour: 8, endMinute: 0)
        XCTAssertTrue(range.contains(timeInMinutes: 360))  // 6:00
        XCTAssertTrue(range.contains(timeInMinutes: 420))  // 7:00
        XCTAssertFalse(range.contains(timeInMinutes: 480)) // 8:00 (exclusive end)
        XCTAssertFalse(range.contains(timeInMinutes: 359)) // 5:59
    }

    func testContainsBoundaryStart() {
        let range = MealTimeRange(startMinutes: 100, endMinutes: 200)
        XCTAssertTrue(range.contains(timeInMinutes: 100))
        XCTAssertFalse(range.contains(timeInMinutes: 99))
    }

    func testContainsBoundaryEnd() {
        let range = MealTimeRange(startMinutes: 100, endMinutes: 200)
        XCTAssertFalse(range.contains(timeInMinutes: 200))
        XCTAssertTrue(range.contains(timeInMinutes: 199))
    }

    func testInitWithHoursAndMinutes() {
        let range = MealTimeRange(startHour: 11, startMinute: 30, endHour: 13, endMinute: 15)
        XCTAssertEqual(range.startMinutes, 690)  // 11*60 + 30
        XCTAssertEqual(range.endMinutes, 795)    // 13*60 + 15
    }

    func testDefaultMealTimeRanges() {
        let defaults = MealTimeRanges.defaults

        // Breakfast: 6:00 - 8:00
        XCTAssertEqual(defaults.breakfast.startMinutes, 360)
        XCTAssertEqual(defaults.breakfast.endMinutes, 480)

        // Lunch: 11:00 - 13:00
        XCTAssertEqual(defaults.lunch.startMinutes, 660)
        XCTAssertEqual(defaults.lunch.endMinutes, 780)

        // Dinner: 16:30 - 19:30
        XCTAssertEqual(defaults.dinner.startMinutes, 990)
        XCTAssertEqual(defaults.dinner.endMinutes, 1170)
    }

    func testCodableRoundTrip() throws {
        let original = MealTimeRanges(
            breakfast: MealTimeRange(startHour: 7, startMinute: 0, endHour: 9, endMinute: 0),
            lunch: MealTimeRange(startHour: 12, startMinute: 0, endHour: 14, endMinute: 0),
            dinner: MealTimeRange(startHour: 18, startMinute: 0, endHour: 20, endMinute: 0)
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MealTimeRanges.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testEquatable() {
        let a = MealTimeRange(startMinutes: 100, endMinutes: 200)
        let b = MealTimeRange(startMinutes: 100, endMinutes: 200)
        let c = MealTimeRange(startMinutes: 100, endMinutes: 300)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
