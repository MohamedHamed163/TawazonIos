//
//  LocalizedText.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

struct LocalizedText: View {
    let key: String
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        Text(languageManager.localize(key))
    }
}

// MARK: - View Modifier for RTL Support
struct RTLModifier: ViewModifier {
    @EnvironmentObject var languageManager: LanguageManager
    
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, languageManager.isRTL ? .rightToLeft : .leftToRight)
            .environment(\.locale, languageManager.currentLanguage.locale)
    }
}

extension View {
    func rtlSupport() -> some View {
        modifier(RTLModifier())
    }
}

