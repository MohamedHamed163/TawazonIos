//
//  Haptics.swift
//  tawazon
//
//  Lightweight wrapper around UIKit feedback generators so call sites stay
//  expressive (`Haptics.success()`) without importing UIKit everywhere.
//

import Foundation

#if os(iOS)
import UIKit

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    /// Semantic shortcuts used across the app.
    static func success() { notify(.success) }
    static func warning() { notify(.warning) }
    static func error() { notify(.error) }
    static func tap() { impact(.light) }
}
#else
enum Haptics {
    static func impact(_ style: Int = 0) {}
    static func selection() {}
    static func success() {}
    static func warning() {}
    static func error() {}
    static func tap() {}
}
#endif
