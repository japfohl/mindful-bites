import SwiftUI

struct CloudBackupSection: View {
    @Environment(\.modelContext) private var modelContext
    var backupService: BackupService = .shared
    var registry: CloudProviderRegistry = .shared

    @State private var showingSignInError = false
    @State private var signInErrorMessage = ""
    @State private var showingBackupError = false
    @State private var backupErrorMessage = ""
    @State private var showingBackupWarning = false
    @State private var backupWarningMessage = ""

    var body: some View {
        Section {
            if let provider = registry.activeProvider {
                signedInContent(provider: provider)
            } else {
                signedOutContent
            }
        } header: {
            Text("Cloud Backup")
        } footer: {
            if registry.activeProvider != nil {
                Text("Backups include all food entries, weight data, tags, photos, and settings")
            } else {
                Text("Back up your data to keep it safe across devices")
            }
        }
        .alert("Sign In Failed", isPresented: $showingSignInError) {
            Button("OK") {}
        } message: {
            Text(signInErrorMessage)
        }
        .alert("Backup Failed", isPresented: $showingBackupError) {
            Button("OK") {}
        } message: {
            Text(backupErrorMessage)
        }
        .alert("Backup Completed with Warnings", isPresented: $showingBackupWarning) {
            Button("OK") {}
        } message: {
            Text(backupWarningMessage)
        }
    }

    // MARK: - Signed Out

    @ViewBuilder
    private var signedOutContent: some View {
        ForEach(Array(registry.providers.enumerated()), id: \.element.providerID) { _, provider in
            Button {
                Task { await signIn(provider: provider) }
            } label: {
                Label("Sign in with \(provider.providerName)", systemImage: provider.providerIcon)
            }
        }
    }

    // MARK: - Signed In

    @ViewBuilder
    private func signedInContent(provider: any CloudStorageProvider) -> some View {
        // Status row
        if case .signedIn(let email) = provider.authState {
            LabeledContent(provider.providerName, value: email)
        }

        // Sync state / backup button
        switch backupService.syncState {
        case .idle:
            Button {
                Task { await performBackup(provider: provider) }
            } label: {
                Label("Back Up Now", systemImage: "icloud.and.arrow.up")
            }

            if let lastBackup = backupService.lastBackupDate {
                LabeledContent("Last Backup", value: lastBackup.formatted(date: .abbreviated, time: .shortened))
            }

        case .syncing(let progress):
            HStack {
                ProgressView()
                    .padding(.trailing, 4)
                Text(progress)
                    .foregroundStyle(.secondary)
            }

        case .error(let message):
            Label(message, systemImage: "exclamation.triangle")
                .foregroundStyle(.red)
        }

        // Restore
        NavigationLink {
            RestoreBackupView(provider: provider)
        } label: {
            Label("Restore from Backup", systemImage: "arrow.counterclockwise")
        }

        // Sign out
        Button(role: .destructive) {
            Task {
                await provider.signOut()
                registry.clearActiveProvider()
            }
        } label: {
            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
        }
    }

    // MARK: - Actions

    @MainActor
    private func signIn(provider: any CloudStorageProvider) async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        do {
            try await provider.signIn(presentingViewController: rootVC)
            registry.setActiveProvider(provider)
        } catch {
            signInErrorMessage = error.localizedDescription
            showingSignInError = true
        }
    }

    @MainActor
    private func performBackup(provider: any CloudStorageProvider) async {
        do {
            let result = try await backupService.performBackup(
                modelContext: modelContext,
                provider: provider
            )
            if result.hasWarnings {
                backupWarningMessage = result.warningMessage ?? ""
                showingBackupWarning = true
            }
        } catch {
            backupErrorMessage = error.localizedDescription
            showingBackupError = true
        }
    }
}
