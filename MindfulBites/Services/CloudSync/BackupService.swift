import Foundation
import SwiftData
import UIKit

@Observable
final class BackupService {
    static let shared = BackupService()

    private(set) var syncState: CloudSyncState = .idle
    private let maxBackups = 5
    private let backupFolderPath = ".mindfulBites/backups"
    private let photoFolderPath = ".mindfulBites/photos"
    private let manifestPath = ".mindfulBites"

    private let lastBackupDateKey = "lastBackupDate"

    var lastBackupDate: Date? {
        get { UserDefaults.standard.object(forKey: lastBackupDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastBackupDateKey) }
    }

    init() {}

    // MARK: - Backup

    @MainActor
    func performBackup(modelContext: ModelContext, provider: CloudStorageProvider, settings: SettingsService = .shared, photoService: PhotoStorageService = .shared) async throws {
        guard case .signedIn = provider.authState else {
            throw CloudStorageError.notAuthenticated
        }

        syncState = .syncing(progress: "Preparing backup...")

        // Fetch all data
        let foodEntries = try modelContext.fetch(FetchDescriptor<FoodEntry>())
        let weightEntries = try modelContext.fetch(FetchDescriptor<WeightEntry>())
        let tags = try modelContext.fetch(FetchDescriptor<Tag>())

        // Build DTOs
        let tagDTOs = tags.map { $0.toDTO() }
        let foodDTOs = foodEntries.map { $0.toDTO() }
        let weightDTOs = weightEntries.map { $0.toDTO() }
        let settingsDTO = settings.toDTO()

        let photoFileNames = foodEntries.compactMap(\.photoFileName)

        let manifest = BackupManifest(
            version: BackupManifest.currentVersion,
            createdAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            deviceName: UIDevice.current.name,
            foodEntryCount: foodEntries.count,
            weightEntryCount: weightEntries.count,
            tagCount: tags.count,
            photoFileNames: photoFileNames
        )

        let backupData = BackupData(
            manifest: manifest,
            tags: tagDTOs,
            foodEntries: foodDTOs,
            weightEntries: weightDTOs,
            settings: settingsDTO
        )

        // Encode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(backupData)

        // Ensure folders
        syncState = .syncing(progress: "Creating folders...")
        let backupFolderID = try await provider.ensureFolder(path: backupFolderPath)
        let photoFolderID = try await provider.ensureFolder(path: photoFolderPath)
        let manifestFolderID = try await provider.ensureFolder(path: manifestPath)

        // Upload photos
        if !photoFileNames.isEmpty {
            let existingPhotos = try await provider.listFiles(inFolder: photoFolderID)
            let existingNames = Set(existingPhotos.map(\.name))

            for (index, fileName) in photoFileNames.enumerated() {
                if existingNames.contains(fileName) { continue }

                syncState = .syncing(progress: "Uploading photo \(index + 1) of \(photoFileNames.count)...")

                let fileURL = photoService.photoFileURL(filename: fileName)
                if let data = try? Data(contentsOf: fileURL) {
                    _ = try await provider.uploadFile(
                        data: data,
                        fileName: fileName,
                        folderID: photoFolderID,
                        mimeType: "image/jpeg"
                    )
                }
            }
        }

        // Upload backup JSON
        syncState = .syncing(progress: "Uploading backup data...")
        let formatter = ISO8601DateFormatter()
        let backupFileName = "backup_\(formatter.string(from: manifest.createdAt)).json"
        _ = try await provider.uploadFile(
            data: jsonData,
            fileName: backupFileName,
            folderID: backupFolderID,
            mimeType: "application/json"
        )

        // Upload manifest for quick status checks
        let manifestData = try encoder.encode(manifest)
        // Delete existing manifest if present
        let existingManifests = try await provider.listFiles(inFolder: manifestFolderID)
        for file in existingManifests where file.name == "manifest.json" {
            try? await provider.deleteFile(fileID: file.id)
        }
        _ = try await provider.uploadFile(
            data: manifestData,
            fileName: "manifest.json",
            folderID: manifestFolderID,
            mimeType: "application/json"
        )

        // Prune old backups
        syncState = .syncing(progress: "Cleaning up old backups...")
        try await pruneOldBackups(provider: provider, folderID: backupFolderID)

        lastBackupDate = Date()
        syncState = .idle
    }

    // MARK: - List Backups

    func listBackups(provider: CloudStorageProvider) async throws -> [BackupManifest] {
        guard case .signedIn = provider.authState else {
            throw CloudStorageError.notAuthenticated
        }

        let backupFolderID = try await provider.ensureFolder(path: backupFolderPath)
        let files = try await provider.listFiles(inFolder: backupFolderID)
        let jsonFiles = files.filter { $0.name.hasSuffix(".json") }
            .sorted { ($0.modifiedDate ?? .distantPast) > ($1.modifiedDate ?? .distantPast) }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var manifests: [BackupManifest] = []
        for file in jsonFiles {
            if let data = try? await provider.downloadFile(fileID: file.id),
               let backupData = try? decoder.decode(BackupData.self, from: data) {
                manifests.append(backupData.manifest)
            }
        }

        return manifests
    }

