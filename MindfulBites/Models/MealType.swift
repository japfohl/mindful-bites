import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snack: return "leaf"
        }
    }

    /// Suggests a meal type based on the time of day.
    /// Uses customizable time ranges from SettingsService.
    /// - Breakfast, Lunch, Dinner: Within configured time ranges
    /// - Snack: All other times
    static func suggested(for date: Date, using settings: SettingsServiceProtocol = SettingsService.shared) -> MealType {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let timeInMinutes = hour * 60 + minute

        let ranges = settings.mealTimeRanges

        if ranges.breakfast.contains(timeInMinutes: timeInMinutes) {
            return .breakfast
        }
        if ranges.lunch.contains(timeInMinutes: timeInMinutes) {
            return .lunch
        }
        if ranges.dinner.contains(timeInMinutes: timeInMinutes) {
            return .dinner
        }

        return .snack
    }
}
