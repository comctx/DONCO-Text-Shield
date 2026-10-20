import XCTest
@testable import TextShieldCore

final class ExpandedRegressionTests: XCTestCase {
    func testSevenFailuresFromFirstFreshEvaluationAreFixed() {
        let samples: [(String, FilterDecision)] = [
            ("Your bank will never ask you to pay with gift cards.", .allow),
            ("Scam warning: Ignore texts saying claim your prize.", .allow),
            ("I do not support our candidate this year.", .allow),
            ("You won $5000. Pay a processing fee to collect.", .junk),
            ("Final toll notice: settle your overdue balance at https://toll-example.invalid now.", .junk),
            ("Security code: 418221. Reply with your password and PIN to unlock your bank account.", .junk),
            ("Your security code is 418221. Flash sale: 40% off your order. Shop now.", .promotion)
        ]
        for (message, expected) in samples {
            XCTAssertEqual(MessageClassifier.classify(message).decision, expected, message)
        }
    }

    func testTwoFailuresFromSecondEvaluationAreFixed() {
        XCTAssertEqual(MessageClassifier.classify("Security notice: We never request that you send gift card codes.").decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Your payment was declined. Update your card at https://billing-example.invalid or lose service.").decision, .junk)
        XCTAssertEqual(MessageClassifier.classify("We never request that you send gift card codes. Send gift card codes now.").decision, .junk)
        XCTAssertEqual(MessageClassifier.classify("Payment failed. Never update your card at https://example.invalid or lose service.").decision, .allow)
    }

    func testWarningCannotHideSeparateRequests() {
        for message in [
            "Your bank will never ask you to pay with gift cards. Pay with gift cards now.",
            "Ignore texts saying claim your prize. Send gift card codes now.",
            "Do not share your password. Reply with your password to unlock access.",
            "I do not support our candidate. Join our campaign today.",
            "Never pay a processing fee. You won $5000: pay a processing fee now."
        ] {
            XCTAssertEqual(MessageClassifier.classify(message).decision, .junk, message)
        }
    }

    func testNewPatternsRespectSwitchesAndWarnings() {
        var settings = FilterSettings.default
        settings.scams = false
        XCTAssertEqual(MessageClassifier.classify("Reply with your password", settings: settings).decision, .allow)
        settings = .default
        settings.advertising = false
        XCTAssertEqual(MessageClassifier.classify("Your security code is 418221. Flash sale: 40% off your order.", settings: settings).decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Never share your password.").decision, .allow)
        let service = "Appointment reminder: Tuesday at 2 PM. Your promo code is on your receipt."
        XCTAssertEqual(MessageClassifier.classify(service).decision, .allow)
        settings = .default
        settings.protectImportantMessages = false
        XCTAssertEqual(MessageClassifier.classify(service, settings: settings).decision, .promotion)
        XCTAssertEqual(MessageClassifier.classify("Your bank will never ask you to send gift card codes.").decision, .allow)
    }
}
