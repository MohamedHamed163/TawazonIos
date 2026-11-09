# ✅ watchOS Setup - Code Changes Complete!

## 🎉 What's Been Done

All code changes from the watchOS setup plan have been completed:

### ✅ 1. SharedDefaultsHelper Created
- **File:** `tawazon/Services/SharedDefaultsHelper.swift`
- Provides App Group UserDefaults for sharing data between iOS and watchOS
- App Group ID: `group.com.tawazon.app` (update if needed)

### ✅ 2. Managers Updated with Shared Instances

**ThemeManager:**
- ✅ Added `static let shared = ThemeManager()`
- ✅ Updated to use `SharedDefaultsHelper.shared` instead of `UserDefaults.standard`
- ✅ Platform-specific initialization (iOS vs watchOS)

**LanguageManager:**
- ✅ Added `static let shared = LanguageManager()`
- ✅ Updated to use `SharedDefaultsHelper.shared` instead of `UserDefaults.standard`

**AuthManager:**
- ✅ Added `static let shared = AuthManager()`

### ✅ 3. watchOS App Files Created

All watchOS view files are ready:
- ✅ `TawazonWatch/TawazonWatchApp.swift` - App entry point
- ✅ `TawazonWatch/Views/ContentView.swift` - Main tab view
- ✅ `TawazonWatch/Views/StatsView.swift` - Quick stats
- ✅ `TawazonWatch/Views/WorkoutView.swift` - Workout controls
- ✅ `TawazonWatch/Views/SettingsView.swift` - Settings

### ✅ 4. Setup Script Created

Run `./setup_watchos.sh` for a quick reference guide.

---

## 📋 What You Need to Do in Xcode

Since Xcode project configuration can't be done via terminal, follow these steps:

### Step 1: Add watchOS Target

1. Open `tawazon.xcodeproj` in Xcode
2. **File → New → Target...**
3. Select **watchOS** tab → **App**
4. Name: `TawazonWatch`
5. Click **Finish** and **Activate** the scheme

### Step 2: Share Files Between Targets

For each file below, select it in Xcode and check both targets in **File Inspector** → **Target Membership**:

**Services:**
- ✅ `Services/AuthManager.swift`
- ✅ `Services/ThemeManager.swift`
- ✅ `Services/LanguageManager.swift`
- ✅ `Services/APIService.swift`
- ✅ `Services/HealthKitService.swift`
- ✅ `Services/SharedDefaultsHelper.swift`
- ✅ `Services/KeychainService.swift`

**Design System:**
- ✅ `DesignSystem/ColorTheme.swift`
- ✅ `DesignSystem/GenderColorTheme.swift`
- ✅ `DesignSystem/Typography.swift`

**Models:**
- ✅ `Models/APIResponseModels.swift`

**Resources:**
- ✅ `Resources/Localizable.strings`
- ✅ `Resources/en.lproj/Localizable.strings`
- ✅ `Resources/ar.lproj/Localizable.strings`

### Step 3: Add watchOS Files to Project

1. In Xcode, right-click on project root
2. **Add Files to "tawazon"...**
3. Select `tawazon/TawazonWatch/` folder
4. Make sure:
   - ✅ **Copy items if needed** is checked
   - ✅ **Create groups** is selected
   - ✅ **TawazonWatch** target is checked
   - ✅ **tawazon** target is NOT checked

### Step 4: Enable App Groups

**For iOS Target:**
1. Select **tawazon** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Select **App Groups**
5. Click **+** and add: `group.com.tawazon.app`
6. Check the checkbox next to it

**For watchOS Target:**
1. Select **TawazonWatch** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Select **App Groups**
5. Click **+** and add: `group.com.tawazon.app`
6. Check the checkbox next to it

**Important:** Both targets must use the **same App Group ID**!

### Step 5: Update App Group ID (if needed)

If your bundle identifier is different, update `SharedDefaultsHelper.swift`:

```swift
static let appGroupID = "group.com.yourcompany.tawazon"
```

Replace `com.yourcompany` with your actual bundle identifier prefix.

### Step 6: Test

1. Select **TawazonWatch** scheme from the scheme selector
2. Choose a watch simulator (e.g., Apple Watch Series 8, 45mm)
3. Press **⌘R** to run
4. The watch app should launch!

---

## ✅ Checklist

- [x] SharedDefaultsHelper.swift created
- [x] ThemeManager updated with shared instance
- [x] LanguageManager updated with shared instance
- [x] AuthManager updated with shared instance
- [x] All managers use SharedDefaultsHelper
- [x] watchOS view files created
- [ ] watchOS target added in Xcode (manual)
- [ ] Shared files added to both targets (manual)
- [ ] watchOS files added to project (manual)
- [ ] App Groups enabled for both targets (manual)
- [ ] Tested on simulator

---

## 🚨 Troubleshooting

### "Cannot find type 'ThemeManager'"
→ Make sure `ThemeManager.swift` is added to **TawazonWatch** target in Target Membership

### "No such module"
→ Check that all shared files have **TawazonWatch** checked in Target Membership

### "App Group not working"
→ Verify both iOS and watchOS targets have the **same App Group ID** enabled

### "SharedDefaultsHelper.shared returns standard UserDefaults"
→ App Groups capability not enabled. Enable it in Signing & Capabilities for both targets.

### watchOS app crashes on launch
→ Make sure all required files are added to watchOS target, especially:
  - SharedDefaultsHelper.swift
  - All manager files
  - Design system files
  - Models

---

## 📱 Next Steps After Setup

1. **Implement HealthKit Workout Tracking**
   - Use HealthKitService on watchOS
   - Start/stop workout sessions
   - Track real-time metrics

2. **Add WatchConnectivity**
   - Real-time sync between iPhone and Apple Watch
   - Send workout data from watch to phone

3. **Create Complications**
   - Show daily stats on watch face
   - Update from app data

4. **Enhance Workout View**
   - Add timer functionality
   - Show heart rate, calories, distance
   - Save workout to HealthKit

---

## 🎯 Summary

**All code changes are complete!** ✅

You just need to:
1. Add watchOS target in Xcode
2. Share files between targets
3. Enable App Groups
4. Test!

The watchOS app is ready to run once you complete the Xcode configuration steps above.

---

**Need help?** Check `WATCHOS_SETUP.md` for detailed explanations!

