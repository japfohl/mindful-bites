import Foundation
import SwiftData

@Model
class WeightEntry {
    var id: UUID
    var date: Date
    var weight: Double
    var notes: String?

    init(date: Date = Date(), weight: Double, notes: String? = nil) {
        self.id = UUID()
        self.date = date
        self.weight = weight
        self.notes = notes
    }

    var calendarDay: Date {
        Calendar.current.startOfDay(for: date)
    }
}
