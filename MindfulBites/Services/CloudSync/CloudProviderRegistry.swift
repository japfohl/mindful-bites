import Foundation

@Observable
final class CloudProviderRegistry {
    static let shared = CloudProviderRegistry()

    private(set) var providers: [any CloudStorageProvider] = []
    private(set) var activeProvider: (any CloudStorageProvider)?

    init() {
        providers = [GoogleDriveProvider.shared]
    }

    func restorePreviousSession() async {
        for provider in providers {
            if await provider.restorePreviousSignIn() {
                activeProvider = provider
                return
            }
        }
    }

    func setActiveProvider(_ provider: any CloudStorageProvider) {
        activeProvider = provider
    }

    func clearActiveProvider() {
        activeProvider = nil
    }
}
