import Foundation
import os
import UIKit

protocol PhotoStorageServiceProtocol {
    func savePhoto(_ image: UIImage) -> String?
    func loadPhoto(filename: String) -> UIImage?
    func deletePhoto(filename: String)
    func loadThumbnail(filename: String, size: CGSize) -> UIImage?
    func photoFileURL(filename: String) -> URL
    func allPhotoFilenames() -> [String]
}

/// Service for saving and loading food photos to the Documents directory.
/// Photos are stored as JPEG files, not in SwiftData, for better performance.
final class PhotoStorageService: PhotoStorageServiceProtocol {
    static let shared = PhotoStorageService()

    private let fileManager = FileManager.default
    private let compressionQuality: CGFloat = 0.8
    let photosDirectory: URL
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.mindfulbites.app", category: "PhotoStorage")

    init(photosDirectory: URL? = nil) {
        if let dir = photosDirectory {
            self.photosDirectory = dir
        } else {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.photosDirectory = documentsURL.appendingPathComponent("FoodPhotos", isDirectory: true)
        }

        if !FileManager.default.fileExists(atPath: self.photosDirectory.path) {
            try? FileManager.default.createDirectory(at: self.photosDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Save Photo

    func savePhoto(_ image: UIImage) -> String? {
        let filename = generateFilename()
        let fileURL = photosDirectory.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }

        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            logger.error("Failed to save photo: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Load Photo

    func loadPhoto(filename: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    // MARK: - Delete Photo

    func deletePhoto(filename: String) {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
    }

    // MARK: - Thumbnail

    func loadThumbnail(filename: String, size: CGSize) -> UIImage? {
        guard let image = loadPhoto(filename: filename) else {
            return nil
        }

        return image.preparingThumbnail(of: size)
    }

    // MARK: - File Access

    func photoFileURL(filename: String) -> URL {
        photosDirectory.appendingPathComponent(filename)
    }

    func allPhotoFilenames() -> [String] {
        (try? fileManager.contentsOfDirectory(atPath: photosDirectory.path))?
            .filter { $0.hasSuffix(".jpg") } ?? []
    }

    // MARK: - Helpers

    private func generateFilename() -> String {
        let uuid = UUID().uuidString
        let timestamp = Int(Date().timeIntervalSince1970)
        return "food_\(uuid)_\(timestamp).jpg"
    }
}
