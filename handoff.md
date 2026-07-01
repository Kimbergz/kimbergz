# LockedIn — Handoff Document

## Goal

A native iOS life-tracker sideloaded via Xcode Personal Team (free). Three sections: Study, Diet, Finance. All guilt-based — the app is designed to make the user feel accountable. User is Malaysian, saves in Ringgit (MYR), goal is to travel.

---

## Current State (as of 30 June 2026 — updated same day)

### What works

**Navigation**
- Top-left hamburger button (`line.3.horizontal`) opens a native iOS `Menu` to switch between Study / Diet / Finance sections
- Each section has its own bottom tab bar — no overflow into "More"
- Forced light mode throughout

**Study section** (tabs: Home, Focus, Log, History, Goals)
- Streak counter, today's total study time, subject progress bars
- Pomodoro timer (25/5/15 min phases), auto-logs sessions on completion
- Manual session logging with subject, duration, date, difficulty rating (Light / Easy / Meh / Hard / Fuck.)
- History grouped by day, swipe to delete
- Goals: set daily minute targets per subject with color picker
- Guilt screen on every app open — different message if goal met vs not, progress ring, dismiss counter resets at midnight
- 5 study notifications: 8am, 1pm, 8pm, 10pm daily + Sunday 7pm weekly report

**Diet section** (tabs: Today, Log, History, Goals)
- Today tab: calorie progress bar vs daily goal, macro summary grid (calories, protein, carbs, fats, fiber), today's meal list
- Log tab: manual entry — food name text field, sliders for macros (calories 0–2000 step 100, protein 0–200g step 5, carbs 0–300g step 5, fats 0–150g step 5, fiber 0–80g step 1), feeling buttons (Great/Fine/Meh/Gross), guilty toggle, tasty toggle
- History tab: one summary card per day showing daily totals (not individual entries); includes today so it updates live as you log
- Goals tab: set daily calorie limit, shows today's progress bar; number pad has a "Done" button to dismiss keyboard
- 6 diet notifications: 9am, 12pm, 2:30pm, 5pm, 7:30pm, 10pm — progressive "have you eaten since X?" messaging

**Finance section** (tabs: Today, Log, History, Goals)
- Today tab: spent today card, this month card, daily limit progress bar, monthly limit progress bar, travel reminder banner, today's expense list
- Log tab: amount (RM, typed), label, three guilt toggles (worth it / keeping it / beneficial), travel reminder nudge
- History tab: grouped by month, monthly total as large header, monthly limit progress bar, then daily sub-groupings
- Goals tab: set daily and monthly spending limits (RM), limits show as progress bars that turn red when exceeded
- 4 finance notifications: 10:30am, 3pm, 6:30pm, 9pm — no overlap with diet or study pings, each reminds user they're saving for travel

**Widget** (small + medium)
- Shows study/goal progress ring, streak, guilt message
- Shares data via App Groups (`group.al.akm.lockedin`)

**Design**
- LinkedIn light palette: background `#fdfaf5`, cards `#e9e5df`, accent `#0a66c2`, primary text `#004182`, secondary `#5E5E5E`
- Zero emojis — all replaced with SF Symbols
- System font (San Francisco) throughout

---

## Files

### App target (`LockedIn/`)

| File | Purpose |
|------|---------|
| `LockedInApp.swift` | App entry point, injects `AppData` + `SectionStore`, `AppDelegate` handles notification taps |
| `ContentView.swift` | Root view — switches entire TabView based on `SectionStore.section`, guilt screen overlay |
| `SectionStore.swift` | `AppSection` enum (study/diet/finance), `SectionStore` ObservableObject, `SectionMenuButton` view |
| `AppData.swift` | All persistence (UserDefaults `group.al.akm.lockedin`), all notifications, computed properties for study/diet/finance |
| `Subject.swift` | Subject model (name, dailyGoalMinutes, colorHex) |

### Views (`LockedIn/Views/`)

| File | Purpose |
|------|---------|
| `HomeView.swift` | Study home — streak, today total, subject progress bars |
| `FocusTimerView.swift` | Pomodoro timer with ring UI |
| `ManualLogView.swift` | Manual study session form |
| `HistoryView.swift` | Study history grouped by day, swipe to delete |
| `GoalsView.swift` | Subject goals list + add/edit sheet |
| `GuiltScreenView.swift` | Full-screen guilt overlay on app open |
| `DietView.swift` | Diet Today tab + `DietHistoryView` + `DayStat` + all shared diet components (MacroGrid, MacroCell, DietEntryRow, MacroPill) |
| `LogFoodView.swift` | Diet Log tab — manual macro entry with sliders |
| `DietGoalsView.swift` | Diet Goals tab — daily calorie limit |
| `FinanceView.swift` | All finance views: `FinanceView` (today), `LogExpenseView`, `FinanceHistoryView`, `FinanceGoalsView` + shared components (`LimitProgressRow`, `FinanceStatCard`, `FinanceEntryRow`) |

