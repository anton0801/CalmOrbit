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
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var systemScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var stage: Stage = .splash

    enum Stage { case splash, onboarding, main }

    var body: some View {
        let scheme = theme.effectiveScheme(system: systemScheme)
        let palette = Palette.make(for: scheme)

        ZStack {
            palette.bg.ignoresSafeArea()

            switch stage {
            case .splash:
                SplashView { finishSplash() }
                    .transition(.opacity)
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
        .onAppear { NotificationManager.shared.refreshStatus() }
    }

    private func finishSplash() {
        stage = hasCompletedOnboarding ? .main : .onboarding
    }

    private func finishOnboarding() {
        hasCompletedOnboarding = true
        stage = .main
    }
}
