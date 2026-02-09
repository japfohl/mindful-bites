import Foundation
import UIKit
@testable import MindfulBites

final class MockCloudStorageProvider: CloudStorageProvider {
    var providerID: String = "mock"
    var providerName: String = "Mock"
    var providerIcon: String = "cloud"
    var authState: CloudAuthState = .signedIn(email: "test@example.com")

    // Storage
    var folders: [String: String] = [:]  // path -> id
    var files: [String: (data: Data, metadata: CloudFileMetadata)] = [:]  // fileID -> (data, metadata)
    private var folderFiles: [String: [String]] = [:]  // folderID -> [fileID]
    private var nextID = 1

    // Call tracking
    var signInCallCount = 0
    var signOutCallCount = 0
    var uploadCallCount = 0
    var downloadCallCount = 0
    var deleteCallCount = 0

    // Error injection
    var shouldFailUpload = false
    var shouldFailDownload = false
    var downloadFailureFileIDs: Set<String> = []

    func signIn(presentingViewController: UIViewController) async throws {
        signInCallCount += 1
        authState = .signedIn(email: "test@example.com")
    }

    func signOut() async {
        signOutCallCount += 1
        authState = .signedOut
    }

    func restorePreviousSignIn() async -> Bool {
        if case .signedIn = authState { return true }
        return false
    }

    func ensureFolder(path: String) async throws -> String {
        if let existing = folders[path] {
            return existing
        }
        let id = "folder_\(nextID)"
        nextID += 1
        folders[path] = id
        folderFiles[id] = []
        return id
    }

    func uploadFile(data: Data, fileName: String, folderID: String, mimeType: String) async throws -> CloudFileMetadata {
        uploadCallCount += 1

        if shouldFailUpload {
            throw CloudStorageError.uploadFailed("Mock upload failure")
        }

        let fileID = "file_\(nextID)"
        nextID += 1

        let metadata = CloudFileMetadata(
            id: fileID,
            name: fileName,
            mimeType: mimeType,
            size: Int64(data.count),
            modifiedDate: Date()
        )

        files[fileID] = (data: data, metadata: metadata)
        folderFiles[folderID, default: []].append(fileID)

        return metadata
    }

    func downloadFile(fileID: String) async throws -> Data {
        downloadCallCount += 1

        if shouldFailDownload {
            throw CloudStorageError.downloadFailed("Mock download failure")
        }

        if downloadFailureFileIDs.contains(fileID) {
            throw CloudStorageError.downloadFailed("Mock selective download failure for \(fileID)")
        }

        guard let file = files[fileID] else {
            throw CloudStorageError.fileNotFound(fileID)
        }
        return file.data
    }

    func listFiles(inFolder folderID: String) async throws -> [CloudFileMetadata] {
        let fileIDs = folderFiles[folderID] ?? []
        return fileIDs.compactMap { files[$0]?.metadata }
    }

    func deleteFile(fileID: String) async throws {
        deleteCallCount += 1
        files.removeValue(forKey: fileID)
        for (folderID, var ids) in folderFiles {
            ids.removeAll { $0 == fileID }
            folderFiles[folderID] = ids
        }
    }
}
