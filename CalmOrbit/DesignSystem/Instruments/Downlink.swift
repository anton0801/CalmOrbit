import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

protocol Downlink {
    func transmit(packet: [String: Any]) async throws -> String
}

final class GroundLink: Downlink {

    private enum Reception {
        case cleared(String)
        case throttled(TimeInterval)
        case shuttered(Static)
        case scrambled(Static)
    }

    private let session: URLSession
    private let arc: [Double] = [80.0, 160.0, 320.0]

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    private var agent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""

    func transmit(packet: [String: Any]) async throws -> String {
        let request = try assemble(packet)

        var attempt = 0
        var carried: Error? = nil

        while attempt < arc.count {
            let reception: Reception
            do {
                reception = try await receive(request)
            } catch {
                carried = error
                attempt += 1
                if attempt < arc.count { try await nap(arc[attempt - 1]) }
                continue
            }

            switch reception {
            case .cleared(let url):
                return url
            case .shuttered(let sealed):
                throw sealed
            case .throttled(let cooldown):
                try await nap(cooldown)
                attempt += 1
                continue
            case .scrambled(let noise):
                carried = noise
                attempt += 1
                if attempt < arc.count { try await nap(arc[attempt - 1]) }
            }
        }

        throw carried ?? Static.lostSignal(stage: "downlink.exhausted")
    }

    private func assemble(_ packet: [String: Any]) throws -> URLRequest {
        guard let endpoint = URL(string: Orbit.downlinkEndpoint) else {
            throw Static.brokenAntenna(at: "downlink.url")
        }

        var body: [String: Any] = packet
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(Orbit.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: OrbitKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(agent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func receive(_ request: URLRequest) async throws -> Reception {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            return .scrambled(.lostSignal(stage: "downlink.response"))
        }

        switch http.statusCode {
        case 404:
            return .shuttered(.hatchSealed(httpCode: 404))
        case 429:
            let after = TimeInterval(http.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            return .throttled(after)
        case 200...299:
            break
        default:
            return .scrambled(.lostSignal(stage: "downlink.status.\(http.statusCode)"))
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .scrambled(.scrambled(at: "downlink.json"))
        }

        guard let ok = json["ok"] as? Bool else {
            return .scrambled(.scrambled(at: "downlink.missingOk"))
        }

        guard ok else {
            return .shuttered(.groundClosed(reason: "okFalse"))
        }

        guard let url = json["url"] as? String, !url.isEmpty else {
            return .scrambled(.scrambled(at: "downlink.missingURL"))
        }

        return .cleared(url)
    }

    private func nap(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
