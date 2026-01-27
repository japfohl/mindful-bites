import Foundation
import SwiftData

@Model
class FoodEntry {
    var id: UUID
    var createdAt: Date
    var text: String?
    var photoFileName: String?
    var mealType: MealType?
    var tags: [Tag]

    init(
        text: String? = nil,
        photoFileName: String? = nil,
        mealType: MealType? = nil,
        tags: [Tag] = []
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.text = text
        self.photoFileName = photoFileName
        self.mealType = mealType
        self.tags = tags
    }

    var hasPhoto: Bool {
        photoFileName != nil && !photoFileName!.isEmpty
    }

    var hasText: Bool {
        text != nil && !text!.isEmpty
    }
}
