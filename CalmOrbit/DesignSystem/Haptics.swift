//
//  Haptics.swift
//  CalmOrbit
//
//  Lightweight haptic helper. Reads the user's "haptics enabled" preference
//  directly from UserDefaults so it works from any context (defaults to on).
//

import UIKit

enum HapticPref {
    static let key = "settings_haptics_enabled"
}

final class Haptics {
    static let shared = Haptics()
    private init() {}

    private var enabled: Bool {
        UserDefaults.standard.object(forKey: HapticPref.key) as? Bool ?? true
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func selection() {
        guard enabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
