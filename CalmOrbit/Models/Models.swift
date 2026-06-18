//
//  Models.swift
//  CalmOrbit
//
//  Core data models and enums. Everything is Codable + Identifiable so the
//  DataStore can persist collections as JSON in UserDefaults.
//

import SwiftUI

// MARK: - Enums

enum Goal: String, CaseIterable, Codable, Identifiable {
    case sleep, focus, anxiety, calm
    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep:   return "Sleep"
        case .focus:   return "Focus"
        case .anxiety: return "Anxiety"
        case .calm:    return "Calm"
        }
    }

    var icon: String {
        switch self {
        case .sleep:   return "moon.zzz.fill"
        case .focus:   return "scope"
        case .anxiety: return "wind"
        case .calm:    return "leaf.fill"
        }
    }

    var tintHex: String {
        switch self {
        case .sleep:   return "6366F1"
        case .focus:   return "22D3EE"
        case .anxiety: return "A78BFA"
        case .calm:    return "34D399"
        }
    }

    var color: Color { Color(hex: tintHex) }
}

extension Notification.Name {
    static let lockArrived = Notification.Name("ConversionDataReceived")
    static let echoesArrived = Notification.Name("deeplink_values")
    static let uplinkURL = Notification.Name("LoadTempURL")
}

enum MoodType: String, CaseIterable, Codable, Identifiable {
    case calm, focused, happy, tired, stressed
    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm:     return "Calm"
        case .focused:  return "Focused"
        case .happy:    return "Happy"
        case .tired:    return "Tired"
        case .stressed: return "Stressed"
        }
    }

    var emoji: String {
        switch self {
        case .calm:     return "😌"
        case .focused:  return "🎯"
        case .happy:    return "😊"
        case .tired:    return "🥱"
        case .stressed: return "😣"
        }
    }

    var icon: String {
        switch self {
        case .calm:     return "leaf.fill"
        case .focused:  return "scope"
        case .happy:    return "sun.max.fill"
        case .tired:    return "moon.zzz.fill"
        case .stressed: return "bolt.fill"
        }
    }

    var tintHex: String {
        switch self {
        case .calm:     return "34D399"
        case .focused:  return "22D3EE"
        case .happy:    return "A78BFA"
        case .tired:    return "818CF8"
        case .stressed: return "F87171"
        }
    }

    var color: Color { Color(hex: tintHex) }

    /// Numeric value used for the mood trend chart (higher = calmer / better).
    var score: Double {
        switch self {
        case .calm:     return 5
        case .happy:    return 4.2
        case .focused:  return 3.8
        case .tired:    return 2.2
        case .stressed: return 1.0
        }
    }
}

enum RecordCategory: String, CaseIterable, Codable, Identifiable {
    case session, note
    var id: String { rawValue }
    var title: String { self == .session ? "Session" : "Note" }
    var icon: String { self == .session ? "wind" : "note.text" }
}

enum SoundKind: String, Codable {
    case pad, ocean, rain, focus, noise

    /// Base sine frequency in Hz (0 = no tonal layer).
    var baseFrequency: Double {
        switch self {
        case .pad:   return 110
        case .ocean: return 70
        case .rain:  return 0
        case .focus: return 220
        case .noise: return 0
        }
    }

    var harmonicFrequency: Double {
        switch self {
        case .pad:   return 164.81
        case .focus: return 329.63
        default:     return 0
        }
    }

    /// Amount of filtered noise mixed in (0...1).
    var noiseLevel: Double {
        switch self {
        case .pad:   return 0.06
        case .ocean: return 0.55
        case .rain:  return 0.5
        case .focus: return 0.03
        case .noise: return 0.4
        }
    }

    /// One-pole low-pass smoothing for the noise (higher = darker).
    var noiseDamping: Double {
        switch self {
        case .ocean: return 0.92
        case .rain:  return 0.6
        case .noise: return 0.8
        default:     return 0.85
        }
    }

