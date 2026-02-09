import Foundation
import UIKit
import GoogleSignIn
import GoogleAPIClientForREST_Drive

@MainActor
final class GoogleDriveProvider: CloudStorageProvider {
    static let shared = GoogleDriveProvider()

    nonisolated let providerName = "Google Drive"
    nonisolated let providerIcon = "externaldrive.fill"

    private(set) var authState: CloudAuthState = .signedOut
    private var driveService: GTLRDriveService?
    private var folderIDCache: [String: String] = [:]
    private let driveScope = "https://www.googleapis.com/auth/drive.file"

    init() {}

    // MARK: - Auth

    func signIn(presentingViewController: UIViewController) async throws {
        authState = .signingIn

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingViewController,
                hint: nil,
                additionalScopes: [driveScope]
            )

            configureDriveService(user: result.user)
            let email = result.user.profile?.email ?? "Unknown"
            authState = .signedIn(email: email)
        } catch {
            authState = .error(error.localizedDescription)
            throw CloudStorageError.authenticationFailed(error.localizedDescription)
        }
    }

    func signOut() async {
        GIDSignIn.sharedInstance.signOut()
        driveService = nil
        folderIDCache.removeAll()
        authState = .signedOut
    }

    func restorePreviousSignIn() async -> Bool {
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()

            // Check if Drive scope is granted
            let grantedScopes = user.grantedScopes ?? []
            guard grantedScopes.contains(driveScope) else {
                authState = .signedOut
                return false
            }

            configureDriveService(user: user)
            let email = user.profile?.email ?? "Unknown"
            authState = .signedIn(email: email)
            return true
        } catch {
            authState = .signedOut
            return false
        }
    }

    // MARK: - File Operations

    func ensureFolder(path: String) async throws -> String {
        if let cached = folderIDCache[path] {
            return cached
        }

        let components = path.split(separator: "/").map(String.init)
        var parentID = "root"

        var currentPath = ""
        for component in components {
            currentPath += (currentPath.isEmpty ? "" : "/") + component

            if let cached = folderIDCache[currentPath] {
                parentID = cached
                continue
            }

            let folderID = try await findOrCreateFolder(name: component, parentID: parentID)
            folderIDCache[currentPath] = folderID
            parentID = folderID
        }

        return parentID
    }

    func uploadFile(data: Data, fileName: String, folderID: String, mimeType: String) async throws -> CloudFileMetadata {
        guard let service = driveService else {
            throw CloudStorageError.notAuthenticated
        }

        let metadata = GTLRDrive_File()
        metadata.name = fileName
        metadata.parents = [folderID]

        let params = GTLRUploadParameters(data: data, mimeType: mimeType)

        let query = GTLRDriveQuery_FilesCreate.query(withObject: metadata, uploadParameters: params)
        query.fields = "id, name, mimeType, size, modifiedTime"

        let file: GTLRDrive_File = try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { _, result, error in
                if let error {
                    continuation.resume(throwing: CloudStorageError.uploadFailed(error.localizedDescription))
                } else if let file = result as? GTLRDrive_File {
                    continuation.resume(returning: file)
                } else {
                    continuation.resume(throwing: CloudStorageError.uploadFailed("Unexpected response"))
                }
            }
        }

        return file.toCloudFileMetadata()
    }

    func downloadFile(fileID: String) async throws -> Data {
        guard let service = driveService else {
            throw CloudStorageError.notAuthenticated
        }

        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)

        return try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { _, result, error in
                if let error {
                    continuation.resume(throwing: CloudStorageError.downloadFailed(error.localizedDescription))
                } else if let data = (result as? GTLRDataObject)?.data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: CloudStorageError.downloadFailed("No data received"))
                }
            }
        }
    }

    func listFiles(inFolder folderID: String) async throws -> [CloudFileMetadata] {
        guard let service = driveService else {
            throw CloudStorageError.notAuthenticated
        }

        var allFiles: [CloudFileMetadata] = []
        var pageToken: String? = nil

        repeat {
            let query = GTLRDriveQuery_FilesList.query()
            query.q = "'\(folderID)' in parents and trashed = false"
            query.fields = "nextPageToken, files(id, name, mimeType, size, modifiedTime)"
            query.pageSize = 100
            if let token = pageToken {
                query.pageToken = token
            }

            let fileList: GTLRDrive_FileList = try await withCheckedThrowingContinuation { continuation in
                service.executeQuery(query) { _, result, error in
                    if let error {
                        continuation.resume(throwing: CloudStorageError.operationFailed(error.localizedDescription))
                    } else if let list = result as? GTLRDrive_FileList {
                        continuation.resume(returning: list)
                    } else {
                        continuation.resume(throwing: CloudStorageError.operationFailed("Unexpected response"))
                    }
                }
            }

            allFiles.append(contentsOf: (fileList.files ?? []).map { $0.toCloudFileMetadata() })
            pageToken = fileList.nextPageToken
        } while pageToken != nil

        return allFiles
    }

    func deleteFile(fileID: String) async throws {
        guard let service = driveService else {
            throw CloudStorageError.notAuthenticated
        }

        let query = GTLRDriveQuery_FilesDelete.query(withFileId: fileID)

        let _: Void = try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { _, _, error in
                if let error {
                    continuation.resume(throwing: CloudStorageError.operationFailed(error.localizedDescription))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    // MARK: - Private

    private func configureDriveService(user: GIDGoogleUser) {
        let service = GTLRDriveService()
        service.authorizer = user.fetcherAuthorizer
        driveService = service
    }

    private func findOrCreateFolder(name: String, parentID: String) async throws -> String {
        guard let service = driveService else {
            throw CloudStorageError.notAuthenticated
        }

        // Search for existing folder
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "name = '\(name)' and '\(parentID)' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
        query.fields = "files(id)"

        let fileList: GTLRDrive_FileList = try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { _, result, error in
                if let error {
                    continuation.resume(throwing: CloudStorageError.operationFailed(error.localizedDescription))
                } else if let list = result as? GTLRDrive_FileList {
                    continuation.resume(returning: list)
                } else {
                    continuation.resume(throwing: CloudStorageError.operationFailed("Unexpected response"))
                }
            }
        }

        if let existingID = fileList.files?.first?.identifier {
            return existingID
        }

        // Create folder
        let folderMetadata = GTLRDrive_File()
        folderMetadata.name = name
        folderMetadata.mimeType = "application/vnd.google-apps.folder"
        folderMetadata.parents = [parentID]

        let createQuery = GTLRDriveQuery_FilesCreate.query(withObject: folderMetadata, uploadParameters: nil)
        createQuery.fields = "id"

        let folder: GTLRDrive_File = try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(createQuery) { _, result, error in
                if let error {
                    continuation.resume(throwing: CloudStorageError.operationFailed(error.localizedDescription))
                } else if let file = result as? GTLRDrive_File {
                    continuation.resume(returning: file)
                } else {
                    continuation.resume(throwing: CloudStorageError.operationFailed("Failed to create folder"))
                }
            }
        }

        guard let folderID = folder.identifier else {
            throw CloudStorageError.operationFailed("Created folder has no ID")
        }

        return folderID
    }
}

// MARK: - GTLRDrive_File Extension

private extension GTLRDrive_File {
    func toCloudFileMetadata() -> CloudFileMetadata {
        CloudFileMetadata(
            id: identifier ?? "",
            name: name ?? "",
            mimeType: mimeType ?? "",
            size: Int64(truncating: size ?? 0),
            modifiedDate: modifiedTime?.date
        )
    }
}
