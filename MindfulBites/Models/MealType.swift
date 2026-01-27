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
    /// Default ranges (will be customizable in settings later):
    /// - Breakfast: 6:00 AM - 8:00 AM
    /// - Lunch: 11:00 AM - 1:00 PM
    /// - Dinner: 4:00 PM - 7:30 PM
    /// - Snack: All other times
    static func suggested(for date: Date) -> MealType {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let timeInMinutes = hour * 60 + minute

        // Breakfast: 6:00 AM (360) - 8:00 AM (480)
        if timeInMinutes >= 360 && timeInMinutes < 480 {
            return .breakfast
        }
        // Lunch: 11:00 AM (660) - 1:00 PM (780)
        if timeInMinutes >= 660 && timeInMinutes < 780 {
            return .lunch
        }
        // Dinner: 4:00 PM (960) - 7:30 PM (1110)
        if timeInMinutes >= 960 && timeInMinutes < 1110 {
            return .dinner
        }
        // All other times
        return .snack
    }
}