### Shared (`Shared/`)

| File | Purpose |
|------|---------|
| `StudySession.swift` | Study session model |
| `DietEntry.swift` | Diet entry model (foodName, calories, protein, carbs, fats, fiber, feeling, guilty, tasty) |
| `FinanceEntry.swift` | Finance entry model (amount, label, worthIt, keepIt, beneficial) |
| `Color+Hex.swift` | `Color(hex:)` initializer + app color constants |

### Widget (`LockedInWidget/`)
- `LockedInWidget.swift` — small + medium widget, reads from shared UserDefaults
- `LockedInWidgetBundle.swift` — widget bundle entry point

---

## Failed Attempts

### USDA FoodData Central API (diet food search)
- Integrated the API with a `FoodSearchService` using async/await
- Failed in production: JSON decoder crashed silently because `SearchNutrient.value` was non-optional — any nutrient missing a value failed the entire food item decode
- Attempted fix with optional fields — still showed "Search failed. Check your connection." on device
- **Decision:** scrapped entirely, replaced with manual macro sliders. User preferred this anyway.

### xcodegen not installed
- `project.yml` exists but `xcodegen` binary is not on the machine and Homebrew is not installed
- Every new Swift file must be manually registered in `LockedIn.xcodeproj/project.pbxproj` — file reference, build file entry, group membership, and sources build phase entry
- UUIDs used follow pattern `AA01000000000000000000XX` for diet files, `AA02000000000000000000XX` for finance files

### iOS tab bar 6-item overflow
- Added Diet as a 6th tab alongside the 5 study tabs — iOS collapsed extras into a "More" button
- Fixed by switching to the section-based navigation (hamburger menu + per-section tab bars)

### Inline `let` in ZStack body
- `DietHistoryView` used `let history = appData.dietEntriesByDay().filter { ... }` inside a `ZStack` body — SwiftUI's `@ViewBuilder` dropped the view silently
- Fixed by moving to a `private var history` computed property outside `body`

### Simulator launch failures
- `xcrun simctl launch` fails with "No such process" if the simulator hasn't fully booted
- Pattern that works: `xcrun simctl boot <UDID>` → `sleep 3` → install → launch
- iPhone 17 Pro simulator UDID: `D543D92A-2207-4DBA-9BCA-B87E773A1E7A`
- Build with explicit derived data path: `xcodebuild ... -derivedDataPath /tmp/lockedin-build`
- App binary at: `/tmp/lockedin-build/Build/Products/Debug-iphonesimulator/LockedIn.app`

---

## Next Steps (not yet built)

1. **Finance History** — currently shows monthly grouping with daily sub-groups; could add a "this month vs last month" comparison card at the top
2. **Diet History** — calorie goal comparison per day (show if goal was met or exceeded for each past day)
3. **App icon** — never added, shows blank in simulator and on device
4. **Export/import** — data lives only in UserDefaults; wiped if app is deleted. JSON export to Files app would protect against rebuilds resetting data
5. **iCloud backup** — no iCloud sync; data is device-local only
6. **Finance savings tracker** — user is saving for travel; could add a "savings goal" (target amount + current saved) separate from spending limits
7. **Diet macro goals** — currently only calorie goal; could add daily targets for protein/carbs/fats/fiber with individual progress bars
8. **Sideloading to phone** — Personal Team certificate expires every 7 days; just hit Run in Xcode, do not delete the app or UserDefaults resets. Requires paid $99/year Apple Developer account for App Store or Family Controls API (real app blocking)

---

## Build Commands

```bash
# Build for simulator
cd /Users/hakimi/LockedIn
xcodebuild -scheme LockedIn -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build -derivedDataPath /tmp/lockedin-build

# Install and launch on simulator
xcrun simctl boot D543D92A-2207-4DBA-9BCA-B87E773A1E7A 2>/dev/null
sleep 3
xcrun simctl install D543D92A-2207-4DBA-9BCA-B87E773A1E7A /tmp/lockedin-build/Build/Products/Debug-iphonesimulator/LockedIn.app
xcrun simctl launch D543D92A-2207-4DBA-9BCA-B87E773A1E7A al.akm.lockedin
open -a Simulator
```
