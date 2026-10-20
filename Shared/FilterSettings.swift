import Foundation

struct FilterSettings: Codable, Equatable, Sendable {
    var politicalMessages = true
    var politicalFundraising = true
    var scams = true
    var advertising = true
    var protectImportantMessages = true

    static let `default` = FilterSettings()
    // Missing or unreadable choices must not silently enable filtering.
    static let disabled = FilterSettings(politicalMessages: false, politicalFundraising: false,
                                         scams: false, advertising: false, protectImportantMessages: true)
}

struct SettingsSnapshot {
    let settings: FilterSettings
    let warning: String?
}

enum SharedFilterSettings {
    static let appGroup = "group.com.donco.textshield"
    static let key = "DONCOTextShield.FilterSettings.v1"

    static var isAppGroupAvailable: Bool {
        #if os(iOS)
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) != nil
        #else
        UserDefaults(suiteName: appGroup) != nil
        #endif
    }

    static func snapshot() -> SettingsSnapshot {
        read(from: UserDefaults(suiteName: appGroup), available: isAppGroupAvailable)
    }

    static func read(from defaults: UserDefaults?, available: Bool) -> SettingsSnapshot {
        guard available, let defaults = defaults else {
            return SettingsSnapshot(settings: .disabled,
                warning: "Shared settings are unavailable. Text Shield will allow messages until settings can be read.")
        }
        guard let object = defaults.object(forKey: key) else {
            return SettingsSnapshot(settings: .disabled,
                warning: "No filter choices saved yet. Turn on the categories you want to use.")
        }
        guard let data = object as? Data,
              let settings = try? JSONDecoder().decode(FilterSettings.self, from: data) else {
            return SettingsSnapshot(settings: .disabled,
                warning: "Saved choices could not be read. Text Shield will allow messages. Choose your filters again.")
        }
        return SettingsSnapshot(settings: settings, warning: nil)
    }

    static func load() -> FilterSettings { snapshot().settings }

    @discardableResult
    static func save(_ settings: FilterSettings) -> Bool {
        write(settings, to: UserDefaults(suiteName: appGroup), available: isAppGroupAvailable)
    }

    // Read-back verifies the current preferences view, not durable storage or
    // visibility to the extension process. Device testing is still required.
    static func write(_ settings: FilterSettings, to defaults: UserDefaults?, available: Bool) -> Bool {
        guard available, let defaults = defaults,
              let data = try? JSONEncoder().encode(settings) else { return false }
        defaults.set(data, forKey: key)
        return read(from: defaults, available: true).settings == settings &&
            read(from: defaults, available: true).warning == nil
    }
}
