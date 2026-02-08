# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build
xcodebuild -project MindfulBites.xcodeproj -scheme MindfulBites -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests
xcodebuild -project MindfulBites.xcodeproj -scheme MindfulBites -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:MindfulBitesTests test
```

Deployment target: iOS 17.0+. Uses Swift 5.0, SwiftUI, SwiftData, and Charts.

### External Dependencies (SPM)

| Package | Version | Products Used |
|---------|---------|---------------|
| GoogleSignIn-iOS | 8.0.0+ | `GoogleSignIn`, `GoogleSignInSwift` |
| google-api-objectivec-client-for-rest | 5.0.0+ | `GoogleAPIClientForRESTCore`, `GoogleAPIClientForREST_Drive` |

## Architecture

**Tab-based SwiftUI app** with four tabs: Food, Weight, Insights, Settings. Root navigation is in `ContentView.swift` using `TabView`.

**No ViewModel layer.** Views use `@Query` for SwiftData fetches and `@State` for local state directly. Business logic lives in singleton services.

### Data Layer

- **SwiftData models** (`Models/`): `FoodEntry`, `WeightEntry`, `Tag` — all use `@Model` macro
- `FoodEntry` ↔ `Tag` is a bidirectional `@Relationship`
- Photos are stored as JPEG files on disk (`Documents/FoodPhotos/`), referenced by filename in `FoodEntry.photoFileName`
- Settings are stored in `UserDefaults`, wrapped by `SettingsService`

### Services (all singletons via `.shared`)

| Service | Pattern | Purpose |
|---------|---------|---------|
| `SettingsService` | `@Observable` | UserDefaults wrapper for weight unit, reminders, meal time ranges |
| `NotificationService` | `@Observable` | Push notification scheduling (daily weight reminders) |
| `PhotoStorageService` | class | Save/load/delete photos, generate thumbnails |
| `ThumbnailCache` | `Actor` | Thread-safe in-memory thumbnail cache (max 100, FIFO eviction) |
| `BackupService` | `@Observable` | Cloud backup/restore orchestrator |
| `CloudProviderRegistry` | `@Observable` | Manages registered cloud storage providers |
| `GoogleDriveProvider` | class | Google Drive implementation of `CloudStorageProvider` |

### Cloud Backup Architecture (`Services/CloudSync/`)

**Protocol-based extensibility**: `CloudStorageProvider` protocol defines auth + file operations. `GoogleDriveProvider` is the first concrete implementation. New providers can be added to `CloudProviderRegistry.providers`.

**Backup data flow**: `BackupService` serializes all three data silos (SwiftData models, photos, UserDefaults settings) into a JSON backup via Codable DTOs (`BackupCodable.swift`). Photos are uploaded individually.

**Drive folder structure**:
```
.mindfulBites/
  manifest.json              ← latest BackupManifest (quick status check)
  backups/
    backup_<ISO8601>.json    ← full BackupData snapshots (keep last 5)
  photos/
    food_<UUID>_<ts>.jpg     ← mirrors local FoodPhotos/ directory
```

**Key types**: `TagDTO`, `FoodEntryDTO`, `WeightEntryDTO`, `SettingsDTO`, `BackupManifest`, `BackupData`. Tag many-to-many handled via `tagIDs: [UUID]` on FoodEntryDTO, resolved on restore via UUID lookup.

**Google Sign-In**: Configured in `Info.plist` (GIDClientID + URL scheme). Callback handled via `.onOpenURL` in `MindfulBitesApp.swift`. Uses `drive.file` scope.

### Testability

Services use dependency injection for testability while maintaining backward-compatible `.shared` singletons:
- `SettingsService(defaults:)` — injectable `UserDefaults`
- `PhotoStorageService(photosDirectory:)` — injectable temp directory
- `MealType.suggested(for:using:)` — injectable `SettingsServiceProtocol`
- `BackupService.performBackup(modelContext:provider:settings:photoService:)` — all deps injectable

Protocols: `SettingsServiceProtocol`, `PhotoStorageServiceProtocol`, `NotificationServiceProtocol`, `CloudStorageProvider`

### View Structure

Views use `NavigationStack` with `.navigationDestination(item:)` for push navigation and `.sheet()` for modals. Key patterns:
- `FoodView` toggles between timeline (`FoodTimelineView`) and gallery (`FoodGalleryView`) modes
- `FlowLayout` (custom `Layout`) used in `TagPicker` and `FoodEntryDetailView` for wrapping tag display
- `CameraPicker` wraps `UIImagePickerController` via `UIViewControllerRepresentable`
- `MealType.suggested()` auto-selects meal type based on current time and configurable `MealTimeRange` values
- `CloudBackupSection` in Settings handles sign-in, backup, restore navigation
- `InsightsCalculator` extracts all computation from `InsightsView` into testable static methods

### Key Enums

- `MealType`: breakfast, lunch, dinner, snack — with time-based suggestion logic
- `WeightUnit`: kg, lbs — includes conversion methods
- `Timeframe`: date range filtering for charts (1W, 1M, 3M, 1Y, all)
- `CloudAuthState`: signedOut, signingIn, signedIn(email), error
- `CloudSyncState`: idle, syncing(progress), error

## Testing

Test target: `MindfulBitesTests` (99 tests). Uses in-memory `ModelContainer` for SwiftData tests, isolated `UserDefaults(suiteName:)` for settings tests, temp directories for photo tests, and `MockCloudStorageProvider` for backup tests.

### pbxproj ID Scheme

- `AA*` = app target entries
- `BB*` = test target infrastructure
- `CC*` = test source files
- `DD*` = SPM package references and dependencies

## Google Drive Setup

To enable Google Drive backup, complete these steps in Google Cloud Console:

1. Create a project and enable the Google Drive API
2. Create an iOS OAuth 2.0 Client ID with bundle ID `com.mindfulbites.app`
3. Replace the placeholder values in `MindfulBites/Info.plist`:
   - `GIDClientID`: your OAuth client ID
   - `CFBundleURLSchemes`: reversed client ID (e.g., `com.googleusercontent.apps.YOUR-CLIENT-ID`)
