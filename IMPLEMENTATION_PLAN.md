# Mindful Bites - Implementation Plan

A privacy-focused iOS app for mindful food and weight tracking. Emphasizes awareness without anxiety - no calories, no macros, no judgmental metrics.

## Tech Stack
- **SwiftUI** (iOS 17+) - Modern declarative UI
- **SwiftData** - Local persistence (no cloud)
- **Swift Charts** - Weight visualization
- **Local Notifications** - Reminders

## Architecture: Simplified MVVM

```
Views (SwiftUI) → ViewModels (@Observable) → Models (SwiftData) → Services
```

---

## Data Models

### FoodEntry
```swift
@Model class FoodEntry {
    var id: UUID
    var createdAt: Date
    var text: String?              // Optional description
    var photoFileName: String?     // Reference to local file (not stored in DB)
    var mealType: MealType?        // Optional: breakfast/lunch/dinner/snack
    var tags: [Tag]                // Custom user tags
}
```

### WeightEntry
```swift
@Model class WeightEntry {
    var id: UUID
    var date: Date                 // One per calendar day
    var weight: Double             // Stored in kg internally
    var notes: String?             // Optional context
}
```

### Tag
```swift
@Model class Tag {
    var id: UUID
    var name: String
    var entries: [FoodEntry]       // Inverse relationship
}
```

### UserSettings (UserDefaults)
- `weightUnit`: lbs | kg
- `foodReminderEnabled`: Bool + time
- `weightReminderEnabled`: Bool + time

---

## App Structure

### Tab Navigation (4 Tabs)
| Tab | Icon | Purpose |
|-----|------|---------|
| Food | `fork.knife` | Food log with timeline/gallery toggle |
| Weight | `scalemass` | Log weight + line graph trends |
| Insights | `chart.bar` | Streaks + gentle trends |
| Settings | `gear` | Units, reminders |

### Key Screens

**Food** (Primary Tab)
- Segmented control or toggle at top: Timeline | Gallery
- FAB or nav button to add new entry (visible in both modes)

*Timeline Mode:*
- Grouped by day with headers ("Today", "Yesterday", dates)
- Shows photo thumbnail + text for each entry
- Chronological journal view

*Gallery Mode:*
- LazyVGrid of food photos
- Text-only entries excluded from grid
- Filter button → sheet with date range picker, tag multi-select
- Tap photo → detail view

**Add Food Entry** (Sheet)
- Camera button → capture photo
- Photo picker → select from library
- Text field for description
- Optional meal type picker
- Optional tag selector
- Requirement: photo OR text (at least one)

**Weight**
- Line chart (Swift Charts) with timeframe picker
- Timeframes: 1W, 1M, 3M, 1Y, All
- List of recent entries below chart
- Add weight sheet with optional notes
- One entry per day (update if exists)

**Insights**
- Current streak (days logged food)
- Longest streak
- Total days logged
- Weight trend: up/down/stable (gentle language)
- Average meals per day

**Settings**
- Weight unit toggle (lbs/kg)
- Food reminder: toggle + time picker
- Weight reminder: toggle + time picker

---

## File Structure

```
MindfulBites/
├── MindfulBitesApp.swift
├── ContentView.swift                 # TabView (4 tabs)
├── Models/
│   ├── FoodEntry.swift
│   ├── WeightEntry.swift
│   ├── Tag.swift
│   ├── MealType.swift
│   ├── WeightUnit.swift
│   └── Timeframe.swift
├── Views/
│   ├── Food/
│   │   ├── FoodView.swift            # Container with timeline/gallery toggle
│   │   ├── FoodTimelineView.swift    # Timeline mode content
│   │   ├── FoodGalleryView.swift     # Gallery mode content
│   │   ├── FoodEntryRow.swift        # Row for timeline
│   │   ├── GalleryGridItem.swift     # Cell for gallery
│   │   ├── GalleryFilterSheet.swift  # Filter options
│   │   ├── AddFoodEntryView.swift    # Add entry sheet
│   │   └── FoodEntryDetailView.swift # Entry detail view
│   ├── Weight/
│   │   ├── WeightView.swift
│   │   ├── WeightChartView.swift
│   │   └── AddWeightSheet.swift
│   ├── Insights/
│   │   ├── InsightsView.swift
│   │   ├── StreakCard.swift
│   │   └── TrendCard.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Components/
│       ├── CameraPicker.swift        # UIKit wrapper
│       ├── TagPicker.swift
│       ├── MealTypePicker.swift
│       └── EmptyStateView.swift
├── ViewModels/
│   ├── FoodViewModel.swift           # Shared for timeline & gallery
│   ├── WeightViewModel.swift
│   └── InsightsViewModel.swift
├── Services/
│   ├── PhotoStorageService.swift     # Save/load photos to Documents
│   ├── NotificationService.swift
│   └── SettingsService.swift
└── Utilities/
    ├── Date+Extensions.swift
    └── Color+Theme.swift
```

---

## Implementation Order

### Phase 1: Foundation
- [x] 1. Create Xcode project (iOS 17+, SwiftUI)
- [x] 2. Set up folder structure
- [x] 3. Implement all data models (FoodEntry, WeightEntry, Tag)
- [x] 4. Configure ModelContainer in App file
- [x] 5. Create TabView with 4 tabs (placeholder views)

**Phase 1 Complete:** [x]

---

