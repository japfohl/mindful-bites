import XCTest
@testable import MindfulBites

final class DateExtensionsTests: XCTestCase {

    func testDaysBetweenSameDay() {
        let date = Date()
        XCTAssertEqual(date.daysBetween(date), 0)
    }

    func testDaysBetweenOneDayApart() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        XCTAssertEqual(today.daysBetween(yesterday), 1)
    }

    func testDaysBetweenIsSymmetric() {
        let a = Date()
        let b = Calendar.current.date(byAdding: .day, value: -5, to: a)!
        XCTAssertEqual(a.daysBetween(b), b.daysBetween(a))
    }

    func testDaysBetweenWeek() {
        let today = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        XCTAssertEqual(today.daysBetween(weekAgo), 7)
    }

    func testIsToday() {
        XCTAssertTrue(Date().isToday)
    }

    func testIsTodayFalseForYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }

    func testIsYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday.isYesterday)
    }

    func testIsYesterdayFalseForToday() {
        XCTAssertFalse(Date().isYesterday)
    }

    func testStartOfDay() {
        let now = Date()
        let startOfDay = now.startOfDay
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: startOfDay)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testStartOfDayPreservesDate() {
        let now = Date()
        let startOfDay = now.startOfDay
        XCTAssertTrue(Calendar.current.isDate(now, inSameDayAs: startOfDay))
    }

    func testTimelineSectionHeaderToday() {
        XCTAssertEqual(Date().timelineSectionHeader, "Today")
    }

    func testTimelineSectionHeaderYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertEqual(yesterday.timelineSectionHeader, "Yesterday")
    }

    func testTimelineSectionHeaderOlderDateSameYear() {
        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!

        if calendar.isDate(threeDaysAgo, equalTo: Date(), toGranularity: .year) {
            let header = threeDaysAgo.timelineSectionHeader
            XCTAssertNotEqual(header, "Today")
            XCTAssertNotEqual(header, "Yesterday")
            // Should not contain the year for same-year dates
            let yearString = String(calendar.component(.year, from: threeDaysAgo))
            XCTAssertFalse(header.contains(yearString))
        }
    }
}
