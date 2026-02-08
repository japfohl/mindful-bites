import Foundation

extension Date {
    /// Returns the number of calendar days between this date and another date
    func daysBetween(_ other: Date) -> Int {
        let calendar = Calendar.current
        let startOfSelf = calendar.startOfDay(for: self)
        let startOfOther = calendar.startOfDay(for: other)
        let components = calendar.dateComponents([.day], from: startOfSelf, to: startOfOther)
        return abs(components.day ?? 0)
    }
    /// Returns true if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Returns true if this date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Returns the start of the calendar day for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Formats the date as a section header for timeline grouping
    var timelineSectionHeader: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year) {
            return formatted(.dateTime.weekday(.wide).month().day())
        } else {
            return formatted(.dateTime.weekday(.wide).month().day().year())
        }
    }
}
