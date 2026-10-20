import XCTest
@testable import TextShieldCore

final class RuleComparisonTests: XCTestCase {
    // Synthetic development examples, not independent validation or accuracy estimates.
    private let samples: [(String, String, FilterDecision)] = [
        ("verification", "Your verification code is 123456", .allow),
        ("appointment", "Appointment reminder: Tuesday at 2 PM", .allow),
        ("delivery", "Your package is out for delivery", .allow),
        ("personal", "Dinner at six? Bring the pie.", .allow),
        ("voting", "County election office: Vote early. Polls open at 7 AM.", .allow),
        ("ballot", "County election office: Request your ballot by Friday. Reply STOP to end.", .allow),
        ("gift-warning", "Bank notice: Do not pay with gift cards.", .allow),
        ("codes-warning", "Safety notice: Never send gift card codes.", .allow),
        ("fraud-alert", "Fraud alert: Did you make a purchase for $42?", .allow),
        ("prescription", "Your prescription is ready for pickup.", .allow),
        ("prize-bypass", "Your verification code is 123456. Claim your prize now.", .junk),
        ("gift-bypass", "Fraud alert: Pay with gift cards to unlock your account.", .junk),
        ("suspension-bypass", "Security code 123456. Your account will be suspended click here.", .junk),
        ("mixed-warning", "Never send gift card codes. But pay with gift cards to unlock your account.", .junk),
        ("prize", "Claim your prize now", .junk),
        ("crypto", "Guaranteed crypto returns: double your bitcoin.", .junk),
        ("democratic", "Democratic campaign: We need your vote. Vote for our candidate.", .junk),
        ("republican", "Republican campaign: We need your vote. Vote for our candidate.", .junk),
        ("fundraising", "Chip in $10 to help our Senate campaign", .junk),
        ("advertising", "Flash sale: take 30% off your order", .promotion)
    ]

    func testTwentyMessageComparison() {
        var oldFalsePositives = 0
        var oldMisses = 0
        var newFalsePositives = 0
        var newMisses = 0
        for (id, message, expected) in samples {
            let old = BaselineMessageClassifier.classify(message).decision
            let new = MessageClassifier.classify(message).decision
            if expected == .allow {
                if old != .allow { oldFalsePositives += 1 }
                if new != .allow { newFalsePositives += 1 }
            } else {
                if old == .allow { oldMisses += 1 }
                if new == .allow { newMisses += 1 }
            }
            print("\(id): expected=\(expected.rawValue), baseline=\(old.rawValue), revised=\(new.rawValue)")
            XCTAssertEqual(new, expected, id)
        }
        print("20 synthetic examples (10 legitimate, 10 unwanted). Baseline: false positives=\(oldFalsePositives), misses=\(oldMisses). Revised: false positives=\(newFalsePositives), misses=\(newMisses).")
        XCTAssertLessThan(newFalsePositives, oldFalsePositives)
        XCTAssertLessThan(newMisses, oldMisses)
    }

    func testWarningDoesNotDisableOtherSignalsOrLaterOccurrences() {
        for message in [
            "Do not pay with gift cards. Send gift card codes now.",
            "Never pay with gift cards. Actually pay with gift cards now.",
            "Don't send gift card codes, but claim your prize now.",
            "Don’t pay with gift cards, but double your bitcoin.",
            "Never pay with gift cards to avoid arrest."
        ] {
            XCTAssertEqual(MessageClassifier.classify(message).decision, .junk, message)
        }
        XCTAssertEqual(MessageClassifier.classify("Don't pay with gift cards.").decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Don’t send gift card codes.").decision, .allow)
    }

    func testSettingsStillControlEachCategory() {
        var settings = FilterSettings.default
        settings.scams = false
        XCTAssertEqual(MessageClassifier.classify("Verification code: claim your prize", settings: settings).decision, .allow)
        settings = .default
        settings.protectImportantMessages = false
        XCTAssertEqual(MessageClassifier.classify("Your verification code: claim your prize", settings: settings).decision, .junk)
        XCTAssertEqual(MessageClassifier.classify("Election office: Vote early.", settings: settings).decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Our campaign: vote early! Verification code 123456.").decision, .junk)
    }
}
