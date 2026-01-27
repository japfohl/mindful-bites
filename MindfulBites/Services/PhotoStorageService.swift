import Foundation
import UIKit

/// Service for saving and loading food photos to the Documents directory.
/// Photos are stored as JPEG files, not in SwiftData, for better performance.
final class PhotoStorageService {
    static let shared = PhotoStorageService()

    private let fileManager = FileManager.default
    private let compressionQuality: CGFloat = 0.8

    private init() {}

    // MARK: - Directory Management

    private var photosDirectory: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosURL = documentsURL.appendingPathComponent("FoodPhotos", isDirectory: true)

        if !fileManager.fileExists(atPath: photosURL.path) {
            try? fileManager.createDirectory(at: photosURL, withIntermediateDirectories: true)
        }

        return photosURL
    }

    // MARK: - Save Photo

    /// Saves a photo and returns the filename for storage in SwiftData.
    /// - Parameter image: The UIImage to save
    /// - Returns: The filename of the saved photo, or nil if save failed
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
            print("Failed to save photo: \(error)")
            return nil
        }
    }

    // MARK: - Load Photo

    /// Loads a photo from the Documents directory.
    /// - Parameter filename: The filename of the photo to load
    /// - Returns: The UIImage, or nil if not found
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

    /// Deletes a photo from the Documents directory.
    /// - Parameter filename: The filename of the photo to delete
    func deletePhoto(filename: String) {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
    }

    // MARK: - Thumbnail

    /// Creates a thumbnail of the specified size from a photo.
    /// - Parameters:
    ///   - filename: The filename of the photo
    ///   - size: The target size for the thumbnail
    /// - Returns: A resized UIImage, or nil if loading failed
    func loadThumbnail(filename: String, size: CGSize) -> UIImage? {
        guard let image = loadPhoto(filename: filename) else {
            return nil
        }

        return image.preparingThumbnail(of: size)
    }

    // MARK: - Helpers

    private func generateFilename() -> String {
        let uuid = UUID().uuidString
        let timestamp = Int(Date().timeIntervalSince1970)
        return "food_\(uuid)_\(timestamp).jpg"
    }
}
