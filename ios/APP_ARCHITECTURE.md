# Tawazon App Architecture - iOS & watchOS

## 📱 Overview

Tawazon is a fitness coaching marketplace app available on both iOS and watchOS platforms. This document details what features and components are used in each platform.

---

## 🍎 iOS App (`tawazon`)

Aligned with the **Android (Kotlin)** feature set: same backend APIs, **SwiftUI** navigation and native iOS patterns.

### **Root & navigation**
- ✅ **Landing** marketing screen → Login / Register, or **guest browse** (coaches only)
- ✅ **`MainView`**: 4-tab `TabView` — **Home**, **Coaches**, **Sessions**, **Profile**
- ✅ Each tab owns a **`NavigationStack`**; typed routes in `Navigation/MainTabNavigation.swift`
- ✅ Push flows: notifications, today’s workout, exercise video, coach detail, book session, session confirmation, health record

**Files:**
- `tawazonApp.swift` — root: unauthenticated (landing/login/register) vs `MainView`
- `Views/MainView.swift`
- `Views/LandingView.swift`
- `Navigation/MainTabNavigation.swift`

### **1. Authentication & user**
- ✅ Login / Register (email, Apple, Google, biometrics)
- ✅ JWT access + refresh; **401 → refresh (single-flight) → retry**; on failure clear Keychain + `Notification.Name.tawazonSessionExpired`
- ✅ Guest browsing (`AuthManager.allowsGuestAccess`) without token for public coach list

**Files:**
- `Views/LoginView.swift`, `Views/SignUpView.swift`
- `Services/AuthManager.swift`, `Services/KeychainService.swift`, `Services/APIService.swift`

### **2. Home (dashboard)**
- ✅ **`GET /dashboard`**, **`GET /users/me/progress/summary`**, **`GET /coaches/featured`** (when no active subscription)
- ✅ HealthKit quick stats strip (when authorized)
- ✅ Subscription card, health-record banner, today’s workout card, progress summary
- ✅ Guest CTA to sign in / open Coaches tab

**Files:**
- `Views/HomeView.swift`
- `ViewModels/HomeViewModel.swift`

### **3. Today’s workout & video**
- ✅ **`GET /programs/today`**, **`PATCH /programs/today/complete`**, **`PATCH /programs/today/skip`**
- ✅ **`ExerciseVideoView`** (`AVKit`)

**Files:**
- `Views/TodayWorkoutView.swift`, `ViewModels/TodayWorkoutViewModel.swift`
- `Views/ExerciseVideoView.swift`

### **4. Coaches & plans**
- ✅ **`GET /coaches`**, **`GET /coaches/{id}`**, **`GET /coaches/{id}/plans`**
- ✅ **Coach detail**: plans, **Subscribe** → Safari **Stripe** checkout (`POST /subscriptions/checkout`), **Book session** when subscribed
- ✅ Foreground refresh of subscription state after returning from Safari

**Files:**
- `Views/CoachesView.swift`, `Views/CoachDetailView.swift`, `ViewModels/CoachDetailViewModel.swift`
- `Components/CoachCard.swift`

### **5. Sessions**
- ✅ **`GET /coaches/{id}/availability`**, **`POST /sessions`**, **`GET /sessions`**, **`PATCH /sessions/{id}/cancel`**

**Files:**
- `Views/BookSessionView.swift`, `ViewModels/BookSessionViewModel.swift`
- `Views/MySessionsView.swift`, `ViewModels/MySessionsViewModel.swift`
- `Views/SessionConfirmationView.swift`, `ViewModels/SessionConfirmationViewModel.swift`

### **6. Health record**
- ✅ **`POST /health/records`**, uploads via **`FileUploadManager`** + **`POST /storage/presigned-upload`**
- ✅ 4-step wizard (basic → measurements → goals → files)

**Files:**
- `Views/HealthRecordView.swift`, `ViewModels/HealthRecordViewModel.swift`
- `Services/FileUploadManager.swift`

