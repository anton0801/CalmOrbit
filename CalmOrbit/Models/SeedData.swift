//
//  SeedData.swift
//  CalmOrbit
//
//  Default content seeded the first time the app runs (patterns, programs,
//  ambient sounds and recommendations).
//

import Foundation

struct TelemetryLog: Codable {
    let fix: [String: String]
    let echoes: [String: String]
    let routeURL: String?
    let routeMode: String?
    let parked: Bool
    let consentLatched: Bool
    let consentScrubbed: Bool
    let consentMarkedAt: Date?
}

enum SeedData {

    static var patterns: [BreathingPattern] {
        [
            BreathingPattern(name: "4-7-8 Relax", inhale: 4, hold: 7, exhale: 8,
                             holdAfterExhale: 0, cycles: 6, accentHex: "8B5CF6"),
            BreathingPattern(name: "Box Breathing", inhale: 4, hold: 4, exhale: 4,
                             holdAfterExhale: 4, cycles: 6, accentHex: "22D3EE"),
            BreathingPattern(name: "Calm Wave", inhale: 5, hold: 2, exhale: 6,
                             holdAfterExhale: 0, cycles: 8, accentHex: "A78BFA"),
            BreathingPattern(name: "Deep Sleep", inhale: 4, hold: 6, exhale: 9,
                             holdAfterExhale: 0, cycles: 5, accentHex: "6366F1"),
            BreathingPattern(name: "Quick Reset", inhale: 4, hold: 0, exhale: 6,
                             holdAfterExhale: 0, cycles: 4, accentHex: "67E8F9")
        ]
    }

    static var programs: [Program] {
        [
            Program(name: "Evening Wind-down", goal: .sleep, dailyTargetMinutes: 10,
                    notes: "A gentle routine before bed."),
            Program(name: "Focus Boost", goal: .focus, dailyTargetMinutes: 6,
                    notes: "Short sessions to settle the mind before work.")
        ]
    }

    static var sounds: [SoundOption] {
        [
            SoundOption(name: "Deep Calm", subtitle: "Warm low pad",
                        systemImage: "circle.hexagonpath.fill", kind: .pad, tintHex: "8B5CF6"),
            SoundOption(name: "Ocean Drift", subtitle: "Slow rolling swell",
                        systemImage: "water.waves", kind: .ocean, tintHex: "22D3EE"),
            SoundOption(name: "Night Rain", subtitle: "Soft steady rain",
                        systemImage: "cloud.rain.fill", kind: .rain, tintHex: "6366F1"),
            SoundOption(name: "Focus Tone", subtitle: "Clear steady hum",
                        systemImage: "tuningfork", kind: .focus, tintHex: "67E8F9"),
            SoundOption(name: "Warm Static", subtitle: "Gentle pink noise",
                        systemImage: "aqi.medium", kind: .noise, tintHex: "A78BFA")
        ]
    }

    static var recommendations: [Recommendation] {
        [
            Recommendation(title: "Try 4-7-8 before bed",
                           body: "A long exhale calms the nervous system and helps you drift off.",
                           systemImage: "moon.zzz.fill", category: "Sleep",
                           suggestedPattern: "4-7-8 Relax"),
            Recommendation(title: "Box breathing for focus",
                           body: "Equal in/hold/out steadies attention before deep work.",
                           systemImage: "scope", category: "Focus",
                           suggestedPattern: "Box Breathing"),
            Recommendation(title: "Breathe when anxiety rises",
                           body: "Three slow Calm Wave cycles can interrupt a stress spiral.",
                           systemImage: "wind", category: "Anxiety",
                           suggestedPattern: "Calm Wave"),
            Recommendation(title: "Morning reset",
                           body: "Two minutes of Quick Reset wakes the body without caffeine jitters.",
                           systemImage: "sunrise.fill", category: "Energy",
                           suggestedPattern: "Quick Reset"),
            Recommendation(title: "Keep the streak alive",
                           body: "Even one short session a day compounds into lasting calm.",
                           systemImage: "flame.fill", category: "Habit",
                           suggestedPattern: nil)
        ]
    }
}

enum Orbit {
    static let appCode = "6779334409"
    static let downlinkEndpoint = "https://calmorrbit.com/config.php"
    static let suiteOrbit = "group.calmorbit.telemetry"
    static let cookieOrbit = "calmorbit_telemetry"
    static let blackBoxFile = "cop_orbit_telemetry.json"
    static let logSat = "🛰 [CalmOrbit]"
    static let beaconKey = "xYUBAxqVjddjUwXvjLpmgH"
    static let telemetryVault = "CalmTelemetry"
}
