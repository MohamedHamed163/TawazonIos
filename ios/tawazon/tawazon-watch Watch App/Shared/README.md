# Shared Files for watchOS

This folder contains the minimal shared files needed for the watchOS app.

## Essential Files

1. **ThemeManager.swift** - Theme management
2. **LanguageManager.swift** - Language/localization
3. **AuthManager.swift** - Authentication (optional, can be simplified)
4. **SharedDefaultsHelper.swift** - App Groups data sharing
5. **DesignSystem/** - Colors and typography

## Note

These files should be added to BOTH iOS and watchOS targets in Xcode:
- Select each file
- File Inspector → Target Membership
- Check both "tawazon" and "tawazon-watch Watch App"