### **7. Notifications**
- ✅ **`GET /notifications`**, mark read, mark-all-read, unread count (used on home bell)

**Files:**
- `Views/NotificationsView.swift`, `ViewModels/NotificationsViewModel.swift`

### **8. Profile**
- ✅ **`GET /subscriptions`**, **`GET /health/records/latest`**, health-record CTA, theme chips, settings sheet, logout

**Files:**
- `Views/ProfileView.swift`, `ViewModels/ProfileViewModel.swift`

### **9. Training / meals / progress (in-app, not separate tabs)**
- ✅ Workouts and meal plans from **today’s schedule** and **coach programs** (no standalone Training / Meal Plans / Progress tabs)

### **10. HealthKit**
- ✅ Steps, calories, heart rate, weight, body fat (see `HealthKitService`)
- ✅ Used on **Home**; permission sheet where needed

**Files:**
- `Services/HealthKitService.swift`, `Views/HealthKitPermissionView.swift`, `Components/StatCard.swift`

### **11. Settings & design system**
- ✅ Language (EN/AR), RTL, gender themes, dark/light

**Files:**
- `Views/SettingsView.swift`, `Services/ThemeManager.swift`, `Services/LanguageManager.swift`
- `DesignSystem/*`, `Components/AppButton.swift`, `AppCard.swift`, `AppTextField.swift`

### **12. API models & pagination**
- ✅ **`Models/APIResponseModels.swift`** — includes dashboard, sessions, health, notifications, `CoachProfileDTO`, checkout DTOs, etc.
- ✅ **`ViewModels/PaginatedListState.swift`** — reusable list paging

### **13. Localization**
- ✅ `Resources/en.lproj/Localizable.strings`, `ar.lproj/Localizable.strings`

---

## ⌚ watchOS App (`tawazon-watch Watch App`)

### **Core Features (Simplified)**

#### 1. **Quick Stats** ⭐
- ✅ Today's steps
- ✅ Calories burned
- ✅ Heart rate
- ✅ Real-time HealthKit data

**Files:**
- `WatchStatsView.swift`
- `Shared/HealthKitService.swift`

**Features:**
- Displays today's health summary
- Auto-refreshes from HealthKit
- Permission handling

#### 2. **Workout Control** ⭐
- ✅ Start/Stop workout
- ✅ Workout timer
- ✅ Basic workout tracking

**Files:**
- `WatchWorkoutView.swift`
- `Shared/HealthKitService.swift`

**Features:**
- Simple workout controls
- Timer display
- Ready for HealthKit workout sessions

#### 3. **Settings**
- ✅ Language toggle (English/Arabic)
- ✅ Theme selection (Dark/Light)
- ✅ Syncs with iOS app via App Groups

**Files:**
- `WatchSettingsView.swift`
- `Shared/ThemeManager.swift`
- `Shared/LanguageManager.swift`

#### 4. **Shared Services** (Minimal)
- ✅ ThemeManager - Theme management
- ✅ LanguageManager - Localization
- ✅ AuthManager - Authentication state (optional)
- ✅ HealthKitService - Health data access
- ✅ SharedDefaultsHelper - App Groups data sharing

**Files:**
- `Shared/ThemeManager.swift`
- `Shared/LanguageManager.swift`
- `Shared/AuthManager.swift` (optional)
- `Shared/HealthKitService.swift`
- `Shared/SharedDefaultsHelper.swift`

#### 5. **Design System** (Shared)
- ✅ Color themes (gender-based)
- ✅ Typography
- ✅ Consistent styling

**Files:**
- `Shared/DesignSystem/ColorTheme.swift`
- `Shared/DesignSystem/GenderColorTheme.swift`
- `Shared/DesignSystem/Typography.swift`

---

## 🔄 Shared Components

### **Services (Both Platforms)**

