//
//  LanguageManager.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: Language = .english {
        didSet {
            SharedDefaultsHelper.shared.set(currentLanguage.rawValue, forKey: SharedDefaultsHelper.Keys.currentLanguage)
            updateLanguage()
        }
    }
    
    @Published var isRTL: Bool = false
    
    // This ID changes when language changes, forcing views to refresh
    @Published var refreshID: UUID = UUID()
    
    private let defaults = SharedDefaultsHelper.shared
    
    enum Language: String, CaseIterable {
        case english = "en"
        case arabic = "ar"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .arabic: return "العربية"
            }
        }
        
        var locale: Locale {
            Locale(identifier: rawValue)
        }
    }
    
    init() {
        if let savedLanguage = defaults.string(forKey: SharedDefaultsHelper.Keys.currentLanguage),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        }
        updateLanguage()
    }
    
    private func updateLanguage() {
        isRTL = currentLanguage == .arabic
        // Set app language
        defaults.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        defaults.synchronize()
        // Update refresh ID to force view updates
        refreshID = UUID()
    }
    
    func localize(_ key: String) -> String {
        return WatchTranslations.translate(key, language: currentLanguage)
    }
    
    // Toggle between languages
    func toggleLanguage() {
        currentLanguage = currentLanguage == .english ? .arabic : .english
    }
}

// MARK: - Watch Translations (Hardcoded for watchOS)
struct WatchTranslations {
    
    // English translations
    private static let englishStrings: [String: String] = [
        // Navigation
        "nav.home": "Home",
        "nav.coaches": "Coaches",
        "nav.training": "Training",
        "nav.meals": "Meals",
        "nav.progress": "Progress",
        "nav.profile": "Profile",
        
        // Progress/Stats
        "progress.title": "Progress",
        "progress.steps": "Steps",
        "progress.calories": "Calories",
        "progress.heartRate": "Heart Rate",
        "progress.distance": "Distance",
        "progress.weight": "Weight",
        "progress.bodyFat": "Body Fat",
        "progress.todayStats": "Today's Stats",
        "progress.weeklyProgress": "Weekly Progress",
        "progress.healthData": "Health Data",
        
        // Workout
        "workout.start": "Start Workout",
        "workout.stop": "Stop",
        "workout.pause": "Pause",
        "workout.resume": "Resume",
        "workout.duration": "Duration",
        "workout.active": "Active",
        "workout.completed": "Completed",
        
        // Settings
        "settings.title": "Settings",
        "settings.language": "Language",
        "settings.theme": "Theme",
        "settings.theme.dark": "Dark",
        "settings.theme.light": "Light",
        "settings.theme.system": "System",
        "settings.appearanceMode": "Appearance",
        "settings.colorTheme": "Color Theme",
        "settings.colorTheme.male": "Male",
        "settings.colorTheme.female": "Female",
        "settings.colorTheme.neutral": "Neutral",
        
        // HealthKit
        "healthkit.permissionRequired": "Permission Required",
        "healthkit.permissionMessage": "Please allow access to Health data to track your fitness progress.",
        "healthkit.notAvailable": "Health data not available",
        
        // Common
        "common.ok": "OK",
        "common.cancel": "Cancel",
        "common.save": "Save",
        "common.loading": "Loading...",
        "common.error": "Error",
        "common.success": "Success",
        "common.retry": "Retry",
        
        // Auth
        "auth.login": "Login",
        "auth.signup": "Sign Up",
        "auth.logout": "Logout",
        "auth.email": "Email",
        "auth.password": "Password",
        
        // Watch specific
        "watch.loginRequired": "Login Required",
        "watch.loginMessage": "Please login on your iPhone app to view your workouts and diet plans.",
        "watch.noPrograms": "No programs available",
        "watch.noDietPlans": "No diet plans available",
        "watch.workouts": "Workouts",
        "watch.dietPlans": "Diet Plans",
        "watch.calories": "cal"
    ]
    
    // Arabic translations
    private static let arabicStrings: [String: String] = [
        // Navigation
        "nav.home": "الرئيسية",
        "nav.coaches": "المدربين",
        "nav.training": "التدريب",
        "nav.meals": "الوجبات",
        "nav.progress": "التقدم",
        "nav.profile": "الملف الشخصي",
        
        // Progress/Stats
        "progress.title": "التقدم",
        "progress.steps": "الخطوات",
        "progress.calories": "السعرات",
        "progress.heartRate": "نبض القلب",
        "progress.distance": "المسافة",
        "progress.weight": "الوزن",
        "progress.bodyFat": "نسبة الدهون",
        "progress.todayStats": "إحصائيات اليوم",
        "progress.weeklyProgress": "التقدم الأسبوعي",
        "progress.healthData": "بيانات الصحة",
        
        // Workout
        "workout.start": "بدء التمرين",
        "workout.stop": "إيقاف",
        "workout.pause": "إيقاف مؤقت",
        "workout.resume": "استئناف",
        "workout.duration": "المدة",
        "workout.active": "نشط",
        "workout.completed": "مكتمل",
        
        // Settings
        "settings.title": "الإعدادات",
        "settings.language": "اللغة",
        "settings.theme": "المظهر",
        "settings.theme.dark": "داكن",
        "settings.theme.light": "فاتح",
        "settings.theme.system": "النظام",
        "settings.appearanceMode": "المظهر",
        "settings.colorTheme": "لون السمة",
        "settings.colorTheme.male": "ذكر",
        "settings.colorTheme.female": "أنثى",
        "settings.colorTheme.neutral": "محايد",
        
        // HealthKit
        "healthkit.permissionRequired": "مطلوب إذن",
        "healthkit.permissionMessage": "يرجى السماح بالوصول إلى بيانات الصحة لتتبع تقدمك الرياضي.",
        "healthkit.notAvailable": "بيانات الصحة غير متاحة",
        
        // Common
        "common.ok": "موافق",
        "common.cancel": "إلغاء",
        "common.save": "حفظ",
        "common.loading": "جاري التحميل...",
        "common.error": "خطأ",
        "common.success": "نجاح",
        "common.retry": "إعادة المحاولة",
        
        // Auth
        "auth.login": "تسجيل الدخول",
        "auth.signup": "إنشاء حساب",
        "auth.logout": "تسجيل الخروج",
        "auth.email": "البريد الإلكتروني",
        "auth.password": "كلمة المرور",
        
        // Watch specific
        "watch.loginRequired": "مطلوب تسجيل الدخول",
        "watch.loginMessage": "يرجى تسجيل الدخول من تطبيق iPhone لعرض تمارينك وخططك الغذائية.",
        "watch.noPrograms": "لا توجد برامج متاحة",
        "watch.noDietPlans": "لا توجد خطط غذائية متاحة",
        "watch.workouts": "التمارين",
        "watch.dietPlans": "الخطط الغذائية",
        "watch.calories": "سعرة"
    ]
    
    static func translate(_ key: String, language: LanguageManager.Language) -> String {
        switch language {
        case .english:
            return englishStrings[key] ?? key
        case .arabic:
            return arabicStrings[key] ?? englishStrings[key] ?? key
        }
    }
}

// MARK: - String Extension
extension String {
    func localized(_ language: LanguageManager.Language? = nil) -> String {
        let lang = language ?? LanguageManager.shared.currentLanguage
        return WatchTranslations.translate(self, language: lang)
    }
}

