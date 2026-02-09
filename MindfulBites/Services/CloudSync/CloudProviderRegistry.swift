import Foundation

@Observable
final class CloudProviderRegistry {
    static let shared = CloudProviderRegistry()

    private(set) var providers: [any CloudStorageProvider] = []
    private(set) var activeProvider: (any CloudStorageProvider)?

    init() {
        providers = [GoogleDriveProvider.shared]
    }

    func register(_ provider: any CloudStorageProvider) {
        guard !providers.contains(where: { $0.providerID == provider.providerID }) else { return }
        providers.append(provider)
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
