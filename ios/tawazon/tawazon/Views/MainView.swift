//
//  MainView.swift
//  tawazon
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedTab = 0
    @State private var homePath = NavigationPath()
    @State private var coachesPath = NavigationPath()
    @State private var messagesPath = NavigationPath()
    @State private var profilePath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $homePath) {
                HomeView(
                    onNotifications: { homePath.append(HomeNav.notifications) },
                    onTodayWorkout: { homePath.append(HomeNav.todayWorkout) },
                    onCoach: { homePath.append(HomeNav.coachDetail($0)) },
                    onHealthRecord: { homePath.append(HomeNav.healthRecord) },
                    onBrowseCoachesTab: { selectedTab = 1 },
                    onMeals: { homePath.append(HomeNav.meals) },
                    onPrograms: { homePath.append(HomeNav.programs) },
                    onCoachContent: { homePath.append(HomeNav.coachContent) },
                    onProgress: { homePath.append(HomeNav.progress) },
                    onMessageCoach: { coachId, coachName in
                        if let coachId {
                            homePath.append(HomeNav.coachChat(coachId, coachName))
                        } else {
                            selectedTab = 3
                        }
                    }
                )
                .navigationDestination(for: HomeNav.self) { route in
                    switch route {
                    case .notifications:
                        NotificationsView()
                    case .todayWorkout:
                        TodayWorkoutView(
                            onPlayVideo: { homePath.append(HomeNav.exerciseVideo($0)) },
                            onStartWorkout: { homePath.append(HomeNav.activeWorkout) }
                        )
                    case .activeWorkout:
                        ActiveWorkoutView(
                            onPlayVideo: { homePath.append(HomeNav.exerciseVideo($0)) }
                        )
                    case .exerciseVideo(let url):
                        ExerciseVideoView(videoURLString: url)
                    case .coachDetail(let id):
                        CoachDetailView(coachId: id)
                    case .healthRecord:
                        HealthRecordView()
                    case .meals:
                        MealsView()
                    case .programs:
                        ProgramsView(onSelect: { homePath.append(HomeNav.programDetail($0)) })
                    case .programDetail(let id):
                        ProgramDetailView(
                            programId: id,
                            onPlayVideo: { homePath.append(HomeNav.exerciseVideo($0)) }
                        )
                    case .coachContent:
                        CoachContentView(onPlay: { homePath.append(HomeNav.exerciseVideo($0)) })
                    case .progress:
                        ProgressDashboardView()
                    case .chat(let id, let name):
                        ChatView(conversationId: id, coachName: name)
                    case .coachChat(let coachId, let name):
                        ChatView(coachProfileId: coachId, coachName: name)
                    }
                }
            }
            .tabItem {
                Label(languageManager.localize("nav.home"), systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack(path: $coachesPath) {
                CoachesView { coachId in
                    coachesPath.append(CoachesNav.coachDetail(coachId))
                }
                .navigationDestination(for: CoachesNav.self) { route in
                    switch route {
                    case .coachDetail(let id):
                        CoachDetailView(coachId: id)
                    }
                }
            }
            .tabItem {
                Label(languageManager.localize("nav.coaches"), systemImage: "person.2.fill")
            }
            .tag(1)

            ReelsView()
                .tabItem {
                    Label(languageManager.localize("nav.reels"), systemImage: "film.stack")
                }
                .tag(2)

            NavigationStack(path: $messagesPath) {
                ConversationsView(onOpen: { id, name in
                    messagesPath.append(MessagesNav.chat(id, name))
                })
                .navigationDestination(for: MessagesNav.self) { route in
                    switch route {
                    case .chat(let id, let name):
                        ChatView(conversationId: id, coachName: name)
                    }
                }
            }
            .tabItem {
                Label(languageManager.localize("nav.messages"), systemImage: "message.fill")
            }
            .tag(3)

            NavigationStack(path: $profilePath) {
                ProfileView(onHealthRecord: { profilePath.append(ProfileNav.healthRecord) })
                    .navigationDestination(for: ProfileNav.self) { route in
                        switch route {
                        case .healthRecord:
                            HealthRecordView()
                        }
                    }
            }
            .tabItem {
                Label(languageManager.localize("nav.profile"), systemImage: "person.fill")
            }
            .tag(4)
        }
        .tint(themeManager.dynamicColorTheme.currentPrimary)
        .onReceive(NotificationCenter.default.publisher(for: .tawazonSessionExpired)) { _ in
            authManager.logout()
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AuthManager())
        .environmentObject(LanguageManager())
        .environmentObject(ThemeManager())
}
