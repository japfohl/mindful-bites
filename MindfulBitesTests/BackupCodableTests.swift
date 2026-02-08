import XCTest
@testable import MindfulBites

final class BackupCodableTests: XCTestCase {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// Creates a Date with second precision (no sub-second component)
    /// so ISO8601 round-trips produce equal values.
    private func stableDate(_ offset: TimeInterval = 0) -> Date {
        Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970) + offset)
    }

    // MARK: - TagDTO

    func testTagDTORoundTrip() throws {
        let tag = TagDTO(id: UUID(), name: "Healthy")
        let data = try encoder.encode(tag)
        let decoded = try decoder.decode(TagDTO.self, from: data)
        XCTAssertEqual(decoded, tag)
    }

    // MARK: - FoodEntryDTO

    func testFoodEntryDTORoundTrip() throws {
        let entry = FoodEntryDTO(
            id: UUID(),
            createdAt: stableDate(),
            title: "Breakfast",
            text: "Oatmeal and berries",
            photoFileName: "food_abc_123.jpg",
            mealType: "breakfast",
            tagIDs: [UUID(), UUID()]
        )
        let data = try encoder.encode(entry)
        let decoded = try decoder.decode(FoodEntryDTO.self, from: data)
        XCTAssertEqual(decoded, entry)
    }

    func testFoodEntryDTOWithNilFields() throws {
        let entry = FoodEntryDTO(
            id: UUID(),
            createdAt: stableDate(),
            title: "Quick entry",
            text: nil,
            photoFileName: nil,
            mealType: nil,
            tagIDs: []
        )
        let data = try encoder.encode(entry)
        let decoded = try decoder.decode(FoodEntryDTO.self, from: data)
        XCTAssertEqual(decoded, entry)
        XCTAssertNil(decoded.text)
        XCTAssertNil(decoded.photoFileName)
        XCTAssertNil(decoded.mealType)
    }

    // MARK: - WeightEntryDTO

    func testWeightEntryDTORoundTrip() throws {
        let entry = WeightEntryDTO(
            id: UUID(),
            date: stableDate(),
            weight: 80.5,
            notes: "Morning weigh-in"
        )
        let data = try encoder.encode(entry)
        let decoded = try decoder.decode(WeightEntryDTO.self, from: data)
        XCTAssertEqual(decoded, entry)
    }

    // MARK: - SettingsDTO

    func testSettingsDTORoundTrip() throws {
        let dto = SettingsDTO(
            weightUnit: "kg",
            reminderEnabled: true,
            reminderHour: 8,
            reminderMinute: 30,
            mealTimeRanges: .defaults
        )
        let data = try encoder.encode(dto)
        let decoded = try decoder.decode(SettingsDTO.self, from: data)
        XCTAssertEqual(decoded, dto)
    }

    // MARK: - BackupManifest

    func testBackupManifestRoundTrip() throws {
        let manifest = BackupManifest(
            version: 1,
            createdAt: stableDate(),
            appVersion: "1.0",
            deviceName: "Test iPhone",
            foodEntryCount: 10,
            weightEntryCount: 5,
            tagCount: 3,
            photoFileNames: ["photo1.jpg", "photo2.jpg"]
        )
        let data = try encoder.encode(manifest)
        let decoded = try decoder.decode(BackupManifest.self, from: data)
        XCTAssertEqual(decoded, manifest)
    }

    // MARK: - Full BackupData

    func testFullBackupDataRoundTrip() throws {
        let tagID1 = UUID()
        let tagID2 = UUID()
        let now = stableDate()

        let backupData = BackupData(
            manifest: BackupManifest(
                version: 1,
                createdAt: now,
                appVersion: "1.0",
                deviceName: "Test",
                foodEntryCount: 2,
                weightEntryCount: 1,
                tagCount: 2,
                photoFileNames: ["photo1.jpg"]
            ),
            tags: [
                TagDTO(id: tagID1, name: "Healthy"),
                TagDTO(id: tagID2, name: "Quick"),
            ],
            foodEntries: [
                FoodEntryDTO(
                    id: UUID(),
                    createdAt: now,
                    title: "Breakfast",
                    text: "Eggs",
                    photoFileName: "photo1.jpg",
                    mealType: "breakfast",
                    tagIDs: [tagID1, tagID2]
                ),
                FoodEntryDTO(
                    id: UUID(),
                    createdAt: stableDate(-3600),
                    title: "Lunch",
                    text: nil,
                    photoFileName: nil,
                    mealType: "lunch",
                    tagIDs: [tagID1]
                ),
            ],
            weightEntries: [
                WeightEntryDTO(id: UUID(), date: now, weight: 80.0, notes: nil),
            ],
            settings: SettingsDTO(
                weightUnit: "lbs",
                reminderEnabled: false,
                reminderHour: 8,
                reminderMinute: 0,
                mealTimeRanges: .defaults
            )
        )

        let data = try encoder.encode(backupData)
        let decoded = try decoder.decode(BackupData.self, from: data)
        XCTAssertEqual(decoded, backupData)
        XCTAssertEqual(decoded.tags.count, 2)
        XCTAssertEqual(decoded.foodEntries.count, 2)
        XCTAssertEqual(decoded.foodEntries[0].tagIDs, [tagID1, tagID2])
    }
}