| Service | iOS | watchOS | Purpose |
|---------|-----|---------|---------|
| `ThemeManager` | ✅ | ✅ | Theme & color management |
| `LanguageManager` | ✅ | ✅ | Localization & RTL |
| `HealthKitService` | ✅ | ✅ | Health data access |
| `SharedDefaultsHelper` | ✅ | ✅ | App Groups data sharing |
| `AuthManager` | ✅ | ⚠️ Optional | Authentication state |
| `APIService` | ✅ (canonical: `tawazon/Services/APIService.swift`) | ⚠️ Subset (`Shared/APIService.swift`; keep aligned with iOS over time) | Backend API calls |
| `KeychainService` | ✅ | ⚠️ Optional | Secure token storage |

### **Design System (Both Platforms)**

| Component | iOS | watchOS | Purpose |
|-----------|-----|---------|---------|
| `ColorTheme` | ✅ | ✅ | Color definitions |
| `GenderColorTheme` | ✅ | ✅ | Gender-based colors |
| `Typography` | ✅ | ✅ | Font system |

### **Models (Both Platforms)**

| Model | iOS | watchOS | Purpose |
|-------|-----|---------|---------|
| `APIResponseModels` | ✅ | ⚠️ Optional | API data models |
| `HealthSummary` | ✅ | ✅ | Health data models |

---

## 🚫 watchOS Exclusions

The watchOS app **does NOT include**:

- ❌ Full authentication flow (login/signup pages)
- ❌ Coach browsing and profiles
- ❌ Training program details
- ❌ Meal plans
- ❌ Full progress charts
- ❌ Full app API surface (watch ships a **subset** `Shared/APIService.swift`; primary client is iOS)
- ❌ Complex navigation
- ❌ Video playback
- ❌ Image uploads

**Reason:** watchOS has limited screen space and processing power. The watch app focuses on quick access to essential fitness data and workout controls.

---

## ✅ watchOS Inclusions

The watchOS app **includes**:

- ✅ Quick health stats (steps, calories, heart rate)
- ✅ Workout start/stop controls
- ✅ Language toggle
- ✅ Theme selection
- ✅ HealthKit integration
- ✅ App Groups data sharing
- ✅ Real-time health data

**Reason:** These features are perfect for a watch - quick, glanceable, and actionable.

---

## 🔗 Data Sharing (iOS ↔ watchOS)

### **App Groups**
- **ID:** `group.com.tawazon.app`
- **Purpose:** Share UserDefaults between iOS and watchOS

### **Shared Data:**
- ✅ Language preference
- ✅ Theme preference (dark/light)
- ✅ Gender theme preference
- ✅ Authentication tokens (via Keychain - auto-syncs)

### **Implementation:**
```swift
// Both platforms use:
SharedDefaultsHelper.shared.set(value, forKey: key)
SharedDefaultsHelper.shared.string(forKey: key)
```

---

## 🏥 HealthKit Integration

### **iOS App:**
- ✅ Full HealthKit integration
- ✅ Request permissions
- ✅ Read: Steps, Heart Rate, Calories, Weight, Body Fat
- ✅ Display on **Home** (quick stats strip) and related flows

**Files:**
- `Services/HealthKitService.swift`
- `Views/HomeView.swift`
- `Views/HealthKitPermissionView.swift`

### **watchOS App:**
- ✅ HealthKit integration
- ✅ Request permissions
- ✅ Read: Steps, Heart Rate, Calories
- ✅ Display in WatchStatsView
- ✅ Workout tracking (ready for implementation)

**Files:**
- `Shared/HealthKitService.swift`
- `WatchStatsView.swift`
- `WatchWorkoutView.swift`

### **Health Data Types:**
| Type | iOS | watchOS | Read/Write |
|------|-----|---------|------------|
| Steps | ✅ | ✅ | Read |
| Heart Rate | ✅ | ✅ | Read |
| Active Calories | ✅ | ✅ | Read |
| Weight | ✅ | ❌ | Read |
| Body Fat % | ✅ | ❌ | Read |
| Workout Sessions | ✅ | ✅ | Write (ready) |

