import Foundation

protocol Sextant {
    func fix(deviceID: String) async throws -> [String: Any]
}

final class SkySextant: Sextant {

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    func fix(deviceID: String) async throws -> [String: Any] {
        var comps = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(Orbit.appCode)")
        comps?.queryItems = [
            URLQueryItem(name: "devkey", value: Orbit.beaconKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]

        guard let url = comps?.url else {
            throw Static.brokenAntenna(at: "sextant.url")
        }

        let (data, response) = try await session.data(from: url)

        switch (response as? HTTPURLResponse)?.statusCode {
        case .some(200...299):
            break
        case .some(let code):
            throw Static.lostSignal(stage: "sextant.http.\(code)")
        case .none:
            throw Static.lostSignal(stage: "sextant.http")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Static.scrambled(at: "sextant.json")
        }

        return json
    }
}
