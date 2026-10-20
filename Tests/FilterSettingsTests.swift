import XCTest
@testable import TextShieldCore

final class FilterSettingsTests: XCTestCase {
    private func withStore(_ body: (UserDefaults) throws -> Void) rethrows {
        let name = "TextShieldTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults)
    }

    func testMissingSettingsAllowMessagesAndGiveNotice() {
        withStore { defaults in
            let snapshot = SharedFilterSettings.read(from: defaults, available: true)
            XCTAssertEqual(snapshot.settings, .disabled)
            XCTAssertNotNil(snapshot.warning)
            XCTAssertEqual(MessageClassifier.classify("Claim your prize", settings: snapshot.settings).decision, .allow)
        }
    }

    func testCorruptOrWrongTypeSettingsDoNotEnableFilters() {
        withStore { defaults in
            let invalidObjects: [Any] = [Data("broken".utf8), "not encoded settings", Data("{}".utf8)]
            for object in invalidObjects {
                defaults.set(object, forKey: SharedFilterSettings.key)
                let snapshot = SharedFilterSettings.read(from: defaults, available: true)
                XCTAssertEqual(snapshot.settings, .disabled)
                XCTAssertNotNil(snapshot.warning)
            }
        }
    }

    func testUnavailableStorageFailsWithoutOverwritingChoices() {
        withStore { defaults in
            XCTAssertTrue(SharedFilterSettings.write(.default, to: defaults, available: true))
            XCTAssertFalse(SharedFilterSettings.write(.disabled, to: defaults, available: false))
            XCTAssertEqual(SharedFilterSettings.read(from: defaults, available: false).settings, .disabled)
            XCTAssertEqual(SharedFilterSettings.read(from: defaults, available: true).settings, .default)
            XCTAssertFalse(SharedFilterSettings.write(.default, to: nil, available: true))
            XCTAssertNotNil(SharedFilterSettings.read(from: nil, available: true).warning)
        }
    }

    func testRoundTripPreservesEveryChoiceAndAllOff() {
        withStore { defaults in
            var selected = FilterSettings.default
            selected.politicalMessages = false
            selected.scams = false
            selected.protectImportantMessages = false
            XCTAssertTrue(SharedFilterSettings.write(selected, to: defaults, available: true))
            XCTAssertEqual(SharedFilterSettings.read(from: defaults, available: true).settings, selected)
            XCTAssertNil(SharedFilterSettings.read(from: defaults, available: true).warning)
            XCTAssertTrue(SharedFilterSettings.write(.disabled, to: defaults, available: true))
            XCTAssertEqual(SharedFilterSettings.read(from: defaults, available: true).settings, .disabled)
        }
    }
}