---

## 📁 File Structure

### **iOS App Structure:**
```
tawazon/tawazon/
├── tawazonApp.swift
├── Navigation/
│   └── MainTabNavigation.swift
├── Services/
│   ├── APIService.swift
│   ├── AuthManager.swift
│   ├── KeychainService.swift
│   ├── FileUploadManager.swift
│   ├── HealthKitService.swift
│   ├── ThemeManager.swift
│   ├── LanguageManager.swift
│   └── SharedDefaultsHelper.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── TodayWorkoutViewModel.swift
│   ├── CoachDetailViewModel.swift
│   ├── BookSessionViewModel.swift
│   ├── MySessionsViewModel.swift
│   ├── SessionConfirmationViewModel.swift
│   ├── HealthViewModel.swift
│   ├── NotificationsViewModel.swift
│   ├── ProfileViewModel.swift
│   └── PaginatedListState.swift
├── Views/
│   ├── MainView.swift
│   ├── LandingView.swift
│   ├── LoginView.swift
│   ├── SignUpView.swift
│   ├── HomeView.swift
│   ├── TodayWorkoutView.swift
│   ├── ExerciseVideoView.swift
│   ├── CoachesView.swift
│   ├── CoachDetailView.swift
│   ├── BookSessionView.swift
│   ├── MySessionsView.swift
│   ├── SessionConfirmationView.swift
│   ├── HealthRecordView.swift
│   ├── NotificationsView.swift
│   ├── ProfileView.swift
│   ├── SettingsView.swift
│   └── HealthKitPermissionView.swift
├── Components/
│   ├── AppButton.swift
│   ├── AppCard.swift
│   ├── AppTextField.swift
│   ├── StatCard.swift
│   └── CoachCard.swift
├── DesignSystem/
│   ├── ColorTheme.swift
│   ├── GenderColorTheme.swift
│   └── Typography.swift
├── Models/
│   └── APIResponseModels.swift
└── Resources/
    ├── Localizable.strings
    ├── en.lproj/Localizable.strings
    └── ar.lproj/Localizable.strings
```

### **watchOS App Structure:**
```
tawazon-watch Watch App/
├── tawazon_watchApp.swift      # App entry point
├── WatchContentView.swift       # Main tab view
├── WatchStatsView.swift         # Health stats
├── WatchWorkoutView.swift       # Workout controls
├── WatchSettingsView.swift      # Settings
└── Shared/                      # Shared services
    ├── ThemeManager.swift
    ├── LanguageManager.swift
    ├── AuthManager.swift
    ├── HealthKitService.swift
    ├── SharedDefaultsHelper.swift
    ├── APIService.swift           # Subset; iOS `Services/APIService.swift` is canonical
    ├── KeychainService.swift
    ├── APIResponseModels.swift
    └── DesignSystem/
        ├── ColorTheme.swift
        ├── GenderColorTheme.swift
        └── Typography.swift
```

---

## 🎨 Theming System

### **iOS:**
- ✅ Full theming support
- ✅ Gender-based colors (Male/Female/Neutral)
- ✅ Dark/Light mode
- ✅ System theme detection
- ✅ Dynamic color updates

### **watchOS:**
- ✅ Full theming support
- ✅ Gender-based colors (syncs with iOS)
- ✅ Dark/Light mode (syncs with iOS)
- ✅ No system detection (defaults to dark)

---

## 🌐 Localization

### **iOS:**
- ✅ Full English/Arabic support
- ✅ RTL layout for Arabic
- ✅ All views translated
- ✅ Dynamic language switching

### **watchOS:**
- ✅ Full English/Arabic support
- ✅ RTL layout for Arabic
- ✅ All views translated
- ✅ Syncs with iOS language preference

