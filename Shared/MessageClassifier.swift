import Foundation

enum FilterDecision: String, Equatable {
    case allow
    case junk
    case promotion
}

struct FilterResult: Equatable {
    let decision: FilterDecision
    let category: String
    let explanation: String
}

enum MessageClassifier {
    static func classify(_ message: String, settings: FilterSettings = .default) -> FilterResult {
        let body = normalized(message)
        guard !body.isEmpty else { return allow() }

        // Party-neutral by design: no candidate or party receives different treatment.
        let clearCampaignLanguage = containsAny(body, [
            "re-elect", "reelect", "elect our candidate", "elect our senator",
            "elect our governor", "elect our president",
            "support our candidate", "support the candidate", "your vote matters",
            "we need your vote", "join our campaign",
            "campaign rally", "paid for by the campaign", "paid for by friends of",
            "stop the opposition", "vote yes on", "vote no on"
        ])
        let politicalContext = containsAny(body, [
            "campaign", "election", "candidate", "republican", "democrat",
            "congress", "senate", "senator", "governor", "president", "political",
            "pac ", "super pac", "ballot", "voters",
            "committee to elect", "party leadership"
        ])
        let campaign = clearCampaignLanguage ||
            (politicalContext && containsAny(body, ["vote for", "vote against", "elect "]))
        let donationAppeal = containsAny(body, [
            "donate", "donation", "contribute", "contribution", "chip in",
            "pitch in", "make a gift", "fund our", "fundraising",
            "double your impact", "triple your impact", "match your gift"
        ])
        let campaignFunding = donationAppeal && politicalContext
        let politicalCallToAction = politicalContext && containsAny(body, [
            "vote today", "vote tomorrow", "vote early", "cast your vote",
            "request your ballot", "sign our petition", "join the fight",
            "text stop to opt out", "text stop to end", "reply stop to end"
        ])

        if settings.politicalFundraising && campaignFunding {
            return FilterResult(decision: .junk, category: "Political fundraising",
                                explanation: "Political donation solicitation detected")
        }
        if settings.politicalMessages && (campaign || politicalCallToAction) {
            return FilterResult(decision: .junk, category: "Political campaign",
                                explanation: "Campaign or voting solicitation detected")
        }

        if settings.protectImportantMessages && containsAny(body, [
            "verification code", "security code", "your code is", "one-time code",
            "one time code", "one-time passcode", "two-factor authentication",
            "authentication code", "login code", "sign-in code", "otp is",
            "appointment reminder", "your appointment is", "prescription is ready",
            "out for delivery", "package delivered", "delivery confirmation",
            "flight confirmation", "boarding pass", "fraud alert"
        ]) {
            return FilterResult(decision: .allow, category: "Important message",
                                explanation: "Likely verification, delivery, or appointment text")
        }

        if settings.scams {
            let scamSignals = containsAny(body, [
                "claim your prize", "you have won a prize", "unclaimed winnings",
                "avoid arrest", "pay with gift cards", "send gift card codes",
                "guaranteed crypto returns", "double your bitcoin",
                "your package cannot be delivered pay", "unpaid toll fee pay now",
                "your account will be suspended click", "social security number to verify"
            ])
            if scamSignals {
                return FilterResult(decision: .junk, category: "Possible scam",
                                    explanation: "Known suspicious solicitation pattern")
            }
        }

        if settings.advertising {
            let salesCalls = containsAny(body, [
                "limited time offer", "flash sale", "exclusive deal", "buy now",
                "shop now", "promo code", "coupon code", "free shipping",
                "sale ends tonight", "special discount", "today only"
            ])
            let salesContext = containsAny(body, [
                "off your order", "% off", "discount", "offer", "sale", "shop",
                "buy", "redeem", "purchase", "code", "unsubscribe", "reply stop"
            ])
            if salesCalls && salesContext {
                return FilterResult(decision: .promotion, category: "Advertising",
                                    explanation: "Promotional marketing message")
            }
        }
        return allow()
    }

    private static func allow() -> FilterResult {
        FilterResult(decision: .allow, category: "Allowed",
                     explanation: "No sufficiently confident filter match")
    }

    private static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive],
                      locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func containsAny(_ body: String, _ signals: [String]) -> Bool {
        signals.contains(where: { body.contains($0) })
    }
}
