import Foundation

struct Telemetry {
    var fix: [String: String] = [:]
    var echoes: [String: String] = [:]
    var routeURL: String? = nil
    var routeMode: String? = nil
    var parked: Bool = true
    var replayed: Bool = false
    var consentLatched: Bool = false
    var consentScrubbed: Bool = false
    var consentMarkedAt: Date? = nil

    var locked: Bool { !fix.isEmpty }
    var organicDrift: Bool { fix["af_status"] == "Organic" }

    var airlockDue: Bool {
        guard !consentLatched && !consentScrubbed else { return false }
        if let date = consentMarkedAt {
            return Date().timeIntervalSince(date) / 86400 >= 3
        }
        return true
    }

    static func restore(from log: TelemetryLog) -> Telemetry {
        var t = Telemetry()
        t.fix = log.fix
        t.echoes = log.echoes
        t.routeURL = log.routeURL
        t.routeMode = log.routeMode
        t.parked = log.parked
        t.consentLatched = log.consentLatched
        t.consentScrubbed = log.consentScrubbed
        t.consentMarkedAt = log.consentMarkedAt
        return t
    }

    func snapshot() -> TelemetryLog {
        TelemetryLog(
            fix: fix,
            echoes: echoes,
            routeURL: routeURL,
            routeMode: routeMode,
            parked: parked,
            consentLatched: consentLatched,
            consentScrubbed: consentScrubbed,
            consentMarkedAt: consentMarkedAt
        )
    }
}

enum Signal: Equatable {
    case coasting
    case hailConsent
    case dock
    case tumble
}
