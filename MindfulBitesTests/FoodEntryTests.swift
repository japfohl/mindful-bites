import XCTest
@testable import MindfulBites

final class FoodEntryTests: XCTestCase {

    func testDefaultTitleContainsTimeAndDate() {
        let date = Date()
        let title = FoodEntry.defaultTitle(for: date)
        // Format: "h:mm a, MMM d"
        XCTAssertFalse(title.isEmpty)
    }

    func testDefaultTitleForSpecificDate() {
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 15
        components.hour = 14
        components.minute = 30
        let date = Calendar.current.date(from: components)!
        let title = FoodEntry.defaultTitle(for: date)
        XCTAssertTrue(title.contains("2:30"))
        XCTAssertTrue(title.contains("Mar"))
        XCTAssertTrue(title.contains("15"))
    }

    func testDefaultTitleMorning() {
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 1
        components.hour = 8
        components.minute = 0
        let date = Calendar.current.date(from: components)!
        let title = FoodEntry.defaultTitle(for: date)
        XCTAssertTrue(title.contains("8:00"))
        XCTAssertTrue(title.contains("AM"))
    }
}
