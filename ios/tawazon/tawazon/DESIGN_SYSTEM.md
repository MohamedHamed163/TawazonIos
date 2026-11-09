# Tawazon Design System Guide

This document explains how to update colors, fonts, and reusable components in the Tawazon iOS app.

## 📁 File Structure

### Design System Files
- `DesignSystem/ColorTheme.swift` - All color definitions (dark/light mode)
- `DesignSystem/Typography.swift` - All font sizes, weights, and styles

### Reusable Components
- `Components/AppTextField.swift` - Unified text input field
- `Components/AppButton.swift` - Unified button component
- `Components/AppCard.swift` - Unified card container
- `Components/StatCard.swift` - Statistics display card
- `Components/CoachCard.swift` - Coach profile card
- `Components/FilterChip.swift` - Filter chip component
- `Components/RTLNavigationBackButton.swift` - RTL-aware back button

### Localization Files
- `Resources/Localizable.strings` - English translations
- `Resources/ar.lproj/Localizable.strings` - Arabic translations

---

## 🎨 How to Change Colors

### Location: `DesignSystem/ColorTheme.swift`

All colors are centralized in the `ColorTheme` struct. To change colors:

1. **Brand Colors** (Primary color):
```swift
static let primary = Color(red: 0.5, green: 1.0, blue: 0.0) // Change this
```

2. **Background Colors**:
```swift
struct Background {
    static let primary = Color(red: 0.1, green: 0.1, blue: 0.1) // Dark mode
    static let primaryLight = Color(red: 0.98, green: 0.98, blue: 0.98) // Light mode
}
```

3. **Text Colors**:
```swift
struct Text {
    static let primary = Color.white // Dark mode text
    static let primaryLight = Color.black // Light mode text
}
```

4. **Button Colors**:
```swift
struct Button {
    static let primary = ColorTheme.primary
    static let primaryText = ColorTheme.Background.primary
}
```

**Usage in Views:**
```swift
Text("Hello")
    .foregroundColor(ColorTheme.Text.primary)
    .background(ColorTheme.Background.primary)
```

---

## ✍️ How to Change Fonts

### Location: `DesignSystem/Typography.swift`

### Change Font Family:
```swift
static let fontFamily = "System" // Change to your custom font name
```

### Change Font Sizes:
```swift
struct Size {
    static let largeTitle: CGFloat = 34 // Change this
    static let title1: CGFloat = 28
    static let body: CGFloat = 17
    // ... etc
}
```

### Change Font Weights:
```swift
struct Weight {
    static let regular = Font.Weight.regular
    static let bold = Font.Weight.bold
    // ... etc
}
```

### Predefined Styles:
```swift
struct Style {
    static let title1 = Font.system(size: Size.title1, weight: Weight.bold, design: .default)
    static let body = Font.system(size: Size.body, weight: Weight.regular, design: .default)
    // ... etc
}
```

**Usage in Views:**
```swift
Text("Hello")
    .textStyle(Typography.Style.headline, color: ColorTheme.Text.primary)
```

---

## 🔘 How to Use Reusable Components

### AppTextField
```swift
AppTextField(
    title: "Email",
    text: $email,
    placeholder: "Enter email",
    keyboardType: .emailAddress,
    isSecure: false,
    isRequired: true,
    errorMessage: "Invalid email"
)
```

### AppButton
```swift
AppButton(
    title: "Login",
    style: .primary, // .primary, .secondary, .outline, .text
    icon: "arrow.right",
    isLoading: false,
    isDisabled: false
) {
    // Action
}
```

### AppCard
```swift
AppCard.defaultCard {
    // Content
}

AppCard.outlinedCard {
    // Content with border
}

AppCard.elevatedCard {
    // Content with enhanced shadow
}
```

### StatCard
```swift
StatCard(
    icon: "flame.fill",
    value: "1,240",
    label: "Calories",
    color: ColorTheme.Semantic.warning
)
```

---

## 🌍 How to Add Translations

### Location: `Resources/Localizable.strings` (English) and `Resources/ar.lproj/Localizable.strings` (Arabic)

1. **Add to English file:**
```swift
"new.key" = "New Text";
```

2. **Add to Arabic file:**
```swift
"new.key" = "نص جديد";
```

3. **Use in code:**
```swift
Text(languageManager.localize("new.key"))
```

---

## 🎯 Quick Reference

### Colors
- `ColorTheme.primary` - Brand color (lime green)
- `ColorTheme.Background.primary` - Main background
- `ColorTheme.Text.primary` - Main text color
- `ColorTheme.Button.primary` - Primary button color
- `ColorTheme.Semantic.error` - Error color (red)
- `ColorTheme.Semantic.success` - Success color (green)

### Typography
- `Typography.Style.largeTitle` - Large title (34pt, bold)
- `Typography.Style.title1` - Title 1 (28pt, bold)
- `Typography.Style.headline` - Headline (17pt, semibold)
- `Typography.Style.body` - Body text (17pt, regular)
- `Typography.Style.caption` - Caption (12pt, regular)

### Components
- `AppTextField` - Text input with validation
- `AppButton` - Button with multiple styles
- `AppCard` - Card container
- `StatCard` - Statistics card
- `CoachCard` - Coach profile card

---

## 📝 Best Practices

1. **Always use ColorTheme** - Never hardcode colors
2. **Always use Typography** - Never hardcode font sizes
3. **Use reusable components** - Don't recreate text fields or buttons
4. **Localize all text** - Use `languageManager.localize()` for all user-facing text
5. **Test in both languages** - Ensure RTL works correctly for Arabic

---

## 🔄 Updating Theme

The app supports dark/light mode through `ThemeManager`. Colors automatically adapt based on the selected theme.

To change theme programmatically:
```swift
themeManager.setTheme(.dark) // or .light, .system
```

