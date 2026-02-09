# Manual Testing Plan: Settings, Cloud Backup, Insights & Notifications

**Branch:** `feature/settings-cloud-insights`
**Scope:** Phase 5 features (~3,800 lines, 42 files)

---

## Preamble: Google Drive Local Environment Setup

Google Drive backup requires a configured OAuth 2.0 client. Follow these steps before testing any cloud backup features.

### Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **Select a project** > **New Project**
3. Name it something like `MindfulBites Dev` and click **Create**
4. Make sure the new project is selected in the top-left dropdown

### Step 2: Enable the Google Drive API

1. In the Cloud Console, go to **APIs & Services** > **Library**
2. Search for **Google Drive API**
3. Click it and press **Enable**

### Step 3: Configure the OAuth Consent Screen

1. Go to **APIs & Services** > **OAuth consent screen**
2. Select **External** user type, click **Create**
3. Fill in required fields:
   - App name: `MindfulBites`
   - User support email: your email
   - Developer contact: your email
4. Click **Save and Continue**
5. On the **Scopes** page, click **Add or Remove Scopes**
   - Add `https://www.googleapis.com/auth/drive.file`
   - Click **Update**, then **Save and Continue**
6. On the **Test users** page, add your Google account email
7. Click **Save and Continue**, then **Back to Dashboard**

### Step 4: Create an iOS OAuth Client ID

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Application type: **iOS**
4. Bundle ID: `com.mindfulbites.app`
5. Click **Create**
6. Note the **Client ID** (looks like `123456789-abcdef.apps.googleusercontent.com`)

### Step 5: Update Info.plist

Edit `MindfulBites/Info.plist` and replace the placeholder values:

```xml
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
    </dict>
</array>
```

The URL scheme is the client ID reversed: if your client ID is `123456789-abcdef.apps.googleusercontent.com`, the URL scheme is `com.googleusercontent.apps.123456789-abcdef`.

### Step 6: Build and Verify

```bash
xcodebuild -project MindfulBites.xcodeproj -scheme MindfulBites \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Launch the app. Navigate to **Settings > Cloud Backup**. The "Sign in with Google Drive" button should be visible. Tapping it should open Google's sign-in flow (requires a real device or simulator with Google account signed in).

> **Note:** Google Sign-In works on the iOS Simulator but you need a Google account configured on the simulator. For the most reliable testing, use a physical device.

### Step 7: Verify Drive Folder Structure (Optional)

After a successful backup, verify the folder structure in Google Drive:

```
My Drive/
  .mindfulBites/
    manifest.json
    backups/
      backup_<ISO8601>.json
    photos/
      food_<UUID>_<timestamp>.jpg
