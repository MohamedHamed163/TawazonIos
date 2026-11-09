# watchOS App Setup Guide for Tawazon

This guide explains how to add a watchOS app to your Tawazon iOS project and what needs to be shared between platforms.

## 📋 Prerequisites

- Xcode 14.0 or later
- iOS 16.0+ deployment target
- watchOS 9.0+ deployment target
- Apple Developer account (for testing on real devices)

---

## 🚀 Step 1: Add watchOS Target in Xcode

### Manual Setup:

1. **Open your project in Xcode**
   - Open `tawazon.xcodeproj`

2. **Add a new target:**
   - Go to **File** → **New** → **Target...**
   - Select **watchOS** tab
   - Choose **App** (not App with WatchKit Extension)
   - Click **Next**

3. **Configure the target:**
   - **Product Name:** `TawazonWatch`
   - **Organization Identifier:** (same as your iOS app)
   - **Bundle Identifier:** `com.yourcompany.tawazon.watchkitapp`
   - **Language:** Swift
   - **Interface:** SwiftUI
   - **Include Notification Scene:** ✅ (optional, for notifications)
   - Click **Finish**

4. **Activate the scheme:**
   - Xcode will ask to activate the scheme - click **Activate**

---

## 📦 Step 2: Create Shared Framework/Target

To share code between iOS and watchOS, we need a shared framework.

### Option A: Shared Framework (Recommended)

1. **Add a new Framework target:**
   - **File** → **New** → **Target...**
   - Select **iOS** → **Framework**
   - Name: `TawazonShared`
   - Click **Finish**

2. **Configure the framework:**
   - Select the `TawazonShared` target
   - Go to **Build Settings**
   - Search for "Supported Platforms"
   - Add `watchos` to supported platforms
   - Or set **Supported Platforms** to: `$(PLATFORM_NAME)`

3. **Move shared code to framework:**
   - Create folders in `TawazonShared`:
     - `Models/` - Data models
     - `Services/` - API, Auth, HealthKit services
     - `DesignSystem/` - Colors, Typography
     - `Resources/` - Localizable strings

### Option B: Shared Files (Simpler, but less organized)

- Add files to both targets:
  - Select a file in Xcode
  - Open **File Inspector** (right panel)
  - Under **Target Membership**, check both:
    - ✅ `tawazon` (iOS)
    - ✅ `TawazonWatch` (watchOS)

---

## 🔧 Step 3: Configure App Groups (for data sharing)

1. **Enable App Groups:**
   - Select iOS app target → **Signing & Capabilities**
   - Click **+ Capability** → **App Groups**
   - Add group: `group.com.yourcompany.tawazon`
   - Repeat for watchOS target

2. **Update UserDefaults to use App Group:**
   ```swift
   // In ThemeManager, LanguageManager, etc.
   static let appGroupID = "group.com.yourcompany.tawazon"
   static let sharedDefaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
   ```

---

## 📱 Step 4: Initial watchOS App Structure

### Files to Create:

```
TawazonWatch/
├── TawazonWatchApp.swift          # App entry point
├── Views/
│   ├── ContentView.swift          # Main watch view
│   ├── WorkoutView.swift          # Active workout
│   ├── StatsView.swift            # Quick stats
│   └── SettingsView.swift         # Watch settings
├── Models/
│   └── (Shared from iOS)
└── Resources/
    └── Assets.xcassets
```

---

## 🎨 Step 5: What to Share Between Platforms

### ✅ Share These:

1. **Models:**
   - `User`, `CoachProfileResponse`, `ProgramResponse`
   - `HealthSummary`, `ProgressLog`
   - All API response models

2. **Services:**
   - `APIService` (with modifications for watchOS)
   - `AuthManager` (read-only token access)
   - `HealthKitService` (watchOS has full HealthKit support)

3. **Design System:**
   - `ColorTheme` (colors)
   - `Typography` (font sizes - watchOS uses smaller sizes)
   - `GenderColorTheme`

4. **Resources:**
   - `Localizable.strings` (translations)

### ❌ Don't Share These:

1. **Views** - watchOS has different UI patterns
2. **Components** - Different component libraries
3. **Navigation** - Different navigation patterns

---

## 🔐 Step 6: Update Services for watchOS

### AuthManager (watchOS version):
```swift
#if os(watchOS)
// Read-only access to tokens
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    var accessToken: String? {
        // Read from App Group UserDefaults
        UserDefaults(suiteName: "group.com.yourcompany.tawazon")?.string(forKey: "access_token")
    }
}
#endif
```

### APIService (watchOS compatible):
```swift
// Make sure URLSession works on watchOS
// watchOS supports most networking features
```

---

## 📊 Step 7: watchOS-Specific Features

### HealthKit on watchOS:
- watchOS has **full HealthKit access**
- Can read AND write health data
- Perfect for workout tracking

### WorkoutKit (watchOS 9+):
- Native workout tracking
- Real-time metrics
- Background execution

### Complications:
- Show quick stats on watch face
- Update from app data

---

## 🏗️ Step 8: Build Configuration

### Update Build Settings:

1. **watchOS Deployment Target:**
   - Set to `watchOS 9.0` (or latest)

2. **Shared Framework:**
   - Make sure `TawazonShared` builds for watchOS
   - Check **Build Settings** → **Supported Platforms**

3. **Code Signing:**
   - Use same Team for both targets
   - Enable App Groups capability

---

## 🧪 Step 9: Testing

1. **Simulator:**
   - Select watchOS scheme
   - Choose a watch simulator (Series 8, Ultra, etc.)
   - Run the app

2. **Real Device:**
   - Pair Apple Watch with iPhone
   - Install iOS app first
   - Then install watchOS app
   - Test data sharing via App Groups

---

## 📝 Next Steps After Setup

1. **Create initial watchOS views:**
   - Main dashboard
   - Quick stats
   - Workout controls

2. **Implement data sync:**
   - Use App Groups for UserDefaults
   - Use WatchConnectivity for real-time sync

3. **Add HealthKit integration:**
   - Read health data on watch
   - Start workouts from watch

4. **Add Complications:**
   - Show daily stats on watch face

---

## ⚠️ Common Issues

### Issue: "No such module 'TawazonShared'"
- **Solution:** Make sure framework target includes watchOS platform

### Issue: "Cannot find type in scope"
- **Solution:** Check Target Membership for shared files

### Issue: "App Group not working"
- **Solution:** Verify both targets have same App Group ID enabled

### Issue: "HealthKit not available"
- **Solution:** Add HealthKit capability to watchOS target

---

## 📚 Resources

- [Apple Watch App Programming Guide](https://developer.apple.com/documentation/watchkit)
- [WatchConnectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [HealthKit on watchOS](https://developer.apple.com/documentation/healthkit)

---

## 🎯 Recommended watchOS Features for Tawazon

1. **Quick Stats View:**
   - Today's steps, calories, heart rate
   - Sync from HealthKit

2. **Active Workout:**
   - Start/stop workouts
   - Show timer and metrics
   - Save to HealthKit

3. **Coach Notifications:**
   - Push notifications for workout reminders
   - Messages from coaches

4. **Complications:**
   - Daily step count
   - Active calories
   - Next workout time

---

## ✅ Checklist

- [ ] watchOS target added
- [ ] Shared framework created (or files shared)
- [ ] App Groups configured
- [ ] Services updated for watchOS
- [ ] Initial views created
- [ ] HealthKit capability added
- [ ] Tested on simulator
- [ ] Tested on real device

---

**Need help?** Check the implementation files I'll create next!

