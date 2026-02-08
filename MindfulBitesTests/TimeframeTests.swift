import XCTest
@testable import MindfulBites

final class TimeframeTests: XCTestCase {

    func testOneWeekStartDate() {
        let startDate = Timeframe.oneWeek.startDate
        XCTAssertNotNil(startDate)
        let days = Calendar.current.dateComponents([.day], from: startDate!, to: Date()).day!
        XCTAssertEqual(days, 7, accuracy: 1)
    }

    func testOneMonthStartDate() {
        let startDate = Timeframe.oneMonth.startDate
        XCTAssertNotNil(startDate)
        let months = Calendar.current.dateComponents([.month], from: startDate!, to: Date()).month!
        XCTAssertEqual(months, 1)
    }

    func testThreeMonthsStartDate() {
        let startDate = Timeframe.threeMonths.startDate
        XCTAssertNotNil(startDate)
        let months = Calendar.current.dateComponents([.month], from: startDate!, to: Date()).month!
        XCTAssertEqual(months, 3)
    }

    func testOneYearStartDate() {
        let startDate = Timeframe.oneYear.startDate
        XCTAssertNotNil(startDate)
        let years = Calendar.current.dateComponents([.year], from: startDate!, to: Date()).year!
        XCTAssertEqual(years, 1)
    }

    func testAllStartDateIsNil() {
        XCTAssertNil(Timeframe.all.startDate)
    }

    func testAllCases() {
        XCTAssertEqual(Timeframe.allCases.count, 5)
    }

    func testRawValues() {
        XCTAssertEqual(Timeframe.oneWeek.rawValue, "1W")
        XCTAssertEqual(Timeframe.oneMonth.rawValue, "1M")
        XCTAssertEqual(Timeframe.threeMonths.rawValue, "3M")
        XCTAssertEqual(Timeframe.oneYear.rawValue, "1Y")
        XCTAssertEqual(Timeframe.all.rawValue, "All")
    }

    func testStartDatesAreInPast() {
        let now = Date()
        for timeframe in Timeframe.allCases {
            if let startDate = timeframe.startDate {
                XCTAssertTrue(startDate < now, "\(timeframe) startDate should be in the past")
            }
        }
    }
}

private func XCTAssertEqual(_ a: Int, _ b: Int, accuracy: Int, file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(abs(a - b) <= accuracy, "\(a) is not equal to \(b) within accuracy \(accuracy)", file: file, line: line)
}
