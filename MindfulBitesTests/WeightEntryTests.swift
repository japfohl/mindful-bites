import XCTest
import SwiftData
@testable import MindfulBites

@MainActor
final class WeightEntryTests: XCTestCase {

    func testCalendarDayIsStartOfDay() throws {
        let container = try ModelContainer(
            for: WeightEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 14
        components.minute = 30
        let date = Calendar.current.date(from: components)!

        let entry = WeightEntry(date: date, weight: 80.0)
        context.insert(entry)

        let calendarDay = entry.calendarDay
        let dayComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: calendarDay)
        XCTAssertEqual(dayComponents.hour, 0)
        XCTAssertEqual(dayComponents.minute, 0)
        XCTAssertEqual(dayComponents.second, 0)
        XCTAssertTrue(Calendar.current.isDate(calendarDay, inSameDayAs: date))
    }

    func testWeightEntryInitialization() throws {
        let container = try ModelContainer(
            for: WeightEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let entry = WeightEntry(weight: 75.5, notes: "Morning")
        context.insert(entry)

        XCTAssertEqual(entry.weight, 75.5)
        XCTAssertEqual(entry.notes, "Morning")
        XCTAssertNotNil(entry.id)
    }
}
