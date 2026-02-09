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

## ~~Medium~~ — All Fixed

### ~~11. SettingsView bypasses DI pattern~~ FIXED
Added injectable `settings: SettingsService` and `notifications: NotificationService` stored properties with `.shared` defaults. All singleton references replaced with injected instances.

### ~~12. BackupService.lastBackupDate bypasses injectable UserDefaults~~ FIXED
`BackupService` now uses its injected `defaults` property for `lastBackupDate` instead of `UserDefaults.standard`.

### ~~13. WeightTrend enum lives in a View file~~ FIXED
Moved `WeightTrend` enum from `TrendCard.swift` to `InsightsCalculator.swift`, co-locating it with the business logic that produces it.

### ~~14. Filename reconstruction for restore is fragile~~ FIXED
Added `backupFileName: String?` to `BackupManifest` with `resolvedBackupFileName` computed property for backward compatibility. Restore now uses the stored filename instead of reconstructing it.

### ~~15. CloudProviderRegistry hardcodes Google Drive~~ FIXED
Added `register(_:)` method with duplicate-check via `providerID`. New providers can be registered at runtime without editing `init()`.

### ~~16. No backup version migration path~~ FIXED
Added version guard in `performRestore`: rejects backups from newer app versions with a clear user-facing error message.

### ~~17. SettingsService.weightReminderHour has a subtle default bug~~ FIXED
Added `weightReminderHourSet` sentinel key to distinguish "never set" (defaults to 8 AM) from "explicitly set to 0" (midnight).

---

## ~~Low~~ — All Fixed

### ~~18. ForEach with array offset as identity~~ FIXED
Added `providerID` to `CloudStorageProvider` protocol. `ForEach` now uses `\.element.providerID` for stable identity.

### ~~19. Singleton init access inconsistency~~ FIXED
Made `GoogleDriveProvider.init()` private. `BackupService` keeps internal init for DI testability.

### ~~20. BackupManifest.id uses Date~~ FIXED
Changed to `let id: UUID` with custom `init(from:)` that generates a UUID for old backups missing the field.

### ~~21. InsightsView recalculates everything on every render~~ FIXED
Added `ComputedInsights` struct. All metrics computed once per body evaluation and passed to section functions.

### ~~22. SettingsDTO.weightUnit is a raw String~~ FIXED
Changed from `String` to `WeightUnit` enum. Invalid values now caught at decode time.

---

## ~~Info (Nice to Have)~~ — All Fixed

### ~~23. print statement in production code~~ FIXED
Replaced `print` with `os.Logger` in `PhotoStorageService` for proper unified logging.

### ~~24. @State with singleton reference is semantically odd~~ FIXED
Changed `MealTimeSection.settings` from `@State private var` to plain stored property `var settings: SettingsService = .shared`.

### ~~25. GalleryFilter does in-memory filtering~~ FIXED
Extracted `FilteredFoodContent` subview with `@Query`/`FetchDescriptor` for date filtering at the SwiftData level. Tag and meal-type filtering remain in-memory due to `#Predicate` limitations.
