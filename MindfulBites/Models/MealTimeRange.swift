import Foundation

/// Represents a time range for a meal type (start and end in minutes from midnight)
struct MealTimeRange: Codable, Equatable {
    var startMinutes: Int
    var endMinutes: Int

    init(startMinutes: Int, endMinutes: Int) {
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
    }

    init(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        self.startMinutes = startHour * 60 + startMinute
        self.endMinutes = endHour * 60 + endMinute
    }

    var startDate: Date {
        get {
            Calendar.current.date(bySettingHour: startMinutes / 60, minute: startMinutes % 60, second: 0, of: Date()) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            startMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        }
    }

    var endDate: Date {
        get {
            Calendar.current.date(bySettingHour: endMinutes / 60, minute: endMinutes % 60, second: 0, of: Date()) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            endMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        }
    }

    func contains(timeInMinutes: Int) -> Bool {
        timeInMinutes >= startMinutes && timeInMinutes < endMinutes
    }
}

/// Collection of meal time ranges for all meal types
struct MealTimeRanges: Codable, Equatable {
    var breakfast: MealTimeRange
    var lunch: MealTimeRange
    var dinner: MealTimeRange

    static let defaults = MealTimeRanges(
        breakfast: MealTimeRange(startHour: 6, startMinute: 0, endHour: 8, endMinute: 0),
        lunch: MealTimeRange(startHour: 11, startMinute: 0, endHour: 13, endMinute: 0),
        dinner: MealTimeRange(startHour: 16, startMinute: 30, endHour: 19, endMinute: 30)
    )
}
