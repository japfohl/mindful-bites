import UIKit

/// In-memory cache for photo thumbnails to improve gallery performance.
actor ThumbnailCache {
    static let shared = ThumbnailCache()

    private var cache: [String: UIImage] = [:]
    private let maxCacheSize = 100

    private init() {}

    func thumbnail(for filename: String, size: CGSize) async -> UIImage? {
        let cacheKey = "\(filename)_\(Int(size.width))x\(Int(size.height))"

        // Return cached if available
        if let cached = cache[cacheKey] {
            return cached
        }

        // Generate thumbnail
        guard let thumbnail = await generateThumbnail(filename: filename, size: size) else {
            return nil
        }

        // Cache it
        if cache.count >= maxCacheSize {
            // Remove oldest entries (simple FIFO)
            let keysToRemove = Array(cache.keys.prefix(20))
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }

        cache[cacheKey] = thumbnail
        return thumbnail
    }

    private func generateThumbnail(filename: String, size: CGSize) async -> UIImage? {
        await Task.detached(priority: .utility) {
            PhotoStorageService.shared.loadThumbnail(filename: filename, size: size)
        }.value
    }

    func clearCache() {
        cache.removeAll()
    }

    func removeThumbnail(for filename: String) {
        let keysToRemove = cache.keys.filter { $0.hasPrefix(filename) }
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
    }
}