### Phase 2: Food Logging - Timeline
- [x] 6. Build PhotoStorageService (save/load photos to Documents dir)
- [x] 7. Create CameraPicker (UIKit wrapper for camera)
- [x] 8. Build AddFoodEntryView (camera, photo picker, text, meal type)
- [x] 9. Build FoodView container with timeline/gallery segmented control
- [x] 10. Build FoodTimelineView with day grouping
- [x] 11. Build FoodEntryRow component
- [x] 12. Build FoodEntryDetailView

**Phase 2 Complete:** [x]

---

### Phase 3: Food Logging - Gallery & Tags
- [x] 13. Implement Tag creation/management
- [x] 14. Add TagPicker to entry creation
- [x] 15. Build FoodGalleryView with LazyVGrid
- [x] 16. Build GalleryFilterSheet (date range, tags)
- [x] 17. Add thumbnail caching for performance

**Phase 3 Complete:** [x]

---

### Phase 3.5: Food View Refinements
- [x] 13.5a. Add `title` field to FoodEntry model (defaults to timestamp)
- [x] 13.5b. Auto-select MealType based on time of day when creating entries
- [x] 13.5c. Compact header: remove "Food" title, inline toggle + filter + add button
- [x] 13.5d. Unify filtering: single filter state for both timeline and gallery views
- [x] 13.5e. Build EditFoodEntryView (edit title, description, photo, tags, meal type)
- [x] 13.5f. Add edit button to FoodEntryDetailView
- [x] 13.5g. Update FoodEntryRow to show title as primary text

**Default Meal Time Ranges (hardcoded initially):**
- Breakfast: 6:00 AM - 8:00 AM
- Lunch: 11:00 AM - 1:00 PM
- Dinner: 4:00 PM - 7:30 PM
- Snack: All other times

**Phase 3.5 Complete:** [x]

---

### Phase 4: Weight Tracking
- [x] 18. Build AddWeightSheet
- [x] 19. Build WeightView with entry list
- [x] 20. Implement one-entry-per-day logic
- [x] 21. Build WeightChartView with Swift Charts
- [x] 22. Add timeframe picker (1W/1M/3M/1Y/All)
- [x] 23. Implement unit conversion (stored kg, display per setting)

**Phase 4 Complete:** [x]

---

### Phase 5: Insights & Settings
- [ ] 24. Build InsightsView layout
- [ ] 25. Implement streak calculations
- [ ] 26. Implement trend detection (up/down/stable)
- [ ] 27. Build SettingsView
- [ ] 28. Implement SettingsService (UserDefaults)
- [ ] 29. Set up NotificationService
- [ ] 30. Wire up reminder scheduling
- [ ] 31. Add customizable meal time ranges to Settings
  - User can set start/end times for Breakfast, Lunch, Dinner
  - Times outside these ranges default to Snack
  - Supports shift workers and non-standard schedules

**Phase 5 Complete:** [ ]

---

### Phase 6: Polish
- [ ] 32. Add empty states for all views
- [ ] 33. Error handling (permissions, storage)
- [ ] 34. Add app icon and launch screen
- [ ] 35. Test on device

**Phase 6 Complete:** [ ]

---

## Key Technical Notes

### Photo Storage
Photos stored in Documents directory (NOT in SwiftData):
- Filename format: `food_{UUID}_{timestamp}.jpg`
- SwiftData stores only the filename reference
- PhotoStorageService handles all file operations
- Delete photo file when entry is deleted

### Camera Access
SwiftUI has no native camera view. Use UIKit wrapper:
```swift
struct CameraPicker: UIViewControllerRepresentable {
    // Wraps UIImagePickerController with sourceType: .camera
}
```

Required Info.plist entries:
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

### Weight Entry Uniqueness
One entry per calendar day - on save:
1. Query for existing entry on that calendar day
2. If exists → update it
3. If not → create new

### Unit Conversion
- Always store weight in kg internally
- Convert for display based on user setting
- `WeightUnit.convert(fromKg:)` and `convertToKg(from:)`

### Streak Calculation
```swift
// Get unique days with entries, sorted descending
// Start from today/yesterday, count consecutive days backward
// Break when gap found
```

---

## Design Principles

- **Calm color palette**: Soft sage green, warm cream, no harsh reds
- **Generous whitespace**: Don't crowd the interface
- **Soft corners**: 12pt+ corner radius
- **Encouraging language**: "Great job logging!" not "You missed days"
- **No anxiety metrics**: No calories, no red warnings, no streaks shown as failures

---

## Verification Plan

- [ ] 1. **Build & Run**: Project compiles and launches on iOS 17+ simulator
- [ ] 2. **Food Tab - Timeline Mode**:
   - Open app → Food tab shows timeline by default
   - Tap add → take/select photo → add text → save
   - Entry appears in timeline grouped under today
- [ ] 3. **Food Tab - Gallery Mode**:
   - Toggle to gallery view → photos display in grid
   - Text-only entries not shown in gallery
   - Filter by date range and tags works
   - Toggle back to timeline → same data, different view
- [ ] 4. **Weight Logging Flow**:
   - Tap Weight tab → add weight → entry appears in list
   - Chart shows the data point
   - Adding second entry same day updates (not duplicates)
- [ ] 5. **Insights**:
   - Log food for 3 consecutive days → streak shows 3
   - Weight trend reflects actual direction
- [ ] 6. **Settings**:
   - Toggle units → weight display changes everywhere
   - Enable reminder → notification scheduled (check Settings app)
- [ ] 7. **Permissions**:
   - Deny camera → graceful handling, photo picker still works
   - Deny notifications → app works, just no reminders

---

## Not In Scope (v1)
- iCloud sync
- Data export
- Apple Watch
- Widgets
- Dark mode customization (uses system)