    // MARK: - Restore

    @MainActor
    func performRestore(modelContext: ModelContext, provider: CloudStorageProvider, backupFileName: String, settings: SettingsService = .shared, photoService: PhotoStorageService = .shared) async throws {
        guard case .signedIn = provider.authState else {
            throw CloudStorageError.notAuthenticated
        }

        syncState = .syncing(progress: "Downloading backup...")

        // Find and download the backup file
        let backupFolderID = try await provider.ensureFolder(path: backupFolderPath)
        let files = try await provider.listFiles(inFolder: backupFolderID)
        guard let backupFile = files.first(where: { $0.name == backupFileName }) else {
            throw CloudStorageError.fileNotFound(backupFileName)
        }

        let data = try await provider.downloadFile(fileID: backupFile.id)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backupData = try decoder.decode(BackupData.self, from: data)

        // Delete all existing data
        syncState = .syncing(progress: "Clearing local data...")
        let existingFood = try modelContext.fetch(FetchDescriptor<FoodEntry>())
        for entry in existingFood { modelContext.delete(entry) }
        let existingWeight = try modelContext.fetch(FetchDescriptor<WeightEntry>())
        for entry in existingWeight { modelContext.delete(entry) }
        let existingTags = try modelContext.fetch(FetchDescriptor<Tag>())
        for tag in existingTags { modelContext.delete(tag) }
        try modelContext.save()

        // Delete existing photos
        for filename in photoService.allPhotoFilenames() {
            photoService.deletePhoto(filename: filename)
        }

        // Restore tags
        syncState = .syncing(progress: "Restoring tags...")
        var tagLookup: [UUID: Tag] = [:]
        for tagDTO in backupData.tags {
            let tag = Tag(name: tagDTO.name)
            tag.id = tagDTO.id
            modelContext.insert(tag)
            tagLookup[tagDTO.id] = tag
        }

        // Restore food entries
        syncState = .syncing(progress: "Restoring food entries...")
        for entryDTO in backupData.foodEntries {
            let mealType = entryDTO.mealType.flatMap { MealType(rawValue: $0) }
            let tags = entryDTO.tagIDs.compactMap { tagLookup[$0] }
            let entry = FoodEntry(
                title: entryDTO.title,
                text: entryDTO.text,
                photoFileName: entryDTO.photoFileName,
                mealType: mealType,
                tags: tags,
                createdAt: entryDTO.createdAt
            )
            entry.id = entryDTO.id
            modelContext.insert(entry)
        }

        // Restore weight entries
        syncState = .syncing(progress: "Restoring weight entries...")
        for entryDTO in backupData.weightEntries {
            let entry = WeightEntry(date: entryDTO.date, weight: entryDTO.weight, notes: entryDTO.notes)
            entry.id = entryDTO.id
            modelContext.insert(entry)
        }

        // Download photos
        let photoFileNames = backupData.manifest.photoFileNames
        if !photoFileNames.isEmpty {
            let photoFolderID = try await provider.ensureFolder(path: photoFolderPath)
            let remotePhotos = try await provider.listFiles(inFolder: photoFolderID)
            let remotePhotoMap = Dictionary(remotePhotos.map { ($0.name, $0.id) }, uniquingKeysWith: { first, _ in first })

            for (index, fileName) in photoFileNames.enumerated() {
                syncState = .syncing(progress: "Downloading photo \(index + 1) of \(photoFileNames.count)...")
                if let fileID = remotePhotoMap[fileName],
                   let photoData = try? await provider.downloadFile(fileID: fileID) {
                    let fileURL = photoService.photoFileURL(filename: fileName)
                    try? photoData.write(to: fileURL)
                }
            }
        }

        // Restore settings
        syncState = .syncing(progress: "Restoring settings...")
        settings.apply(dto: backupData.settings)

        try modelContext.save()
        syncState = .idle
    }

    // MARK: - Private

    private func pruneOldBackups(provider: CloudStorageProvider, folderID: String) async throws {
        let files = try await provider.listFiles(inFolder: folderID)
        let jsonFiles = files.filter { $0.name.hasSuffix(".json") }
            .sorted { ($0.modifiedDate ?? .distantPast) > ($1.modifiedDate ?? .distantPast) }

        if jsonFiles.count > maxBackups {
            let toDelete = jsonFiles.suffix(from: maxBackups)
            for file in toDelete {
                try? await provider.deleteFile(fileID: file.id)
            }
        }
    }
}
