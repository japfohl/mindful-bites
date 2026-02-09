import Foundation
import SwiftUI

protocol SettingsServiceProtocol {
    var weightUnit: WeightUnit { get set }
    var weightReminderEnabled: Bool { get set }
    var weightReminderHour: Int { get set }
    var weightReminderMinute: Int { get set }
    var weightReminderTime: Date { get set }
    var mealTimeRanges: MealTimeRanges { get set }
    func resetMealTimeRangesToDefaults()
}

@Observable
final class SettingsService: SettingsServiceProtocol {
    static let shared = SettingsService()

    private let defaults: UserDefaults

    // MARK: - Keys
    private enum Keys {
        static let weightUnit = "weightUnit"
        static let weightReminderEnabled = "weightReminderEnabled"
        static let weightReminderHour = "weightReminderHour"
        static let weightReminderMinute = "weightReminderMinute"
        static let mealTimeRanges = "mealTimeRanges"
        static let weightReminderHourSet = "weightReminderHourSet"
    }

    // MARK: - Weight Unit
    var weightUnit: WeightUnit {
        get {
            guard let rawValue = defaults.string(forKey: Keys.weightUnit),
                  let unit = WeightUnit(rawValue: rawValue) else {
                return .lbs
            }
            return unit
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.weightUnit)
        }
    }

    // MARK: - Weight Reminder
    var weightReminderEnabled: Bool {
        get { defaults.bool(forKey: Keys.weightReminderEnabled) }
        set { defaults.set(newValue, forKey: Keys.weightReminderEnabled) }
    }

    var weightReminderHour: Int {
        get {
            if defaults.bool(forKey: Keys.weightReminderHourSet) {
                return defaults.integer(forKey: Keys.weightReminderHour)
            }
            return 8 // Default to 8 AM when never set
        }
        set {
            defaults.set(newValue, forKey: Keys.weightReminderHour)
            defaults.set(true, forKey: Keys.weightReminderHourSet)
        }
    }

    var weightReminderMinute: Int {
        get { defaults.integer(forKey: Keys.weightReminderMinute) }
        set { defaults.set(newValue, forKey: Keys.weightReminderMinute) }
    }

    var weightReminderTime: Date {
        get {
            Calendar.current.date(bySettingHour: weightReminderHour, minute: weightReminderMinute, second: 0, of: Date()) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            weightReminderHour = components.hour ?? 8
            weightReminderMinute = components.minute ?? 0
        }
    }

    // MARK: - Meal Time Ranges
    var mealTimeRanges: MealTimeRanges {
        get {
            guard let data = defaults.data(forKey: Keys.mealTimeRanges),
                  let ranges = try? JSONDecoder().decode(MealTimeRanges.self, from: data) else {
                return .defaults
            }
            return ranges
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.mealTimeRanges)
            }
        }
    }

    func resetMealTimeRangesToDefaults() {
        mealTimeRanges = .defaults
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}
