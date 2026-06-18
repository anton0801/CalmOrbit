import Foundation

protocol BlackBox {
    func write(_ log: TelemetryLog)
    func brandRoute(url: String, mode: String)
    func raisePrimedFlag()
    func read() -> TelemetryLog
}

final class FlightRecorder: BlackBox {

    private let fm = FileManager.default
    private let vaultDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.vaultDir = docs.appendingPathComponent(Orbit.telemetryVault, isDirectory: true)
        if !fm.fileExists(atPath: vaultDir.path) {
            try? fm.createDirectory(at: vaultDir, withIntermediateDirectories: true)
        }
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: Orbit.suiteOrbit) ?? .standard
    }

    private var recorderURL: URL {
        vaultDir.appendingPathComponent(Orbit.blackBoxFile)
    }

    func write(_ log: TelemetryLog) {
        let masked = MaskedLog(
            fix: maskMap(log.fix),
            echoes: maskMap(log.echoes),
            routeURL: log.routeURL,
            routeMode: log.routeMode,
            parked: log.parked,
            consentLatched: log.consentLatched,
            consentScrubbed: log.consentScrubbed,
            consentMarkedAt: log.consentMarkedAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970

        do {
            let data = try encoder.encode(masked)
            try data.write(to: recorderURL, options: .atomic)
        } catch {
            print("\(Orbit.logSat) BlackBox write failed: \(error)")
        }

        [suiteStore, homeStore].forEach { store in
            store.set(log.consentLatched, forKey: OrbitKey.consentLatched)
            store.set(log.consentScrubbed, forKey: OrbitKey.consentScrubbed)
            if let date = log.consentMarkedAt {
                store.set(date.timeIntervalSince1970, forKey: OrbitKey.consentMarkedAt)
            }
        }
    }

    func brandRoute(url: String, mode: String) {
        suiteStore.set(url, forKey: OrbitKey.routeURL)
        homeStore.set(url, forKey: OrbitKey.routeURL)
        suiteStore.set(mode, forKey: OrbitKey.routeMode)
    }

    func raisePrimedFlag() {
        suiteStore.set(true, forKey: OrbitKey.primed)
        homeStore.set(true, forKey: OrbitKey.primed)
    }

    func read() -> TelemetryLog {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        if fm.fileExists(atPath: recorderURL.path),
           let data = try? Data(contentsOf: recorderURL),
           let masked = try? decoder.decode(MaskedLog.self, from: data) {
            return TelemetryLog(
                fix: unmaskMap(masked.fix),
                echoes: unmaskMap(masked.echoes),
                routeURL: masked.routeURL,
                routeMode: masked.routeMode,
                parked: masked.parked,
                consentLatched: masked.consentLatched,
                consentScrubbed: masked.consentScrubbed,
                consentMarkedAt: masked.consentMarkedAt
            )
        }

        return readFromMirror()
    }

    private func readFromMirror() -> TelemetryLog {
        let routeURL = homeStore.string(forKey: OrbitKey.routeURL)
            ?? suiteStore.string(forKey: OrbitKey.routeURL)
        let routeMode = suiteStore.string(forKey: OrbitKey.routeMode)
        let primed = suiteStore.bool(forKey: OrbitKey.primed)

        let latched = suiteStore.bool(forKey: OrbitKey.consentLatched)
            || homeStore.bool(forKey: OrbitKey.consentLatched)
        let scrubbed = suiteStore.bool(forKey: OrbitKey.consentScrubbed)
            || homeStore.bool(forKey: OrbitKey.consentScrubbed)
        let markedTs = suiteStore.double(forKey: OrbitKey.consentMarkedAt)
        let markedAt: Date? = markedTs > 0 ? Date(timeIntervalSince1970: markedTs) : nil

        return TelemetryLog(
            fix: [:],
            echoes: [:],
            routeURL: routeURL,
            routeMode: routeMode,
            parked: !primed,
            consentLatched: latched,
            consentScrubbed: scrubbed,
            consentMarkedAt: markedAt
        )
    }

    private func maskMap(_ dict: [String: String]) -> [String: String] {
        dict.reduce(into: [:]) { acc, pair in acc[pair.key] = mask(pair.value) }
    }

    private func unmaskMap(_ dict: [String: String]) -> [String: String] {
        dict.reduce(into: [:]) { acc, pair in acc[pair.key] = unmask(pair.value) ?? pair.value }
    }

    private func mask(_ input: String) -> String {
        Data(input.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: ")")
            .replacingOccurrences(of: "/", with: ":")
    }

    private func unmask(_ input: String) -> String? {
        let restored = input
            .replacingOccurrences(of: ")", with: "+")
            .replacingOccurrences(of: ":", with: "/")
        guard let data = Data(base64Encoded: restored),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

struct MaskedLog: Codable {
    let fix: [String: String]
    let echoes: [String: String]
    let routeURL: String?
    let routeMode: String?
    let parked: Bool
    let consentLatched: Bool
    let consentScrubbed: Bool
    let consentMarkedAt: Date?
}
