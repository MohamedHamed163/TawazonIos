//
//  RTLNavigationBackButton.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

struct RTLNavigationBackButton: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            HStack(spacing: 4) {
                if languageManager.isRTL {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                } else {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(languageManager.localize("common.back"))
                    .font(.body)
            }
            .foregroundColor(.fitForgeLime)
        }
    }
}

// MARK: - Navigation Bar Modifier
struct RTLNavigationBarModifier: ViewModifier {
    @EnvironmentObject var languageManager: LanguageManager
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    RTLNavigationBackButton()
                        .environmentObject(languageManager)
                }
            }
    }
}

extension View {
    func rtlNavigationBar() -> some View {
        modifier(RTLNavigationBarModifier())
    }
}

