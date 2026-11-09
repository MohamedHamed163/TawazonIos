# watchOS Build Fixes

## ✅ Fixed Issues

### 1. UIApplication Usage in ThemeManager.swift
**Problem:** `UIApplication` is iOS-only and doesn't exist on watchOS, causing compile errors.

**Fix:** Wrapped iOS-specific code in `#if os(iOS)` compiler directives:
```swift
#if os(iOS)
if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
    // iOS-specific code
}
#else
// watchOS fallback
currentGenderThemeMode = currentGender == .male ? .maleDark : ...
#endif
```

**Location:** `tawazon/tawazon/Services/ThemeManager.swift` (lines 75-82 and 105-112)

---

## 🔍 Common watchOS Build Issues & Solutions

### Issue: "Cannot find type 'ThemeManager' in scope"
**Solution:** 
1. Clean build folder (⌘⇧K)
2. Make sure `tawazon` folder is included in watchOS target (already done in project.pbxproj)
3. Rebuild project

### Issue: "Missing com.apple.developer.healthkit entitlement"
**Solution:**
1. Select watchOS target → Signing & Capabilities
2. Click + Capability → HealthKit
3. Enable HealthKit capability

### Issue: App Groups not working
**Solution:**
1. Select iOS target → Signing & Capabilities → App Groups
2. Add: `group.com.tawazon.app`
3. Select watchOS target → Signing & Capabilities → App Groups
4. Add: `group.com.tawazon.app` (same ID!)

### Issue: Missing localization files
**Solution:**
- Make sure `Resources/Localizable.strings` files are added to watchOS target
- Check File Inspector → Target Membership

---

## 📋 Files That Should Work on watchOS

✅ **Services:**
- `AuthManager.swift` - Uses @MainActor (works on watchOS)
- `ThemeManager.swift` - Fixed iOS-specific code
- `LanguageManager.swift` - Platform-agnostic
- `SharedDefaultsHelper.swift` - Platform-agnostic
- `KeychainService.swift` - Works on watchOS
- `APIService.swift` - Platform-agnostic
- `HealthKitService.swift` - Works on watchOS (needs HealthKit capability)

✅ **Design System:**
- `ColorTheme.swift` - SwiftUI only
- `GenderColorTheme.swift` - SwiftUI only
- `Typography.swift` - SwiftUI only

✅ **Models:**
- `APIResponseModels.swift` - Platform-agnostic

✅ **Resources:**
- `Localizable.strings` - Works on watchOS

---

## 🚨 Files That May Need Platform Checks

⚠️ **Views (iOS-only):**
- Most views in `Views/` folder are iOS-specific
- Only watchOS views should be in `tawazon-watch Watch App/`

---

## ✅ Next Steps

1. **Clean Build Folder:**
   ```
   Product → Clean Build Folder (⌘⇧K)
   ```

2. **Rebuild:**
   - Select "tawazon-watch Watch App" scheme
   - Press ⌘B

3. **If errors persist:**
   - Check Xcode build log for specific errors
   - Verify all shared files are accessible
   - Check App Groups capability is enabled

---

## 📝 Notes

- The project.pbxproj has been updated to include `tawazon` folder in watchOS target
- All iOS-specific code is now wrapped in `#if os(iOS)` checks
- watchOS app should now build successfully

