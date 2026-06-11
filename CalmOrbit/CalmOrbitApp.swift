//
//  CalmOrbitApp.swift
//  CalmOrbit
//
//  App entry point. Injects the shared ThemeManager and DataStore and hosts
//  the RootView flow (Splash → Onboarding on first launch → Main).
//

import SwiftUI
import UIKit

@main
struct CalmOrbitApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var store = DataStore()

    init() {
        // Register sensible defaults the first time the app runs so the
        // Settings toggles start in the expected state.
        let defaults = UserDefaults.standard
        if defaults.object(forKey: SoundPref.key) == nil {
            defaults.set(true, forKey: SoundPref.key)
        }
        if defaults.object(forKey: HapticPref.key) == nil {
            defaults.set(true, forKey: HapticPref.key)
        }
        // Make TextEditor backgrounds transparent so they match the theme.
        UITextView.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(theme)
                .environmentObject(store)
        }
    }
}
