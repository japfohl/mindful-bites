import XCTest
@testable import MindfulBites

final class SettingsServiceTests: XCTestCase {

    private var sut: SettingsService!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SettingsServiceTests_\(UUID().uuidString)")!
        sut = SettingsService(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: defaults.description)
        defaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Weight Unit

    func testWeightUnitDefaultsToLbs() {
        XCTAssertEqual(sut.weightUnit, .lbs)
    }

    func testWeightUnitPersists() {
        sut.weightUnit = .kg
        let fresh = SettingsService(defaults: defaults)
        XCTAssertEqual(fresh.weightUnit, .kg)
    }

    func testWeightUnitSetAndGet() {
        sut.weightUnit = .kg
        XCTAssertEqual(sut.weightUnit, .kg)
        sut.weightUnit = .lbs
        XCTAssertEqual(sut.weightUnit, .lbs)
    }

    // MARK: - Weight Reminder

    func testWeightReminderEnabledDefaultsFalse() {
        XCTAssertFalse(sut.weightReminderEnabled)
    }

    func testWeightReminderEnabledPersists() {
        sut.weightReminderEnabled = true
        let fresh = SettingsService(defaults: defaults)
        XCTAssertTrue(fresh.weightReminderEnabled)
    }

    func testWeightReminderHourDefaultsTo8() {
        XCTAssertEqual(sut.weightReminderHour, 8)
    }

    func testWeightReminderHourPersists() {
        sut.weightReminderHour = 10
        let fresh = SettingsService(defaults: defaults)
        XCTAssertEqual(fresh.weightReminderHour, 10)
    }

    func testWeightReminderMinuteDefaultsTo0() {
        XCTAssertEqual(sut.weightReminderMinute, 0)
    }

    func testWeightReminderMinutePersists() {
        sut.weightReminderMinute = 30
        let fresh = SettingsService(defaults: defaults)
        XCTAssertEqual(fresh.weightReminderMinute, 30)
    }

    // MARK: - Meal Time Ranges

    func testMealTimeRangesDefaults() {
        XCTAssertEqual(sut.mealTimeRanges, MealTimeRanges.defaults)
    }

    func testMealTimeRangesPersists() {
        let custom = MealTimeRanges(
            breakfast: MealTimeRange(startHour: 5, startMinute: 0, endHour: 9, endMinute: 0),
            lunch: MealTimeRange(startHour: 11, startMinute: 30, endHour: 13, endMinute: 30),
            dinner: MealTimeRange(startHour: 17, startMinute: 0, endHour: 20, endMinute: 0)
        )
        sut.mealTimeRanges = custom

        let fresh = SettingsService(defaults: defaults)
        XCTAssertEqual(fresh.mealTimeRanges, custom)
    }

    func testResetMealTimeRangesToDefaults() {
        let custom = MealTimeRanges(
            breakfast: MealTimeRange(startHour: 5, startMinute: 0, endHour: 9, endMinute: 0),
            lunch: MealTimeRange(startHour: 11, startMinute: 30, endHour: 13, endMinute: 30),
            dinner: MealTimeRange(startHour: 17, startMinute: 0, endHour: 20, endMinute: 0)
        )
        sut.mealTimeRanges = custom
        sut.resetMealTimeRangesToDefaults()
        XCTAssertEqual(sut.mealTimeRanges, MealTimeRanges.defaults)
    }
}
