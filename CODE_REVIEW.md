# Code Review: Settings, Cloud Backup, Insights, and Notifications

**Reviewer:** Claude (Senior Principal iOS)
**Date:** 2026-02-08
**Scope:** All staged changes (~3,800 lines, 42 files)

---

## Critical (Blockers)

### 1. Restore is destructive with no safety net
**File:** `BackupService.swift:182-195`

`performRestore` deletes ALL local data (food entries, weight entries, tags, photos) before downloading the replacement. If the network fails mid-restore, or photo downloads silently error out (`try?` on line 244), the user loses everything with no recovery path.

**Fix:** Either create a local backup before restoring, or download everything into a staging area first and swap atomically.

### 2. syncState never resets on error
**File:** `BackupService.swift:27-131, 162-255`

Both `performBackup` and `performRestore` set `syncState = .syncing(...)` but never reset it if an error is thrown. The UI will show a perpetual spinner with no way to recover. Neither method has a `defer { syncState = .idle }` or catch-path reset.

### 3. Error alerts defined but never displayed
**File:** `CloudBackupSection.swift:8-11`

Four `@State` properties (`showingSignInError`, `signInErrorMessage`, `showingBackupError`, `backupErrorMessage`) are populated on errors, but there are no `.alert()` modifiers in the view body. Sign-in and backup errors are silently swallowed from the user's perspective.

### 4. Photo upload failures silently skipped during backup
**File:** `BackupService.swift:89-97`

`try? Data(contentsOf:)` silently skips missing or corrupted photos. The backup completes "successfully" with missing photos and no user indication. The manifest's `photoFileNames` lists photos that may not exist in the cloud.

### 5. Google Drive pagination missing
**File:** `GoogleDriveProvider.swift:152`

`query.pageSize = 100` with no pagination loop. Users with >100 photos or >100 backup files will silently have data truncated. `listFiles` returns only the first page.

---

## High (Fix Before Shipping)

### 6. GoogleDriveProvider has data races
**File:** `GoogleDriveProvider.swift`

Mutable state (`authState`, `driveService`, `folderIDCache`) is accessed from async contexts with no synchronization. `folderIDCache` is read and written in `ensureFolder` (lines 71-92). `authState` is written from `signIn`/`signOut`/`restorePreviousSignIn` without actor isolation. This class should be an `actor` or use a lock.

### 7. @MainActor on entire backup/restore methods
**File:** `BackupService.swift:26-27, 161-162`

Both `performBackup` and `performRestore` are `@MainActor`, meaning all network uploads, JSON encoding, and file I/O run on the main thread. Only the SwiftData fetches require main actor isolation. Heavy backups with many photos will freeze the UI.

### 8. Dual source of truth for weightUnit
**File:** `InsightsView.swift:7`

`@AppStorage("weightUnit")` reads directly from UserDefaults using a raw string key, bypassing `SettingsService`. If the key name ever changes in `SettingsService.Keys.weightUnit`, this silently breaks. Two independent readers of the same UserDefaults key with no shared constant.

### 9. NotificationService.syncWithSettings() hardcodes singleton
**File:** `NotificationService.swift:81`

`let settings = SettingsService.shared` is the only service method that bypasses the DI pattern used everywhere else. Makes it impossible to test notification scheduling with different settings.

### 10. MealTimeRange doesn't support overnight ranges
**File:** `MealTimeRange.swift:38-40`

`contains(timeInMinutes:)` checks `start <= time < end`, which only works when `start < end`. A dinner range of 22:00-01:00 (crossing midnight) would never match. The UI has no validation to prevent users from creating this configuration via the DatePickers.

---

## Medium

### 11. SettingsView bypasses DI pattern
**File:** `SettingsView.swift:4-6, 21, 40-43, 84, 93`

Directly accesses `SettingsService.shared` and `NotificationService.shared` throughout. Unlike `CloudBackupSection` which accepts services as stored properties, `SettingsView` is untestable and inconsistent with the rest of the codebase.

