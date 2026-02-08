import XCTest
import SwiftData
@testable import MindfulBites

@MainActor
final class BackupServiceTests: XCTestCase {

    private var sut: BackupService!
    private var mockProvider: MockCloudStorageProvider!
    private var container: ModelContainer!
    private var context: ModelContext!
    private var settings: SettingsService!
    private var photoService: PhotoStorageService!
    private var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        sut = BackupService()
        mockProvider = MockCloudStorageProvider()
        container = try ModelContainer(
            for: FoodEntry.self, WeightEntry.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        settings = SettingsService(defaults: UserDefaults(suiteName: "BackupTest_\(UUID().uuidString)")!)
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        photoService = PhotoStorageService(photosDirectory: tempDir)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }

    // MARK: - Backup

    func testBackupCreatesFilesInProvider() async throws {
        // Seed data
        let tag = Tag(name: "Test")
        context.insert(tag)
        let entry = FoodEntry(title: "Lunch", text: "Salad", mealType: .lunch, tags: [tag])
        context.insert(entry)
        let weight = WeightEntry(weight: 80.0)
        context.insert(weight)

        try await sut.performBackup(
            modelContext: context,
            provider: mockProvider,
            settings: settings,
            photoService: photoService
        )

        // Should have uploaded backup JSON + manifest
        XCTAssertGreaterThanOrEqual(mockProvider.uploadCallCount, 2)
        XCTAssertEqual(sut.syncState, .idle)
        XCTAssertNotNil(sut.lastBackupDate)
    }

    func testBackupRequiresAuth() async {
        mockProvider.authState = .signedOut

        do {
            try await sut.performBackup(
                modelContext: context,
                provider: mockProvider,
                settings: settings,
                photoService: photoService
            )
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is CloudStorageError)
        }
    }

    func testBackupUploadsPhotos() async throws {
        // Create a test photo
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        let filename = photoService.savePhoto(image)!

        let entry = FoodEntry(title: "Photo entry", photoFileName: filename)
        context.insert(entry)

        try await sut.performBackup(
            modelContext: context,
            provider: mockProvider,
            settings: settings,
            photoService: photoService
        )

        // Should have uploaded: 1 photo + 1 backup JSON + 1 manifest = 3
        XCTAssertEqual(mockProvider.uploadCallCount, 3)
    }

    // MARK: - Backup + Restore Round Trip

    func testBackupAndRestoreRoundTrip() async throws {
        // Seed data
        let tag1 = Tag(name: "Healthy")
        let tag2 = Tag(name: "Quick")
        context.insert(tag1)
        context.insert(tag2)

        let food1 = FoodEntry(title: "Breakfast", text: "Eggs", mealType: .breakfast, tags: [tag1, tag2])
        let food2 = FoodEntry(title: "Lunch", text: nil, mealType: .lunch, tags: [tag1])
        context.insert(food1)
        context.insert(food2)

        let weight1 = WeightEntry(weight: 80.0, notes: "Morning")
        context.insert(weight1)

        settings.weightUnit = .kg
        settings.weightReminderEnabled = true
        settings.weightReminderHour = 7
        settings.weightReminderMinute = 15

        // Backup
        try await sut.performBackup(
            modelContext: context,
            provider: mockProvider,
            settings: settings,
            photoService: photoService
        )

        // Find backup filename
        let backupFolderID = mockProvider.folders[".mindfulBites/backups"]!
        let backupFiles = try await mockProvider.listFiles(inFolder: backupFolderID)
        let backupFileName = backupFiles.first!.name

        // Clear local data
        let existingFood = try context.fetch(FetchDescriptor<FoodEntry>())
        for entry in existingFood { context.delete(entry) }
        let existingWeight = try context.fetch(FetchDescriptor<WeightEntry>())
        for entry in existingWeight { context.delete(entry) }
        let existingTags = try context.fetch(FetchDescriptor<Tag>())
        for tag in existingTags { context.delete(tag) }
        try context.save()

        // Create new settings instance
        let restoreSettings = SettingsService(defaults: UserDefaults(suiteName: "RestoreTest_\(UUID().uuidString)")!)

        // Restore
        try await sut.performRestore(
            modelContext: context,
            provider: mockProvider,
            backupFileName: backupFileName,
            settings: restoreSettings,
            photoService: photoService
        )

        // Verify data restored
        let restoredTags = try context.fetch(FetchDescriptor<Tag>())
        XCTAssertEqual(restoredTags.count, 2)

        let restoredFood = try context.fetch(FetchDescriptor<FoodEntry>())
        XCTAssertEqual(restoredFood.count, 2)

        let restoredWeight = try context.fetch(FetchDescriptor<WeightEntry>())
        XCTAssertEqual(restoredWeight.count, 1)
        XCTAssertEqual(restoredWeight[0].weight, 80.0)

        // Verify settings restored
        XCTAssertEqual(restoreSettings.weightUnit, .kg)
        XCTAssertTrue(restoreSettings.weightReminderEnabled)
        XCTAssertEqual(restoreSettings.weightReminderHour, 7)
        XCTAssertEqual(restoreSettings.weightReminderMinute, 15)
    }

    // MARK: - List Backups

    func testListBackups() async throws {
        // Do two backups
        let entry = FoodEntry(title: "Test")
        context.insert(entry)

        try await sut.performBackup(modelContext: context, provider: mockProvider, settings: settings, photoService: photoService)
        try await sut.performBackup(modelContext: context, provider: mockProvider, settings: settings, photoService: photoService)

        let manifests = try await sut.listBackups(provider: mockProvider)
        XCTAssertEqual(manifests.count, 2)
    }
}
