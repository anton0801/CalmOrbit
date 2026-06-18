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
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegatingApp

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}
