import Foundation

struct FilterSettings: Codable, Equatable, Sendable {
    var politicalMessages = true
    var politicalFundraising = true
    var scams = true
    var advertising = true
    var protectImportantMessages = true

    static let `default` = FilterSettings()
}

enum SharedFilterSettings {
    static let appGroup = "group.com.donco.textshield"
    private static let key = "DONCOTextShield.FilterSettings.v1"

    static var isAppGroupAvailable: Bool {
        #if os(iOS)
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) != nil
        #else
        UserDefaults(suiteName: appGroup) != nil
        #endif
    }

    static func load() -> FilterSettings {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key),
              let settings = try? JSONDecoder().decode(FilterSettings.self, from: data)
        else { return .default }
        return settings
    }

    @discardableResult
    static func save(_ settings: FilterSettings) -> Bool {
        guard isAppGroupAvailable,
              let defaults = UserDefaults(suiteName: appGroup),
              let data = try? JSONEncoder().encode(settings) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}
