//
//  FilterChip.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

struct FilterChip: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? themeManager.dynamicColorTheme.currentPrimaryDark : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? themeManager.dynamicColorTheme.currentPrimary : Color.gray.opacity(0.3))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HStack {
        FilterChip(title: "All", isSelected: true) {}
        FilterChip(title: "Active", isSelected: false) {}
    }
    .padding()
    .environmentObject(ThemeManager())
    .preferredColorScheme(.dark)
}

