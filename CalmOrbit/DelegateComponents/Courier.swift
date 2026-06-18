import Foundation

final class Courier {

    private let routes: [[String]] = [
        ["url"],
        ["data", "url"],
        ["aps", "data", "url"],
        ["custom", "url"]
    ]

    func deliver(_ payload: [AnyHashable: Any]) {
        guard let url = routes.lazy.compactMap({ self.dig(payload, $0) }).first else { return }
        UserDefaults.standard.set(url, forKey: OrbitKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            NotificationCenter.default.post(
                name: .uplinkURL,
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }

    private func dig(_ payload: [AnyHashable: Any], _ path: [String]) -> String? {
        guard let first = path.first else { return nil }
        if path.count == 1 {
            return payload[first] as? String
        }
        guard var node = payload[first] as? [String: Any] else { return nil }
        for key in path.dropFirst().dropLast() {
            guard let next = node[key] as? [String: Any] else { return nil }
            node = next
        }
        return node[path.last!] as? String
    }
}
