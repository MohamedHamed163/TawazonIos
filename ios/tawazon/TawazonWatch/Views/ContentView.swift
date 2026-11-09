//
//  ContentView.swift
//  TawazonWatch
//
//  Main watch view
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            StatsView()
                .tag(0)
            
            WorkoutView()
                .tag(1)
            
            SettingsView()
                .tag(2)
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LanguageManager.shared)
}

