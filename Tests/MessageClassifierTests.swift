import XCTest
@testable import TextShieldCore

final class MessageClassifierTests: XCTestCase {
    func testScamSignalsCannotBeBypassedWithImportantKeywords() {
        for prefix in ["Fraud alert: ", "Your verification code is 123456. "] {
            XCTAssertEqual(MessageClassifier.classify(prefix + "Pay with gift cards to avoid arrest").decision, .junk)
        }
    }
    func testImportantMessagePrecedesPoliticalRules() {
        XCTAssertEqual(MessageClassifier.classify("Your campaign account verification code is 123456. Join our campaign.").decision, .allow)
        var settings = FilterSettings.default
        settings.protectImportantMessages = false
        XCTAssertEqual(MessageClassifier.classify("Your campaign account verification code is 123456. Join our campaign.", settings: settings).decision, .junk)
    }
    func testKeywordsDoNotMatchInsideUnrelatedWords() {
        XCTAssertEqual(MessageClassifier.classify("Donate to the residential garden project").decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Our election meeting will select chairs").decision, .allow)
    }
    func testDisabledFallbackDoesNotFilter() {
        for text in ["Join our campaign", "Claim your prize now", "Flash sale 30% off"] {
            XCTAssertEqual(MessageClassifier.classify(text, settings: .disabled).decision, .allow)
        }
    }
    func testPoliticalLeftAndRightAreTreatedTheSame() {
        let samples = [
            "Democratic campaign: We need your vote. Vote for our candidate today!",
            "Republican campaign: We need your vote. Vote for our candidate today!",
            "Independent campaign: We need your vote. Vote for our candidate today!"
        ]
        for sample in samples {
            XCTAssertEqual(MessageClassifier.classify(sample).decision, .junk)
        }
    }
    func testPoliticalFundraising() {
        XCTAssertEqual(MessageClassifier.classify("Chip in $10 to help our Senate campaign").decision, .junk)
        XCTAssertEqual(MessageClassifier.classify("Donate to elect our candidate").decision, .junk)
    }
    func testPoliticalFundraisingCanBeDisabledIndependently() {
        var settings = FilterSettings.default
        settings.politicalFundraising = false
        XCTAssertEqual(MessageClassifier.classify("Chip in $10 to help our Senate campaign", settings: settings).decision, .allow)
    }
    func testCampaignSwitchCanBeDisabled() {
        var settings = FilterSettings.default
        settings.politicalMessages = false
        XCTAssertEqual(MessageClassifier.classify("Vote for our candidate tomorrow", settings: settings).decision, .allow)
    }
    func testScamsAndPromotions() {
        XCTAssertEqual(MessageClassifier.classify("Claim your prize now").decision, .junk)
        XCTAssertEqual(MessageClassifier.classify("Flash sale — take 30% off your order").decision, .promotion)
    }
    func testImportantTextsStayVisible() {
        XCTAssertEqual(MessageClassifier.classify("Your verification code is 123456").decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Appointment reminder: Tuesday at 2 PM").decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Your package is out for delivery").decision, .allow)
    }
    func testNormalMessagesAreNotFiltered() {
        XCTAssertEqual(MessageClassifier.classify("Dinner at six? Bring the pie.").decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("I am going to vote for this recipe.").decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Happy birthday!").decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Polls are open from 7 AM to 7 PM").decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Election day is tomorrow").decision, .allow)
    }
    func testAdvertisingAndScamsCanBeDisabled() {
        var settings = FilterSettings.default
        settings.advertising = false
        settings.scams = false
        XCTAssertEqual(MessageClassifier.classify("Flash sale — take 30% off your order", settings: settings).decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Claim your prize now", settings: settings).decision, .allow)
    }
    func testWhitespaceCaseAndAccentNormalization() {
        XCTAssertEqual(MessageClassifier.classify("VOTE  FOR    our candidate").decision, .junk)
    }
    func testNoOverBlockingOnIsolatedKeywords() {
        XCTAssertEqual(MessageClassifier.classify("The election results are on TV").decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("How did your party go?").decision, .allow)
        XCTAssertEqual(MessageClassifier.classify("Can you donate your old couch?").decision, .allow)
    }
}
