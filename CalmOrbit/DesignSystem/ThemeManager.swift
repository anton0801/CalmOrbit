//
//  ThemeManager.swift
//  CalmOrbit
//
//  App-wide theme state. Persists the user's choice and exposes the value
//  needed for `.preferredColorScheme`. Injected as an EnvironmentObject.
//

import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.stars.fill"
        }
    }
}

final class ThemeManager: ObservableObject {
    @Published var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey)
        }
    }

    static let storageKey = "app_theme_preference"

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppTheme.dark.rawValue
        self.theme = AppTheme(rawValue: raw) ?? .dark
    }

    /// Value handed to `.preferredColorScheme`. `nil` means follow the system.
    var preferredScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    /// Resolve the effective scheme used to build the palette. For `.system`
    /// the caller supplies the live environment scheme.
    func effectiveScheme(system: ColorScheme) -> ColorScheme {
        switch theme {
        case .system: return system
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