**Translation Files:**
- `Resources/Localizable.strings` (English)
- `Resources/en.lproj/Localizable.strings` (English)
- `Resources/ar.lproj/Localizable.strings` (Arabic)

---

## 🔐 Security

### **iOS:**
- ✅ Keychain for token storage
- ✅ Secure API communication
- ✅ JWT token management
- ✅ Refresh token rotation

### **watchOS:**
- ✅ Keychain auto-syncs with iOS
- ✅ Shared authentication state
- ✅ Secure data sharing via App Groups

---

## 📊 API Integration

### **iOS App (`Services/APIService.swift`):**
- ✅ **Auth:** register, login, refresh, logout, social sign-in helpers as used by the app
- ✅ **Dashboard & home:** `GET /dashboard`, progress summary, featured coaches
- ✅ **Today’s program:** today schedule, complete/skip exercise
- ✅ **Coaches:** list, detail, plans (paginated)
- ✅ **Subscriptions:** list, **Stripe checkout** (`POST /subscriptions/checkout`)
- ✅ **Sessions:** coach availability, create session, list, cancel
- ✅ **Health:** create record, latest record; **storage** presigned upload
- ✅ **Notifications:** list (paged), mark read, mark all read, unread count
- ✅ **Legacy / shared surface:** programs, videos, nutrition, dishes, meals, user profile, etc. (as retained in `APIService`)

### **watchOS App:**
- ⚠️ **`Shared/APIService.swift`** — **subset** of iOS; not the full app client
- ✅ HealthKit for on-watch health data
- ✅ App Groups for preferences / optional token sync

---

## 🎯 Use Cases

### **iOS App:**
- 📱 Landing, auth, guest browse, 4-tab main app
- 👥 Coaches, plans, Stripe subscribe, book sessions
- 🏠 Dashboard, today’s workout, exercise video
- 📝 Health record wizard + file upload
- 🔔 Notifications
- ⚙️ Profile, subscriptions, settings, themes
- 🔐 JWT + refresh, session expiry handling

### **watchOS App:**
- ⌚ Quick health stats glance
- 🏃 Start/stop workouts
- ⚙️ Quick settings (language, theme)
- 📊 Real-time health data
- 🔄 Syncs with iPhone

---

## 🔧 Technical Details

### **Platform-Specific Code:**

**iOS Only:**
- `UIApplication` usage (wrapped in `#if os(iOS)`)
- Complex navigation
- Video playback
- Image handling
- Full API integration

**watchOS Only:**
- Simplified UI
- Watch-specific interactions
- Limited navigation

**Both Platforms:**
- SwiftUI views
- HealthKit
- App Groups
- Shared services

---

## 📝 Summary

| Feature | iOS | watchOS |
|---------|-----|---------|
| **Authentication** | ✅ Full | ⚠️ Optional |
| **Coaches / sessions / checkout** | ✅ Full | ❌ |
| **Home dashboard & today workout** | ✅ Full | ❌ |
| **Health record & uploads** | ✅ Full | ❌ |
| **Notifications** | ✅ Full | ❌ |
| **HealthKit** | ✅ Full (Home + flows) | ✅ Basic |
| **Settings** | ✅ Full | ✅ Basic |
| **Localization** | ✅ Full | ✅ Full |
| **Theming** | ✅ Full | ✅ Full |
| **API Integration** | ✅ Full client | ⚠️ Subset `Shared/APIService` |
| **Data Sharing** | ✅ | ✅ |

---

## 🚀 Future Enhancements

### **watchOS:**
- [ ] HealthKit workout sessions
- [ ] Complications for watch face
- [ ] WatchConnectivity for real-time sync
- [ ] Haptic feedback
- [ ] Voice commands

### **iOS:**
- [ ] Push notifications
- [ ] Social features
- [ ] Advanced analytics
- [ ] Offline mode
- [ ] Widgets

---

**Last Updated:** 2026-03-21

