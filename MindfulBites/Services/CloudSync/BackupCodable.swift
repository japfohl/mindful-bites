import Foundation

// MARK: - DTOs

struct TagDTO: Codable, Equatable {
    let id: UUID
    let name: String
}

struct FoodEntryDTO: Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let title: String
    let text: String?
    let photoFileName: String?
    let mealType: String?
    let tagIDs: [UUID]
}

struct WeightEntryDTO: Codable, Equatable {
    let id: UUID
    let date: Date
    let weight: Double
    let notes: String?
}

struct SettingsDTO: Codable, Equatable {
    let weightUnit: String
    let reminderEnabled: Bool
    let reminderHour: Int
    let reminderMinute: Int
    let mealTimeRanges: MealTimeRanges
}

// MARK: - Manifest

struct BackupManifest: Codable, Equatable, Identifiable {
    let version: Int
    let createdAt: Date
    let appVersion: String
    let deviceName: String
    let foodEntryCount: Int
    let weightEntryCount: Int
    let tagCount: Int
    let photoFileNames: [String]

    var id: Date { createdAt }

    static let currentVersion = 1
}

// MARK: - Full Backup

struct BackupData: Codable, Equatable {
    let manifest: BackupManifest
    let tags: [TagDTO]
    let foodEntries: [FoodEntryDTO]
    let weightEntries: [WeightEntryDTO]
    let settings: SettingsDTO
}

// MARK: - Model Extensions

extension Tag {
    func toDTO() -> TagDTO {
        TagDTO(id: id, name: name)
    }
}

extension FoodEntry {
    func toDTO() -> FoodEntryDTO {
        FoodEntryDTO(
            id: id,
            createdAt: createdAt,
            title: title,
            text: text,
            photoFileName: photoFileName,
            mealType: mealType?.rawValue,
            tagIDs: tags.map(\.id)
        )
    }
}

extension WeightEntry {
    func toDTO() -> WeightEntryDTO {
        WeightEntryDTO(
            id: id,
            date: date,
            weight: weight,
            notes: notes
        )
    }
}

extension SettingsService {
    func toDTO() -> SettingsDTO {
        SettingsDTO(
            weightUnit: weightUnit.rawValue,
            reminderEnabled: weightReminderEnabled,
            reminderHour: weightReminderHour,
            reminderMinute: weightReminderMinute,
            mealTimeRanges: mealTimeRanges
        )
    }

    func apply(dto: SettingsDTO) {
        if let unit = WeightUnit(rawValue: dto.weightUnit) {
            weightUnit = unit
        }
        weightReminderEnabled = dto.reminderEnabled
        weightReminderHour = dto.reminderHour
        weightReminderMinute = dto.reminderMinute
        mealTimeRanges = dto.mealTimeRanges
    }
}
