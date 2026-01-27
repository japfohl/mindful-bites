import Foundation
import SwiftData

@Model
class Tag {
    var id: UUID
    var name: String
    @Relationship(inverse: \FoodEntry.tags) var entries: [FoodEntry]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.entries = []
    }
}