    /// Slow amplitude wobble rate (Hz) that gives a breathing motion.
    var lfoRate: Double {
        switch self {
        case .pad:   return 0.08
        case .ocean: return 0.12
        case .rain:  return 0.0
        case .focus: return 0.0
        case .noise: return 0.05
        }
    }
}

// MARK: - Models

struct BreathingPattern: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var inhale: Int
    var hold: Int
    var exhale: Int
    var holdAfterExhale: Int = 0
    var cycles: Int
    var accentHex: String = "8B5CF6"
    var isArchived: Bool = false
    var createdAt: Date = Date()

    var cycleSeconds: Int { inhale + hold + exhale + holdAfterExhale }
    var totalSeconds: Int { cycleSeconds * cycles }

    var ratioText: String {
        var parts = ["\(inhale)", "\(hold)", "\(exhale)"]
        if holdAfterExhale > 0 { parts.append("\(holdAfterExhale)") }
        return parts.joined(separator: "-")
    }

    var durationText: String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        if m == 0 { return "\(s)s" }
        return s == 0 ? "\(m) min" : "\(m)m \(s)s"
    }

    var accent: Color { Color(hex: accentHex) }
}

struct Program: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var goal: Goal
    var dailyTargetMinutes: Int
    var startDate: Date = Date()
    var notes: String = ""
    var isArchived: Bool = false
    var createdAt: Date = Date()
}

struct SessionRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var programID: UUID?
    var date: Date = Date()
    var category: RecordCategory = .session
    var valueMinutes: Double
    var comment: String = ""
    var mood: MoodType?
    var patternID: UUID?
    var createdAt: Date = Date()

    var minutesText: String {
        if valueMinutes < 1 { return "\(Int(valueMinutes * 60))s" }
        let rounded = (valueMinutes * 10).rounded() / 10
        return rounded == rounded.rounded() ? "\(Int(rounded)) min" : String(format: "%.1f min", rounded)
    }
}

enum Static: Error, CustomStringConvertible {
    case voidField(at: String)
    case brokenAntenna(at: String)
    case lostSignal(stage: String)
    case bandThrottled(cooldown: TimeInterval)
    case hatchSealed(httpCode: Int)
    case groundClosed(reason: String)
    case scrambled(at: String)

    var description: String {
        switch self {
        case .voidField(let at): return "voidField(\(at))"
        case .brokenAntenna(let at): return "brokenAntenna(\(at))"
        case .lostSignal(let stage): return "lostSignal(\(stage))"
        case .bandThrottled(let cd): return "bandThrottled(cd=\(cd))"
        case .hatchSealed(let code): return "hatchSealed(\(code))"
        case .groundClosed(let reason): return "groundClosed(\(reason))"
        case .scrambled(let at): return "scrambled(\(at))"
        }
    }

    var isSealed: Bool {
        switch self {
        case .hatchSealed, .groundClosed: return true
        default: return false
        }
    }
}


struct MoodEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var mood: MoodType
    var note: String = ""
    var createdAt: Date = Date()
}

struct HabitTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var detail: String = ""
    var dueDate: Date
    var isDone: Bool = false
    var repeatsDaily: Bool = false
    var reminderEnabled: Bool = false
    var createdAt: Date = Date()

    var notificationID: String { "task-\(id.uuidString)" }

    func isMissed(reference: Date = Date()) -> Bool {
        guard !isDone else { return false }
        return dueDate < reference && !Calendar.current.isDate(dueDate, inSameDayAs: reference)
    }
}

struct SoundOption: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var subtitle: String
    var systemImage: String
    var kind: SoundKind
    var tintHex: String

    var color: Color { Color(hex: tintHex) }
}

enum OrbitKey {
    static let routeURL = "cop_route_url"
    static let routeMode = "cop_route_mode"
    static let primed = "cop_primed"

    static let consentLatched = "cop_consent_latched"
    static let consentScrubbed = "cop_consent_scrubbed"
    static let consentMarkedAt = "cop_consent_marked_at"

    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
}

struct Recommendation: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var systemImage: String
    var category: String
    var suggestedPattern: String?
    var isSaved: Bool = false
    var isDismissed: Bool = false
}
