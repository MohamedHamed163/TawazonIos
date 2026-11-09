//
//  StatCard.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

struct StatCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let value: String
    let label: String
    var color: Color? = nil
    
    private var displayColor: Color {
        color ?? themeManager.dynamicColorTheme.currentPrimary
    }
    
    var body: some View {
        AppCard {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(displayColor)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        StatCard(
            icon: "flame.fill",
            value: "1,240",
            label: "Calories",
            color: ColorTheme.Semantic.warning
        )
        StatCard(
            icon: "figure.run",
            value: "45",
            label: "Steps",
            color: ColorTheme.primary
        )
    }
    .padding()
    .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: ThemeManager().isDarkMode))
    .environmentObject(ThemeManager())
    .preferredColorScheme(.dark)
}

