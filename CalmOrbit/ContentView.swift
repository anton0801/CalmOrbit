//
//  ContentView.swift
//  CalmOrbit
//
//  RootView — the top-level flow coordinator. Builds the active palette from
//  the resolved color scheme (so theme changes re-skin instantly), applies
//  preferredColorScheme, and drives Splash → Onboarding → Main.
//

import SwiftUI

struct RootView: View {
    @StateObject private var theme = ThemeManager()
    @StateObject private var store = DataStore()
    @Environment(\.colorScheme) private var systemScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var stage: Stage = .main

    enum Stage { case onboarding, main }
    
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


    var body: some View {
        let scheme = theme.effectiveScheme(system: systemScheme)
        let palette = Palette.make(for: scheme)

        ZStack {
            palette.bg.ignoresSafeArea()

            switch stage {
            case .onboarding:
                OnboardingView { finishOnboarding() }
                    .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .environment(\.palette, palette)
        .accentColor(palette.accent)
        .preferredColorScheme(theme.preferredScheme)
        .animation(.easeInOut(duration: 0.5), value: stage)
        .onAppear {
            if hasCompletedOnboarding {
                stage = .main
            } else {
                stage = .onboarding
            }
            NotificationManager.shared.refreshStatus()
        }
        .environmentObject(store)
        .environmentObject(theme)
    }

    private func finishSplash() {
        stage = hasCompletedOnboarding ? .main : .onboarding
    }

    private func finishOnboarding() {
        hasCompletedOnboarding = true
        stage = .main
    }
}
