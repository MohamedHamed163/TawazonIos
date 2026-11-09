//
//  CoachesView.swift
//  tawazon
//

import SwiftUI

struct CoachesView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    private let apiService = APIService.shared
    @State private var searchText = ""
    @State private var selectedFilter: CoachFilter = .all
    @State private var coaches: [CoachProfileDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    var onSelectCoach: (String) -> Void

    var isIPad: Bool { horizontalSizeClass == .regular }

    enum CoachFilter: String, CaseIterable {
        case all, strength, cardio, yoga, hiit, pilates

        func localized(_ languageManager: LanguageManager) -> String {
            switch self {
            case .all: return languageManager.localize("common.all")
            case .strength: return languageManager.localize("workout.strength")
            case .cardio: return languageManager.localize("workout.cardio")
            case .yoga: return languageManager.localize("workout.yoga")
            case .hiit: return languageManager.localize("workout.hiit")
            case .pilates: return languageManager.localize("workout.pilates")
            }
        }

        func matches(_ specialties: [String]) -> Bool {
            if self == .all { return true }
            let needle = rawValue
            return specialties.contains { $0.localizedCaseInsensitiveContains(needle) }
        }
    }

    private var filteredCoaches: [CoachProfileDTO] {
        coaches.filter { c in
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchOk = q.isEmpty
                || c.displayName.localizedCaseInsensitiveContains(q)
                || c.specialties.joined(separator: " ").localizedCaseInsensitiveContains(q)
            return searchOk && selectedFilter.matches(c.specialties)
        }
    }

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                    TextField(languageManager.localize("coaches.searchPlaceholder"), text: $searchText)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        .onSubmit { loadCoaches() }
                }
                .padding()
                .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
                .cornerRadius(12)
                .padding(.horizontal, isIPad ? 40 : 20)
                .padding(.vertical, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CoachFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.localized(languageManager),
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, isIPad ? 40 : 20)
                    .padding(.bottom, 16)
                }

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.gray)
                        Button(languageManager.localize("common.retry")) {
                            loadCoaches()
                        }
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredCoaches, id: \.id) { coach in
                                CoachListRowCard(
                                    coach: coach,
                                    themeManager: themeManager,
                                    languageManager: languageManager
                                ) {
                                    onSelectCoach(coach.id)
                                }
                            }
                        }
                        .padding(.horizontal, isIPad ? 40 : 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationTitle(languageManager.localize("coaches.title"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadCoaches()
        }
    }

    private func loadCoaches() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let token = KeychainService.shared.getAccessToken()
                let response = try await apiService.getCoaches(page: 0, size: 50, token: token)
                await MainActor.run {
                    coaches = response.content
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

/// Full-width row (aligned with Android coaches list): avatar, name, bio, specialty pill, chevron.
struct CoachListRowCard: View {
    let coach: CoachProfileDTO
    let themeManager: ThemeManager
    let languageManager: LanguageManager
    var onTap: () -> Void

    private var displayName: String {
        coach.displayName.isEmpty ? "—" : coach.displayName
    }

    private var specialtyText: String {
        coach.specialties.first ?? languageManager.localize("coaches.specialty")
    }

    private var bioText: String? {
        let b = coach.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return b.isEmpty ? nil : b
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                CoachAvatarView(urlString: coach.avatarUrl, size: 56)
                    .environmentObject(themeManager)

                VStack(alignment: .leading, spacing: 6) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let bio = bioText {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Text(specialtyText)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(themeManager.dynamicColorTheme.currentPrimary.opacity(0.16))
                        .clipShape(Capsule())
                }

                Image(systemName: languageManager.isRTL ? "chevron.backward" : "chevron.forward")
                    .font(.body.weight(.semibold))
                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode).opacity(0.55))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(themeManager.isDarkMode ? 0.12 : 0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CoachesView(onSelectCoach: { _ in })
    }
    .environmentObject(LanguageManager())
    .environmentObject(ThemeManager())
}