### 12. BackupService.lastBackupDate bypasses injectable UserDefaults
**File:** `BackupService.swift:18-19`

Uses `UserDefaults.standard` directly while the rest of the settings infrastructure uses injectable `UserDefaults(suiteName:)`. Tests for `BackupService` mutate the real user defaults.

### 13. WeightTrend enum lives in a View file
**File:** `TrendCard.swift:3-34`

`WeightTrend` is a domain/model enum defined inside a view file. `InsightsCalculator` returns it but has to import it from a view. Couples business logic to the UI layer.

### 14. Filename reconstruction for restore is fragile
**File:** `RestoreBackupView.swift:104-105`

Reconstructs the backup filename from the manifest date: `"backup_\(formatter.string(from: manifest.createdAt)).json"`. If ISO8601 formatting differs between encode and decode (timezone, fractional seconds), the name won't match. The manifest or list API should return the actual filename.

### 15. CloudProviderRegistry hardcodes Google Drive
**File:** `CloudProviderRegistry.swift:11`

`providers = [GoogleDriveProvider.shared]` in `init()` defeats the protocol-based extensibility. Adding a provider requires editing this constructor rather than registering from outside.

### 16. No backup version migration path
**File:** `BackupCodable.swift:49`

`BackupManifest.currentVersion = 1` exists but there is no code to check or handle different versions. When version 2 arrives, there's no infrastructure to migrate version 1 backups gracefully. `performRestore` should at minimum check the version field.

### 17. SettingsService.weightReminderHour has a subtle default bug
**File:** `SettingsService.swift:50-53`

The default logic `value == 0 && !defaults.bool(forKey: ...) ? 8 : value` conflates "key not set" with "explicitly set to 0." If a user sets hour=0 (midnight) while reminders are disabled, enabling reminders later jumps to hour 8. Classic UserDefaults zero-ambiguity issue.

---

## Low

### 18. ForEach with array offset as identity
**File:** `CloudBackupSection.swift:35`

`ForEach(Array(registry.providers.enumerated()), id: \.offset)` uses array index as SwiftUI identity. If the provider list changes order, SwiftUI will misidentify views. Providers should have a stable `id`.

### 19. Singleton init access inconsistency
`NotificationService` has `private init()` (correct for singleton), but `BackupService` and `GoogleDriveProvider` have internal `init()`, allowing anyone to create additional instances. `GoogleDriveProvider` having a public init alongside `.shared` is confusing.

### 20. BackupManifest.id uses Date
**File:** `BackupCodable.swift:47`

`var id: Date { createdAt }` means two backups created within the same second would have colliding `Identifiable` ids. Should use UUID.

### 21. InsightsView recalculates everything on every render
**File:** `InsightsView.swift:45-53, 63-66, 83`

Every section body calls `InsightsCalculator` methods that sort, deduplicate, and iterate the full dataset. O(n log n) work on every SwiftUI view evaluation with no caching.

### 22. SettingsDTO.weightUnit is a raw String
**File:** `BackupCodable.swift:28`

Storing weight unit as a `String` rather than the `WeightUnit` enum means invalid strings can persist in backups. Restore silently ignores invalid values (line 107-109) with no user-facing error.

---

## Info (Nice to Have)

### 23. print statement in production code
**File:** `PhotoStorageService.swift:49`

`print("Failed to save photo: \(error)")` should use `os_log` or `Logger` for proper log levels and filtering in production.

### 24. @State with singleton reference is semantically odd
**File:** `MealTimeSection.swift:4`

`@State private var settings = SettingsService.shared` captures the singleton as `@State`. It works because `@Observable` + reference type, but `@State` semantically implies view-owned value. Could be confusing to future readers.

### 25. GalleryFilter does in-memory filtering
**File:** `FoodView.swift:19-46`

`filteredEntries` does in-memory filtering of all entries on every view update. Could eventually be optimized with SwiftData `#Predicate` for large datasets, but fine for current scale.
