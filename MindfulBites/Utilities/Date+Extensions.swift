import Foundation

extension Date {
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
