import Foundation

struct AppInfo {
    private static func bundleInfo(_ keys: String...) -> String {
        for key in keys {
            if let value = Bundle.main.infoDictionary?[key] as? String,
               !value.isEmpty {
                return value
            }
        }
        return ""
    }

    var json: [String: Any] = [:]

    init(json: [String: Any] = [:]) {
        self.json = json
    }

    static func create() async throws -> Self {
        let urlPrefix = "https://itunes.apple.com/lookup?bundleId="
        let identifier = bundleInfo("CFBundleIdentifier")
        let url = URL(string: "\(urlPrefix)\(identifier)&country=US")
        guard let url else {
            throw AppError(
                message: "AppInfo: bad URL \(String(describing: url))"
            )
        }

        // Using the ephemeral configuration avoids caching.
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(from: url)
        if let response = response as? HTTPURLResponse,
           !(200 ... 299).contains(response.statusCode) {
            throw AppError(
                message: "AppInfo: HTTP status \(response.statusCode)"
            )
        }

        guard let json = try JSONSerialization.jsonObject(
            with: data,
            options: [.allowFragments]
        ) as? [String: Any] else {
            throw AppError(message: "AppInfo: bad JSON")
        }

        guard let results =
            (json["results"] as? [Any])?.first as? [String: Any] else {
            return Self()
        }

        // After a new version is released, there seems to be a
        // delay in the app detecting that from the URL above.
        // Perhaps users won't see the "Update Available" link
        // until the next day.
        // print("AppInfo.create: version =", results["version"])

        return Self(json: results)
    }

    private func date(_ key: String) -> Date? {
        if let value = json[key] as? Date { return value }
        guard let value = json[key] as? String else { return nil }
        return date(from: value)
    }

    private func double(_ key: String) -> Double {
        json[key] as? Double ?? 0
    }

    private func date(from value: String) -> Date? {
        let fractionalSecondsFormatter = ISO8601DateFormatter()
        fractionalSecondsFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        if let date = fractionalSecondsFormatter.date(from: value) {
            return date
        }

        return ISO8601DateFormatter().date(from: value)
    }

    private func info(_ key: String) -> String {
        Self.bundleInfo(key)
    }

    private func int(_ key: String) -> Int {
        json[key] as? Int ?? 0
    }

    private func string(_ key: String, fallback: String = "") -> String {
        json[key] as? String ?? fallback
    }

    var appId: Int { int("trackId") }
    var appURL: String { string("trackViewUrl") }
    var author: String { string("sellerName") }
    var bundleId: String { string("bundleId", fallback: identifier) }
    var description: String { string("description") }
    var iconURL: String { string("artworkUrl100") }
    var supportURL: String { string("sellerUrl") }

    var haveLatestVersion: Bool {
        let order = storeVersion.compare(installedVersion, options: .numeric)
        return order != .orderedDescending
    }

    var installedVersion: String { info("CFBundleShortVersionString") }
    var identifier: String { info("CFBundleIdentifier") }
    var minimumOsVersion: String { string("minimumOsVersion") }
    var name: String {
        string(
            "trackName",
            fallback: Self.bundleInfo("CFBundleDisplayName", "CFBundleName")
        )
    }

    // "Promotional Text" is not present in the App Store JSON.
    var price: Double { double("price") }
    var releaseDate: Date? { date("currentVersionReleaseDate") }
    var releaseNotes: String { string("releaseNotes") }
    var storeVersion: String { string("version", fallback: installedVersion) }
}
