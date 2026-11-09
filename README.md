<div align="center">

<img src="docs/icon.png" width="120" alt="Tawazon icon" />

# Tawazon

**A fitness coaching marketplace for iPhone and Apple Watch.**

Subscribe to a coach, follow today's workout and meal plan, book 1:1 sessions, chat, and track
your health with HealthKit, in English or Arabic.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-000000?logo=apple&logoColor=white)
![watchOS 11+](https://img.shields.io/badge/watchOS-11%2B-000000?logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0A84FF)
![HealthKit](https://img.shields.io/badge/HealthKit-enabled-FF2D55)
![EN / AR](https://img.shields.io/badge/i18n-EN%20%2F%20AR%20(RTL)-2EA043)
![TestFlight](https://img.shields.io/badge/CI-TestFlight-0D96F6?logo=githubactions&logoColor=white)

</div>

## Features

### iPhone

| Area | What it does |
|---|---|
| **Landing & auth** | Marketing landing; login / register with email, Apple, Google and biometrics; guest browsing of coaches |
| **Home** | Dashboard, progress summary, featured coaches, HealthKit quick stats, subscription card, today's workout |
| **Coaches & plans** | Coach list and detail, plans, Stripe checkout in Safari, subscription refresh when you return |
| **Today's workout** | Complete or skip, exercise videos (AVKit), active workout view |
| **Sessions** | Coach availability, book, list and cancel 1:1 sessions |
| **Health record** | 4-step wizard (basic → measurements → goals → files) with presigned uploads |
| **Chat & reels** | Conversations with coaches (STOMP), voice notes, coach content and reels |
| **Notifications** | List, mark read / mark all read, unread badge on the home bell |
| **Profile & settings** | Subscriptions, latest health record, language EN/AR with RTL, gender-based themes, dark/light |

Navigation is a 4-tab `TabView` (**Home · Coaches · Sessions · Profile**). Each tab owns a
`NavigationStack` with typed routes.

### Apple Watch

- **Quick stats**: today's steps, calories and heart rate from HealthKit, in real time
- **Workout control**: start/stop with a workout timer
- **Settings**: language and theme, synced with the iPhone app through App Groups

## Tech stack

| Layer | Choice |
|---|---|
| UI | SwiftUI, MVVM (`Views/`, `ViewModels/`, `Components/`, `DesignSystem/`) |
| Networking | `APIService` with a JWT access + refresh flow: on 401, a single-flight refresh, then retry |
| Storage | Keychain for tokens, App Groups (`SharedDefaultsHelper`) for watch sync |
| Realtime | STOMP over WebSocket for chat |
| Health | HealthKit: steps, calories, heart rate, weight, body fat |
| Payments | Stripe Checkout (opened in Safari) |
| Backend | Spring Boot (Java 21) REST API, `ApiResponse<T>` envelope, paged responses |
| Release | fastlane + GitHub Actions → TestFlight |

## Getting started

```bash
git clone https://github.com/MohamedHamed163/TawazonIos.git
cd TawazonIos
open ios/tawazon/tawazon.xcodeproj
```

1. Select the `tawazon` scheme and an iPhone simulator (iOS 17+).
2. Optionally point the API at a local backend (`http://127.0.0.1:8080/api/v1/`). See
   [`ios/API_INTEGRATION.md`](ios/API_INTEGRATION.md).
3. Press <kbd>⌘R</kbd>. For the watch app, pick the `tawazon-watch Watch App` scheme.

## Repository layout

| Path | Contents |
|---|---|
| `ios/tawazon/tawazon/` | iPhone app: Views, ViewModels, Services, Components, DesignSystem, Navigation |
| `ios/tawazon/tawazon-watch Watch App/` | Apple Watch companion app and shared code |
| `watch-os/` | Standalone watchOS prototype project |
| `fastlane/` | Build and TestFlight lanes |
| `.github/workflows/testflight.yml` | Archive and upload to TestFlight (manual, or on push to `main` under `ios/`) |

## Docs

- [App architecture](ios/APP_ARCHITECTURE.md): feature-by-feature breakdown with endpoints and files
- [API integration](ios/API_INTEGRATION.md)
- [watchOS setup](ios/WATCHOS_SETUP.md) · [quick start](ios/WATCHOS_QUICK_START.md)
- [Troubleshooting](ios/tawazon/TROUBLESHOOTING.md)
