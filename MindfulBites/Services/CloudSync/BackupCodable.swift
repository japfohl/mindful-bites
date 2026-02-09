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
    let weightUnit: WeightUnit
    let reminderEnabled: Bool
    let reminderHour: Int
    let reminderMinute: Int
    let mealTimeRanges: MealTimeRanges
}

// MARK: - Manifest

struct BackupManifest: Codable, Equatable, Identifiable {
    let id: UUID
    let version: Int
    let createdAt: Date
    let appVersion: String
    let deviceName: String
    let foodEntryCount: Int
    let weightEntryCount: Int
    let tagCount: Int
    let photoFileNames: [String]
    let backupFileName: String?

    var resolvedBackupFileName: String {
        if let name = backupFileName { return name }
        let formatter = ISO8601DateFormatter()
        return "backup_\(formatter.string(from: createdAt)).json"
    }

    static let currentVersion = 1

    init(id: UUID = UUID(), version: Int, createdAt: Date, appVersion: String, deviceName: String, foodEntryCount: Int, weightEntryCount: Int, tagCount: Int, photoFileNames: [String], backupFileName: String? = nil) {
        self.id = id
        self.version = version
        self.createdAt = createdAt
        self.appVersion = appVersion
        self.deviceName = deviceName
        self.foodEntryCount = foodEntryCount
        self.weightEntryCount = weightEntryCount
        self.tagCount = tagCount
        self.photoFileNames = photoFileNames
        self.backupFileName = backupFileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.version = try container.decode(Int.self, forKey: .version)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.appVersion = try container.decode(String.self, forKey: .appVersion)
        self.deviceName = try container.decode(String.self, forKey: .deviceName)
        self.foodEntryCount = try container.decode(Int.self, forKey: .foodEntryCount)
        self.weightEntryCount = try container.decode(Int.self, forKey: .weightEntryCount)
        self.tagCount = try container.decode(Int.self, forKey: .tagCount)
        self.photoFileNames = try container.decode([String].self, forKey: .photoFileNames)
        self.backupFileName = try? container.decode(String.self, forKey: .backupFileName)
    }
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
            weightUnit: weightUnit,
            reminderEnabled: weightReminderEnabled,
            reminderHour: weightReminderHour,
            reminderMinute: weightReminderMinute,
            mealTimeRanges: mealTimeRanges
        )
    }

    func apply(dto: SettingsDTO) {
        weightUnit = dto.weightUnit
        weightReminderEnabled = dto.reminderEnabled
        weightReminderHour = dto.reminderHour
        weightReminderMinute = dto.reminderMinute
        mealTimeRanges = dto.mealTimeRanges
    }
}
