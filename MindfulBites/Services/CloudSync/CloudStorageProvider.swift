import Foundation
import UIKit

// MARK: - Auth State

enum CloudAuthState: Equatable {
    case signedOut
    case signingIn
    case signedIn(email: String)
    case error(String)

    static func == (lhs: CloudAuthState, rhs: CloudAuthState) -> Bool {
        switch (lhs, rhs) {
        case (.signedOut, .signedOut), (.signingIn, .signingIn):
            return true
        case (.signedIn(let a), .signedIn(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Sync State

enum CloudSyncState: Equatable {
    case idle
    case syncing(progress: String)
    case error(String)
}

// MARK: - File Metadata

struct CloudFileMetadata: Identifiable, Equatable {
    let id: String
    let name: String
    let mimeType: String
    let size: Int64?
    let modifiedDate: Date?
}

// MARK: - Errors

enum CloudStorageError: LocalizedError {
    case notAuthenticated
    case networkUnavailable
    case quotaExceeded
    case fileNotFound(String)
    case uploadFailed(String)
    case downloadFailed(String)
    case deleteFailed(String)
    case folderCreationFailed(String)
    case authenticationFailed(String)
    case operationFailed(String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in to cloud storage"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .quotaExceeded:
            return "Cloud storage quota exceeded"
        case .fileNotFound(let name):
            return "File not found: \(name)"
        case .uploadFailed(let detail):
            return "Upload failed: \(detail)"
        case .downloadFailed(let detail):
            return "Download failed: \(detail)"
        case .deleteFailed(let detail):
            return "Delete failed: \(detail)"
        case .folderCreationFailed(let detail):
            return "Could not create folder: \(detail)"
        case .authenticationFailed(let detail):
            return "Authentication failed: \(detail)"
        case .operationFailed(let detail):
            return "Operation failed: \(detail)"
        case .unknown(let error):
            return "Cloud storage error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Protocol

protocol CloudStorageProvider: AnyObject {
    var providerID: String { get }
    var providerName: String { get }
    var providerIcon: String { get }
    var authState: CloudAuthState { get }

    func signIn(presentingViewController: UIViewController) async throws
    func signOut() async
    func restorePreviousSignIn() async -> Bool

    func ensureFolder(path: String) async throws -> String
    func uploadFile(data: Data, fileName: String, folderID: String, mimeType: String) async throws -> CloudFileMetadata
    func downloadFile(fileID: String) async throws -> Data
    func listFiles(inFolder folderID: String) async throws -> [CloudFileMetadata]
    func deleteFile(fileID: String) async throws
}