```

You can check this via the Google Drive web UI or the API Explorer.

---

## Test Data Setup

Before running through the test cases, populate the app with representative data:

1. **Food entries** (5+): spread across different days, different meal types, some with photos, some with tags
2. **Weight entries** (5+): at least 2 within the last 7 days to trigger trend calculation
3. **Tags** (3+): assign multiple tags to some food entries to test many-to-many relationships
4. **Photos** (2+): attach photos to food entries via camera or photo library

---

## 1. Settings Tab — Weight Unit

| # | Test Case | Steps | Expected Result |
|---|-----------|-------|-----------------|
| 1.1 | Default unit | Fresh install, open Settings | Weight unit picker shows "lbs" |
| 1.2 | Change to kg | Tap picker, select "kg" | Picker updates to "kg" |
| 1.3 | Persistence | Change to kg, force-quit app, relaunch, open Settings | Still shows "kg" |
| 1.4 | Insights reflects unit | Set to kg, open Insights tab | Weight trend card shows "kg" unit |
| 1.5 | Switch back | Change from kg to lbs | All weight displays update to lbs |

---

## 2. Settings Tab — Weight Reminder Notifications

### 2.1 Enable Reminder (First Time)

**Precondition:** Fresh install, notifications never requested.

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Settings | Reminder toggle is OFF, no date picker visible |
| 2 | Toggle "Weight Logging Reminder" ON | System notification permission alert appears |
| 3 | Tap "Allow" | Toggle stays ON, date picker appears showing 8:00 AM |

### 2.2 Enable Reminder (Permission Denied)

**Precondition:** Previously denied notification permission in system settings.

| Step | Action | Expected |
|------|--------|----------|
| 1 | Toggle reminder ON | Alert: "Notifications Disabled — Please enable notifications in Settings to receive reminders" |
| 2 | Tap "Open Settings" | Navigates to iOS Settings for MindfulBites |
| 3 | Tap "Cancel" instead | Alert dismisses, toggle reverts to OFF |

### 2.3 Change Reminder Time

| Step | Action | Expected |
|------|--------|----------|
| 1 | With reminder enabled, tap date picker | Time picker opens |
| 2 | Change to 7:00 AM | Picker updates, notification rescheduled |
| 3 | Force-quit and relaunch | Date picker still shows 7:00 AM |

### 2.4 Disable Reminder

| Step | Action | Expected |
|------|--------|----------|
| 1 | Toggle reminder OFF | Date picker disappears |
| 2 | Verify in iOS Settings > Notifications | Pending notification removed |

### 2.5 Notification Content

When the reminder fires, verify:
- **Title:** "Morning weigh-in"
- **Body:** "A great time to log your weight."
- **Sound:** Default system sound

### 2.6 Edge Case — Midnight Reminder

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set reminder to 12:00 AM (midnight) | Picker shows 12:00 AM |
| 2 | Force-quit and relaunch | Still shows 12:00 AM (not reset to 8:00 AM) |

> This tests the `weightReminderHourSet` sentinel key that distinguishes "never set" from "explicitly set to 0".

---

## 3. Settings Tab — Meal Time Customization

### 3.1 View Defaults

| Step | Action | Expected |
|------|--------|----------|
| 1 | Settings > Customize Meal Times | Three sections: Breakfast, Lunch, Dinner |
| 2 | Verify defaults | Breakfast 6:00–8:00 AM, Lunch 11:00 AM–1:00 PM, Dinner 4:30–7:30 PM |
| 3 | Verify footer text | Breakfast: "Food logged during this time will default to Breakfast" |
| 4 | Verify footer text | Dinner: "Times outside these ranges will default to Snack" |

### 3.2 Modify Meal Times

| Step | Action | Expected |
|------|--------|----------|
| 1 | Change Breakfast start to 5:30 AM | Picker updates |
| 2 | Change Breakfast end to 9:00 AM | Picker updates |
| 3 | Navigate back, re-enter | Shows 5:30–9:00 AM |
| 4 | Create food entry at 5:45 AM | Auto-suggests "Breakfast" |
| 5 | Create food entry at 10:00 AM | Auto-suggests "Snack" |

### 3.3 Overnight Meal Range

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set Dinner to 10:00 PM start, 1:00 AM end | Pickers update |
| 2 | Create food entry at 11:30 PM | Auto-suggests "Dinner" |
| 3 | Create food entry at 12:30 AM | Auto-suggests "Dinner" |
| 4 | Create food entry at 2:00 AM | Auto-suggests "Snack" |

### 3.4 Reset to Defaults

| Step | Action | Expected |
|------|--------|----------|
| 1 | Modify all meal times | Customized values shown |
| 2 | Tap "Reset to Defaults" | Confirmation dialog: "Reset Meal Times — This will reset all meal times to their default values." |
| 3 | Tap "Reset to Defaults" in dialog | All times revert to defaults |
| 4 | Tap "Cancel" instead (repeat from step 2) | Custom times preserved |

---

## 4. Cloud Backup — Sign-In / Sign-Out

### 4.1 Signed-Out State

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Settings > Cloud Backup | "Sign in with Google Drive" button visible |
| 2 | No other controls shown | No backup/restore/sign-out buttons |
| 3 | Footer text | "Back up your data to keep it safe across devices" |

### 4.2 Sign-In Flow

**Precondition:** Google Drive credentials configured per Preamble.

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap "Sign in with Google Drive" | Google sign-in sheet appears |
| 2 | Select Google account | Permission scope screen shows |
| 3 | Tap "Allow" | Sheet dismisses, UI updates to signed-in state |
| 4 | Verify signed-in UI | Email shown, "Back Up Now" button, "Restore from Backup" link, "Sign Out" button |

### 4.3 Sign-In Cancelled

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap "Sign in with Google Drive" | Google sign-in sheet appears |
| 2 | Dismiss/cancel the sheet | Error alert may appear briefly; UI stays in signed-out state |

### 4.4 Sign Out

| Step | Action | Expected |
|------|--------|----------|
| 1 | While signed in, tap "Sign Out" | UI reverts to signed-out state |
| 2 | Verify | "Sign in with Google Drive" button reappears |

### 4.5 Session Restore on App Relaunch

| Step | Action | Expected |
|------|--------|----------|
| 1 | Sign in to Google Drive | Signed-in UI shown |
| 2 | Force-quit app | — |
| 3 | Relaunch app, open Settings | Automatically signed in (email shown) |
| 4 | Sign out, force-quit, relaunch | Stays signed out |

---

## 5. Cloud Backup — Backup

### 5.1 Perform Backup

**Precondition:** Signed in, app has food/weight entries with photos and tags.

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap "Back Up Now" | Progress indicator appears |
| 2 | Observe progress messages | Messages cycle through: preparing, creating folders, uploading photos, uploading data, cleaning up |
| 3 | Backup completes | Progress disappears, "Last Backup" timestamp shown |
| 4 | Timestamp format | Abbreviated date + short time (e.g., "Feb 9, 2026 at 3:30 PM") |

### 5.2 Backup — Empty App

| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete all entries | Empty app |
| 2 | Tap "Back Up Now" | Backup succeeds (0 entries, 0 photos) |
| 3 | Verify | Timestamp updated |

### 5.3 Backup — Photo Upload Partial Failure

**Precondition:** Simulated by toggling airplane mode mid-backup, or by deleting a photo file from disk before backup.

| Step | Action | Expected |
|------|--------|----------|
| 1 | Trigger condition where some photos fail to upload | Backup continues |
| 2 | After backup completes | Alert: "Backup Completed with Warnings — X photo(s) could not be uploaded" |
| 3 | JSON data still uploaded | Backup usable for restore (minus failed photos) |

### 5.4 Backup — Complete Failure

| Step | Action | Expected |
|------|--------|----------|
| 1 | Disable network (airplane mode) | — |
| 2 | Tap "Back Up Now" | Progress starts, then fails |
| 3 | Error shown | Red warning text with error message |
| 4 | Sync state resets | "Back Up Now" button reappears (state returns to idle) |

### 5.5 Backup Retention (Max 5)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Perform 6+ backups | Each succeeds |
| 2 | Check Google Drive `.mindfulBites/backups/` | Only 5 most recent backup JSON files remain |

---

## 6. Cloud Backup — Restore

### 6.1 View Backup List

**Precondition:** Signed in, at least one backup exists.

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap "Restore from Backup" | Loading spinner: "Loading backups..." |
| 2 | List loads | Each backup shows: date, device name, entry counts (food/weight/tag/photo icons) |

### 6.2 No Backups

| Step | Action | Expected |
|------|--------|----------|
| 1 | Sign in with account that has no backups | — |
| 2 | Tap "Restore from Backup" | Empty state: cloud-slash icon, "No Backups", "You haven't created any backups yet." |

### 6.3 Load Error

| Step | Action | Expected |
|------|--------|----------|
| 1 | Disable network before tapping restore | — |
| 2 | Tap "Restore from Backup" | Error state: warning icon, "Could Not Load Backups", error message |

### 6.4 Restore Confirmation

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap a backup in the list | Confirmation dialog appears |
| 2 | Dialog content | "Restore Backup" title, "This will replace all current data with the backup from [date]. This action cannot be undone." |
| 3 | "Restore" button is red (destructive) | — |
| 4 | Tap "Cancel" | Dialog dismisses, nothing happens |

### 6.5 Perform Restore

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap a backup, then tap "Restore" | Progress messages: downloading backup, downloading photos, clearing data, restoring, finalizing |
| 2 | Restore completes | View dismisses |
| 3 | Verify Food tab | All food entries from backup present |
| 4 | Verify Weight tab | All weight entries from backup present |
| 5 | Verify tags | Tags and food-tag associations preserved |
| 6 | Verify photos | Photos display correctly on food entries |
| 7 | Verify Settings | Weight unit, reminder settings, meal times match backup |

### 6.6 Restore with Missing Photos

| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete some photos from Google Drive `.mindfulBites/photos/` | — |
| 2 | Restore that backup | Some photo downloads fail |
| 3 | Alert | "Restore Completed with Warnings — X photo(s) could not be downloaded" |
| 4 | Food entries still restored | Entries present but without the missing photos |

### 6.7 Version Mismatch

| Step | Action | Expected |
|------|--------|----------|
| 1 | Manually edit a backup's manifest in Google Drive to set `appVersion` to "99.0" | — |
| 2 | Attempt to restore that backup | Error: "This backup was created with a newer version of the app (v99.0). Please update MindfulBites to restore it." |

### 6.8 Restore Failure

| Step | Action | Expected |
|------|--------|----------|
| 1 | Disable network mid-restore (or delete the backup JSON from Drive) | — |
| 2 | Restore fails | Error alert shown |
| 3 | Verify local data | Original data should remain intact (staged restore is atomic) |

---

## 7. Insights Tab

### 7.1 Empty State

| Step | Action | Expected |
|------|--------|----------|
| 1 | Fresh app (no data), open Insights tab | Chart icon, "No Data Yet", "Start logging food and weight to see your insights" |

### 7.2 Streaks — Current Streak

| Scenario | Data | Expected |
|----------|------|----------|
| No entries | — | Current Streak: 0 days |
| Entry today only | 1 entry today | Current Streak: 1 day |
| Today + yesterday | Entries on both | Current Streak: 2 days |
| 3 consecutive days | Today, yesterday, day before | Current Streak: 3 days |
| Gap yesterday, entry today | Entry today, entry 2 days ago, no entry yesterday | Current Streak: 1 day |
| Entry yesterday but not today | Entry yesterday only | Current Streak: 1 day (grace period) |

### 7.3 Streaks — Longest Streak

| Scenario | Data | Expected |
|----------|------|----------|
| Single entry | 1 entry | Longest Streak: 1 day |
| 5 consecutive, gap, 3 consecutive | Jan 1-5, Jan 7-9 | Longest Streak: 5 days |
| Current streak is longest | 10 consecutive ending today | Longest Streak: 10 days |

### 7.4 Streak Card Display

| # | Check | Expected |
|---|-------|----------|
| 7.4.1 | Singular | "1 day" (not "1 days") |
| 7.4.2 | Plural | "0 days", "2 days", "99 days" |
| 7.4.3 | Icon | Flame icon for current, trophy for longest |

### 7.5 Weight Trend

| Scenario | Data (lbs) | Expected |
|----------|-----------|----------|
| No weight entries | — | "Log more weight to see trends", gray |
| 1 entry only | 150 lbs today | "Log more weight to see trends" |
| Stable (< 0.5 lbs change) | 150 → 150.2 in 7 days | "Holding steady", gray/secondary |
| Trending up | 150 → 152 in 7 days | "Trending upward", orange, arrow up, "+2.0 lbs" |
| Trending down | 155 → 150 in 7 days | "Trending downward", teal, arrow down, "-5.0 lbs" |
| Data older than 7 days only | Entries 30+ days ago | "Log more weight to see trends" |

### 7.6 Weight Trend — Unit Sensitivity

| # | Scenario | Expected |
|---|----------|----------|
| 7.6.1 | Unit = lbs, threshold 0.5 lbs | 0.4 lbs change = stable |
| 7.6.2 | Unit = kg, threshold ~0.23 kg | 0.2 kg change = stable |
| 7.6.3 | Switch unit while viewing | Trend card updates unit label |

### 7.7 Activity Stats

| Stat | Calculation | Example |
|------|-------------|---------|
| Days Logged | Unique calendar days with food entries | 3 entries on 2 days → "2" |
| Avg Meals/Day | Total food entries / unique days | 6 entries over 3 days → "2.0" |
| Total Entries | Count of all food entries | "7" |
| Weight Logs | Count of all weight entries | "12" |

### 7.8 Activity Stats — Layout

| Step | Action | Expected |
|------|--------|----------|
| 1 | View Insights with data | 4 stat cards in 2x2 grid |
| 2 | Each card shows | Icon (colored), large bold value, smaller title |

---

## 8. Food View — Gallery Filter

### 8.1 Filter Button Appearance

| State | Expected Icon |
|-------|---------------|
| No filters active | Outline funnel icon (`line.3.horizontal.decrease.circle`) |
| Any filter active | Filled funnel icon (`line.3.horizontal.decrease.circle.fill`) |

### 8.2 Date Range Filter

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open filter sheet | "Filter by date" toggle is OFF |
| 2 | Toggle ON | "From" and "To" date buttons appear |
| 3 | Tap "From", select date | Calendar picker opens, select start date |
| 4 | Tap "To", select date | End date picker opens (restricted: >= start date) |
| 5 | Tap "Apply" | Only entries within date range shown |
| 6 | Reopen filter | Dates preserved |

### 8.3 Meal Type Filter

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open filter sheet | No meal types selected |
| 2 | Tap "Breakfast" | Checkmark appears on Breakfast |
| 3 | Tap "Lunch" | Checkmark appears on Lunch (both selected) |
| 4 | Tap "Apply" | Only Breakfast and Lunch entries shown |
| 5 | Tap "Breakfast" again | Checkmark removed (deselect) |

### 8.4 Tag Filter

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open filter sheet, scroll to Tags | Tags displayed in wrapping flow layout |
| 2 | Tap a tag | Tag highlighted (blue background) |
| 3 | Tap another tag | Both highlighted |
| 4 | Tap "Apply" | Entries with ANY selected tag shown (OR logic) |
| 5 | No tags created | "No tags created yet" message |

### 8.5 Combined Filters

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set date range + meal type + tag | All three active |
| 2 | Tap "Apply" | Only entries matching ALL filter types shown |
| 3 | Filter icon | Filled (active) |

### 8.6 Clear Filters

| Step | Action | Expected |
|------|--------|----------|
| 1 | With active filters, open filter sheet | — |
| 2 | Tap "Clear Filters" | All selections cleared |
| 3 | Button disabled | "Clear Filters" grayed out (no filters active) |
| 4 | Tap "Apply" | All entries shown again |

### 8.7 Cancel Without Applying

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open filter, change selections | — |
| 2 | Tap "Cancel" | Sheet dismisses, previous filters unchanged |

### 8.8 Empty State with Filters

| Step | Action | Expected |
|------|--------|----------|
| 1 | Apply filter that matches no entries | "No Matching Entries" with magnifying glass icon |
| 2 | "Clear Filters" button shown | Tap it to reset |

### 8.9 View Mode Toggle

| Step | Action | Expected |
|------|--------|----------|
| 1 | Default view | Timeline mode (list icon highlighted) |
| 2 | Tap gallery icon | Switches to grid view with animation |
| 3 | Tap timeline icon | Switches back to list view |
| 4 | Filters persist | Switching modes doesn't reset filters |

---

## 9. Cross-Feature Integration

### 9.1 Backup → Restore → Verify All Data

| Step | Action | Expected |
|------|--------|----------|
| 1 | Populate app with diverse data | Food entries (with photos, tags, meal types), weight entries, custom settings |
| 2 | Note exact counts | Food: X, Weight: Y, Tags: Z, Photos: W |
| 3 | Perform backup | Success |
| 4 | Delete all local data or fresh install | Empty app |
| 5 | Sign in, restore the backup | Success |
| 6 | Verify Food tab | All entries present with correct dates, meal types, notes |
| 7 | Verify photos | All photos display correctly |
| 8 | Verify tags | Tags exist, food-tag associations intact |
| 9 | Verify Weight tab | All entries present |
| 10 | Verify Settings | Weight unit, reminder toggle/time, meal time ranges all match |
| 11 | Verify Insights | Streaks, trends, activity stats correct for restored data |

### 9.2 Settings Change → Insights Update

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set weight unit to lbs, add weight entries | Trend shows lbs |
| 2 | Switch to kg in Settings | Trend card updates to show kg |

### 9.3 Meal Time Change → Food Entry Suggestion

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set Breakfast to 5:00–10:00 AM | — |
| 2 | At 9:30 AM, add new food entry | Meal type auto-suggests "Breakfast" |
| 3 | Reset meal times to default | — |
| 4 | At 9:30 AM, add new food entry | Meal type auto-suggests "Snack" (outside default 6–8 AM) |

### 9.4 Notification Restore via Backup

| Step | Action | Expected |
|------|--------|----------|
| 1 | Enable reminder at 6:00 AM, backup | — |
| 2 | Disable reminder, verify no notification scheduled | — |
| 3 | Restore backup | Reminder setting restored |
| 4 | Verify notification rescheduled at 6:00 AM | Check iOS Settings or wait for notification |

---

## 10. Edge Cases & Error Recovery

| # | Scenario | Steps | Expected |
|---|----------|-------|----------|
| 10.1 | Network loss during backup | Start backup, toggle airplane mode | Error alert, sync state resets to idle |
| 10.2 | Network loss during restore | Start restore, toggle airplane mode | Error alert, original local data intact |
| 10.3 | Sign out mid-backup | Sign out while backup in progress | Backup fails gracefully, state resets |
| 10.4 | Google Drive scope revoked | Revoke Drive scope in Google account settings, relaunch | Auth state returns to signed-out |
| 10.5 | Duplicate backup same second | Tap "Back Up Now" twice rapidly | Only one backup runs (button disabled during sync) |
| 10.6 | Entry with nil meal type | Create entry, filter by meal type | Entry excluded from meal type filter results |
| 10.7 | Entry with no tags | Create entry without tags, filter by tag | Entry excluded from tag filter results |
| 10.8 | Overnight meal range boundary | Dinner 10 PM–1 AM, entry at exactly 1:00 AM | Should be "Snack" (range is exclusive of end) |
| 10.9 | Restore old backup (no UUID id) | Backup from before UUID migration | UUID auto-generated during decode, restore works |
| 10.10 | Restore old backup (no backupFileName) | Backup from before filename field added | Falls back to reconstructed filename via `resolvedBackupFileName` |

---

## Quick Checklist

### Settings Tab
- [ ] Weight unit picker works and persists
- [ ] Reminder toggle requests permissions correctly
- [ ] Reminder time picker appears/disappears with toggle
- [ ] Midnight reminder time persists (not reset to 8 AM)
- [ ] Meal time customization saves and loads
- [ ] Overnight meal ranges work
- [ ] Reset to defaults with confirmation dialog
- [ ] About section shows version 1.0.0

### Cloud Backup
- [ ] Signed-out UI: only sign-in button
- [ ] Sign-in flow completes successfully
- [ ] Signed-in UI: email, backup, restore, sign-out
- [ ] Backup shows progress, completes, updates timestamp
- [ ] Backup retains max 5 files
- [ ] Backup with photo failures shows warning
- [ ] Backup failure resets sync state to idle
- [ ] Restore lists backups with correct metadata
- [ ] Restore confirmation dialog with destructive styling
- [ ] Restore replaces all data atomically
- [ ] Restore with missing photos shows warning
- [ ] Restore version check blocks newer versions
- [ ] Sign-out clears UI state
- [ ] Session auto-restores on app relaunch

### Insights Tab
- [ ] Empty state when no data
- [ ] Current streak calculates correctly
- [ ] Longest streak calculates correctly
- [ ] Streak singular/plural display
- [ ] Weight trend up/down/stable/insufficient
- [ ] Trend threshold respects weight unit
- [ ] Activity stats: days logged, avg meals, total entries, weight logs
- [ ] Stats grid layout (2x2)

### Food View Filtering
- [ ] Filter icon changes when filters active
- [ ] Date range filter works
- [ ] Meal type filter works
- [ ] Tag filter works (OR logic)
- [ ] Combined filters work
- [ ] Clear filters resets everything
- [ ] Cancel discards changes
- [ ] Empty filter result shows "No Matching Entries"
- [ ] View mode toggle preserves filters
