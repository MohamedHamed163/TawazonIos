//
//  MainTabNavigation.swift
//  tawazon
//

import Foundation

enum HomeNav: Hashable {
    case notifications
    case todayWorkout
    case activeWorkout
    case exerciseVideo(String)
    case coachDetail(String)
    case healthRecord
    case meals
    case programs
    case programDetail(String)
    case coachContent
    case progress
    case chat(String, String)
    case coachChat(String, String)
}

enum CoachesNav: Hashable {
    case coachDetail(String)
}

enum MessagesNav: Hashable {
    case chat(String, String)
}

enum ProfileNav: Hashable {
    case healthRecord
}
