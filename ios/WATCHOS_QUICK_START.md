# watchOS Quick Start Guide

## 🎯 Quick Steps to Add watchOS App

### 1. In Xcode:

1. **File → New → Target...**
2. Select **watchOS** → **App**
3. Name: `TawazonWatch`
4. Click **Finish** and **Activate** the scheme

### 2. Share Code Between Platforms:

**Option A: Add files to both targets (Easiest)**
- Select a file (e.g., `AuthManager.swift`)
- In **File Inspector** (right panel)
- Under **Target Membership**, check:
  - ✅ `tawazon` (iOS)
  - ✅ `TawazonWatch` (watchOS)

**Files to share:**
- ✅ `Services/AuthManager.swift`
- ✅ `Services/ThemeManager.swift`
- ✅ `Services/LanguageManager.swift`
- ✅ `Services/APIService.swift`
- ✅ `Services/HealthKitService.swift`
- ✅ `DesignSystem/ColorTheme.swift`
- ✅ `DesignSystem/GenderColorTheme.swift`
- ✅ `Models/APIResponseModels.swift`
- ✅ `Resources/Localizable.strings`

### 3. Enable App Groups (for data sharing):

1. Select **iOS app target** → **Signing & Capabilities**
2. Click **+ Capability** → **App Groups**
3. Add: `group.com.yourcompany.tawazon`
4. Repeat for **watchOS target**

### 4. Update Services to Use App Groups:

**In `ThemeManager.swift`:**
```swift
// Replace UserDefaults.standard with:
private let defaults = SharedDefaultsHelper.shared
```

**In `LanguageManager.swift`:**
```swift
// Replace UserDefaults.standard with:
private let defaults = SharedDefaultsHelper.shared
```

**In `KeychainService.swift`:**
- Keychain automatically syncs between iOS and watchOS
- No changes needed!

### 5. Copy watchOS Files:

I've created initial watchOS files in:
- `tawazon/TawazonWatch/TawazonWatchApp.swift`
- `tawazon/TawazonWatch/Views/ContentView.swift`
- `tawazon/TawazonWatch/Views/StatsView.swift`
- `tawazon/TawazonWatch/Views/WorkoutView.swift`
- `tawazon/TawazonWatch/Views/SettingsView.swift`

**Add them to your watchOS target:**
- Drag files into Xcode
- Make sure **TawazonWatch** target is checked

### 6. Update Managers for Shared Instances:

**In `AuthManager.swift`, add:**
```swift
static let shared = AuthManager()
```

**In `ThemeManager.swift`, add:**
```swift
static let shared = ThemeManager()
```

**In `LanguageManager.swift`, add:**
```swift
static let shared = LanguageManager()
```

### 7. Test:

1. Select **TawazonWatch** scheme
2. Choose a watch simulator (Apple Watch Series 8, etc.)
3. Run (⌘R)

---

## ✅ Checklist

- [ ] watchOS target added in Xcode
- [ ] Shared files added to both targets
- [ ] App Groups enabled for both targets
- [ ] SharedDefaultsHelper.swift added
- [ ] Managers updated to use SharedDefaultsHelper
- [ ] Static `shared` instances added to managers
- [ ] watchOS view files added to project
- [ ] Tested on simulator

---

## 🚨 Common Issues

**"Cannot find type 'ThemeManager'"**
→ Make sure `ThemeManager.swift` is added to watchOS target

**"No such module"**
→ Check Target Membership for all shared files

**"App Group not working"**
→ Verify both targets have same App Group ID enabled

---

## 📱 Next Steps

1. Implement HealthKit workout tracking
2. Add WatchConnectivity for real-time sync
3. Create Complications for watch face
4. Add workout controls and metrics

See `WATCHOS_SETUP.md` for detailed guide!

