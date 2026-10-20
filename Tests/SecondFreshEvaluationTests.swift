import XCTest
@testable import TextShieldCore

final class SecondFreshEvaluationTests: XCTestCase {
    // Written after revision 2, before executing it. Diagnostic only.
    // Synthetic same-author examples; not independent real-world validation.
    func testReportTwentyAdditionalMessages() {
        let samples: [(String, String, FilterDecision)] = [
            ("bank-reminder", "We will never ask you to share your password.", .allow),
            ("bank-more", "Your bank will never ask anyone to pay with gift cards.", .allow),
            ("quoted", "Ignore messages that say claim your prize.", .allow),
            ("appointment", "Appointment reminder: Friday at noon. Your promo code is on the receipt.", .allow),
            ("voting", "Election office: cast your vote before 7 PM.", .allow),
            ("school", "School closes early tomorrow. Pickup is at noon.", .allow),
            ("delivery", "Delivery confirmation: collect your parcel at the counter.", .allow),
            ("negation", "I don't support the candidate.", .allow),
            ("auth", "Authentication code: 873921. Expires in five minutes.", .allow),
            ("bank-warning-variant", "Bank warning: Never give anyone your password or PIN.", .allow),
            ("password", "Send your password to confirm your account.", .junk),
            ("pin", "Reply with your PIN to restore access.", .junk),
            ("prize", "You have won $1000. Pay the release fee now.", .junk),
            ("toll", "Outstanding toll notice: pay your balance at https://example.invalid now.", .junk),
            ("mixed", "Ignore messages that say claim your prize. Share your password now.", .junk),
            ("campaign", "Independent campaign: Join our campaign and vote early.", .junk),
            ("fundraiser", "Republican Senate campaign: contribute $10 today.", .junk),
            ("sale", "Login code: 823194. Exclusive deal: shop now for 50% off.", .promotion),
            ("scam-new", "Your payment was declined. Update your card at https://billing-example.invalid or lose service.", .junk),
            ("warning-variant", "Security notice: We never request that you send gift card codes.", .allow)
        ]
        var falsePositives = 0
        var misses = 0
        for (id, message, expected) in samples {
            let actual = MessageClassifier.classify(message).decision
            if expected == .allow && actual != .allow { falsePositives += 1 }
            if expected != .allow && actual == .allow { misses += 1 }
            print("SECOND FRESH \(id): expected=\(expected.rawValue), actual=\(actual.rawValue)")
        }
        print("SECOND FRESH: 11 legitimate, 9 unwanted; false positives=\(falsePositives), misses=\(misses). Diagnostic only, not an accuracy pass gate.")
    }
}
