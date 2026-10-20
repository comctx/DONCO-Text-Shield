import XCTest
@testable import TextShieldCore

final class FreshEvaluationTests: XCTestCase {
    // Authored AFTER the first rule revision, before running this evaluation.
    // No classifier tuning in this commit. This reports errors; it is not a
    // release gate or a passing-accuracy assertion. Synthetic and same-author.
    func testReportFreshThirtyMessageEvaluation() {
        let samples: [(String, String, FilterDecision)] = [
            ("bank-warning", "Your bank will never ask you to pay with gift cards.", .allow),
            ("bank-warning-two", "Reminder: Do not ever send gift card codes to anyone.", .allow),
            ("voting-info", "County election notice: Your vote matters. Polls close at 7 PM.", .allow),
            ("ballot-info", "Election office: Your ballot was received. Reply STOP to end.", .allow),
            ("medical", "Your appointment is tomorrow. Please bring your insurance card.", .allow),
            ("delivery", "Delivery confirmation: left at your front door.", .allow),
            ("code", "Your one-time passcode is 481920. Do not share it.", .allow),
            ("travel", "Flight confirmation: departure at 8:30 AM.", .allow),
            ("personal", "We discussed the Senate election at dinner.", .allow),
            ("donation-personal", "Can you donate blankets to the shelter?", .allow),
            ("quoted-prize", "Scam warning: Ignore texts saying claim your prize.", .allow),
            ("negated-campaign", "I do not support our candidate this year.", .allow),
            ("prescription", "Your prescription is ready at the pharmacy.", .allow),
            ("account-info", "Your account statement is ready to view in our app.", .allow),
            ("invoice", "Invoice 381 is due Friday. Call the office with questions.", .allow),
            ("disguised-code", "Login code: 441122. Send gift card codes to avoid arrest.", .junk),
            ("fake-bank", "Fraud alert: Your account will be suspended click this link.", .junk),
            ("fake-delivery", "Out for delivery: your package cannot be delivered pay now.", .junk),
            ("prize-paraphrase", "You won $5000. Pay a processing fee to collect.", .junk),
            ("toll-paraphrase", "Final toll notice: settle your overdue balance at https://toll-example.invalid now.", .junk),
            ("credential", "Security code: 418221. Reply with your password and PIN to unlock your bank account.", .junk),
            ("crypto", "Double your bitcoin with guaranteed crypto returns.", .junk),
            ("gift-demand", "Pay with gift cards now to restore access.", .junk),
            ("warning-plus-demand", "Do not send gift card codes. Pay with gift cards now.", .junk),
            ("democratic-appeal", "Democratic campaign: Donate $5 today.", .junk),
            ("republican-appeal", "Republican campaign: Donate $5 today.", .junk),
            ("independent-appeal", "Independent campaign: Donate $5 today.", .junk),
            ("campaign-code", "Verification code 418221. Join our campaign: we need your vote.", .junk),
            ("marketing-code", "Your security code is 418221. Flash sale: 40% off your order. Shop now.", .promotion),
            ("sale", "Limited time offer: 20% off your purchase. Buy now.", .promotion)
        ]
        var falsePositives = 0
        var misses = 0
        var wrongCategory = 0
        for (id, message, expected) in samples {
            let actual = MessageClassifier.classify(message).decision
            if expected == .allow && actual != .allow { falsePositives += 1 }
            if expected != .allow && actual == .allow { misses += 1 }
            if expected != .allow && actual != .allow && actual != expected { wrongCategory += 1 }
            print("FRESH \(id): expected=\(expected.rawValue), actual=\(actual.rawValue)")
        }
        print("FRESH EVALUATION: 15 legitimate, 15 unwanted; false positives=\(falsePositives), misses=\(misses), wrong category=\(wrongCategory). Known failures are reported, not suppressed or asserted away.")
    }
}
