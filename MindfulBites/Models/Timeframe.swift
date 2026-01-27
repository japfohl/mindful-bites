import Foundation

enum Timeframe: String, CaseIterable, Identifiable {
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case oneYear = "1Y"
    case all = "All"

    var id: String { rawValue }

    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .oneWeek:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: now)
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now)
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .all:
            return nil
        }
    }
}
