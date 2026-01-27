import Foundation
import SwiftData

@Model
class FoodEntry {
    var id: UUID
    var createdAt: Date
    var title: String
    var text: String?
    var photoFileName: String?
    var mealType: MealType?
    var tags: [Tag]

    init(
        title: String? = nil,
        text: String? = nil,
        photoFileName: String? = nil,
        mealType: MealType? = nil,
        tags: [Tag] = [],
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.title = title ?? Self.defaultTitle(for: createdAt)
        self.text = text
        self.photoFileName = photoFileName
        self.mealType = mealType ?? MealType.suggested(for: createdAt)
        self.tags = tags
    }

    var hasPhoto: Bool {
        photoFileName != nil && !photoFileName!.isEmpty
    }

    var hasText: Bool {
        text != nil && !text!.isEmpty
    }

    /// Generates a default title based on the timestamp
    static func defaultTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a, MMM d"
        return formatter.string(from: date)
    }
}
