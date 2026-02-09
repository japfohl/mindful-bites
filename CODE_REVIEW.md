# Code Review: Settings, Cloud Backup, Insights, and Notifications

**Reviewer:** Claude (Senior Principal iOS)
**Date:** 2026-02-08
**Scope:** All staged changes (~3,800 lines, 42 files)

---

## ~~Critical (Blockers)~~ — All Fixed

### ~~1. Restore is destructive with no safety net~~ FIXED
Implemented staged restore: downloads to temp directory first, then swaps atomically. Returns `RestoreResult` with failed photo download warnings.

### ~~2. syncState never resets on error~~ FIXED
Added do/catch with `syncState = .idle` reset in all error paths for both `performBackup` and `performRestore`.

### ~~3. Error alerts defined but never displayed~~ FIXED
Added `.alert()` modifiers to `CloudBackupSection` for sign-in errors, backup errors, and backup warnings. Added restore warning alert to `RestoreBackupView`.

### ~~4. Photo upload failures silently skipped during backup~~ FIXED
Replaced `try?` with do/catch, tracks failed uploads in `BackupResult.skippedPhotos`, surfaces warning to user.

### ~~5. Google Drive pagination missing~~ FIXED
Added pagination loop using `nextPageToken` in `listFiles` to fetch all pages.

---

## ~~High (Fix Before Shipping)~~ — All Fixed

### ~~6. GoogleDriveProvider has data races~~ FIXED
Added `@MainActor` to class declaration. Marked constant properties as `nonisolated`.

### ~~7. @MainActor on entire backup/restore methods~~ FIXED
Removed `@MainActor` from method signatures. Only SwiftData access and UI state updates wrapped in `await MainActor.run {}`.

### ~~8. Dual source of truth for weightUnit~~ FIXED
Replaced `@AppStorage("weightUnit")` with `SettingsService.shared` reference in `InsightsView`.

### ~~9. NotificationService.syncWithSettings() hardcodes singleton~~ FIXED
Made `settings` parameter injectable with default value `SettingsService.shared`. Updated protocol.

### ~~10. MealTimeRange doesn't support overnight ranges~~ FIXED
Added overnight logic: when `startMinutes > endMinutes`, uses OR (`>=start || <end`) instead of AND.

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
