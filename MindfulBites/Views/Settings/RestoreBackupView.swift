import SwiftUI

struct RestoreBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let provider: any CloudStorageProvider

    var backupService: BackupService = .shared

    @State private var manifests: [BackupManifest] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var selectedBackup: BackupManifest?
    @State private var showingConfirmation = false
    @State private var restoreError: String?
    @State private var showingRestoreWarning = false
    @State private var restoreWarningMessage = ""

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading backups...")
            } else if let error = loadError {
                ContentUnavailableView {
                    Label("Could Not Load Backups", systemImage: "exclamation.triangle")
                } description: {
                    Text(error)
                }
            } else if manifests.isEmpty {
                ContentUnavailableView {
                    Label("No Backups", systemImage: "icloud.slash")
                } description: {
                    Text("You haven't created any backups yet.")
                }
            } else {
                backupList
            }
        }
        .navigationTitle("Restore Backup")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadBackups()
        }
        .confirmationDialog(
            "Restore Backup",
            isPresented: $showingConfirmation,
            presenting: selectedBackup
        ) { backup in
            Button("Restore", role: .destructive) {
                Task { await restoreBackup(backup) }
            }
        } message: { backup in
            Text("This will replace all current data with the backup from \(backup.createdAt.formatted(date: .abbreviated, time: .shortened)).\n\nThis action cannot be undone.")
        }
        .alert("Restore Failed", isPresented: .init(
            get: { restoreError != nil },
            set: { if !$0 { restoreError = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(restoreError ?? "")
        }
        .alert("Restore Completed with Warnings", isPresented: $showingRestoreWarning) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(restoreWarningMessage)
        }
    }

    private var backupList: some View {
        List(manifests) { manifest in
            Button {
                selectedBackup = manifest
                showingConfirmation = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(manifest.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    Text(manifest.deviceName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Label("\(manifest.foodEntryCount)", systemImage: "fork.knife")
                        Label("\(manifest.weightEntryCount)", systemImage: "scalemass")
                        Label("\(manifest.tagCount)", systemImage: "tag")
                        if !manifest.photoFileNames.isEmpty {
                            Label("\(manifest.photoFileNames.count)", systemImage: "photo")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .tint(.primary)
        }
    }

    private func loadBackups() async {
        do {
            manifests = try await backupService.listBackups(provider: provider)
            isLoading = false
        } catch {
            loadError = error.localizedDescription
            isLoading = false
        }
    }

    @MainActor
    private func restoreBackup(_ manifest: BackupManifest) async {
        let formatter = ISO8601DateFormatter()
        let fileName = "backup_\(formatter.string(from: manifest.createdAt)).json"

        do {
            let result = try await backupService.performRestore(
                modelContext: modelContext,
                provider: provider,
                backupFileName: fileName
            )
            if result.hasWarnings {
                restoreWarningMessage = result.warningMessage ?? ""
                showingRestoreWarning = true
            } else {
                dismiss()
            }
        } catch {
            restoreError = error.localizedDescription
        }
    }
}
