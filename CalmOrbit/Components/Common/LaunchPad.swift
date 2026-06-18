import Foundation

final class Console {
    let blackBox: BlackBox
    let sextant: Sextant
    let downlink: Downlink
    let airlock: Airlock

    init(blackBox: BlackBox, sextant: Sextant, downlink: Downlink, airlock: Airlock) {
        self.blackBox = blackBox
        self.sextant = sextant
        self.downlink = downlink
        self.airlock = airlock
    }

    static func mannedConsole() -> Console {
        Console(
            blackBox: FlightRecorder(),
            sextant: SkySextant(),
            downlink: GroundLink(),
            airlock: HatchAirlock()
        )
    }
}

@MainActor
final class LaunchPad {

    static let shared = LaunchPad()

    private var bays: [String: Any] = [:]

    private init() {}

    func mount<T>(_ instance: T, as type: T.Type) {
        bays[String(describing: type)] = instance
    }

    func deploy<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        if let instance = bays[key] as? T {
            return instance
        }
        let built = fabricate(type)
        bays[key] = built
        return built
    }

    private func fabricate<T>(_ type: T.Type) -> T {
        switch String(describing: type) {
        case String(describing: Console.self):
            return Console.mannedConsole() as! T
        case String(describing: MissionControl.self):
            return MissionControl(console: deploy(Console.self)) as! T
        default:
            fatalError("LaunchPad: no builder for \(type)")
        }
    }
}
