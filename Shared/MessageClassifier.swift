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

        if settings.scams {
            let scamSignals = containsUnwarnedScam(body, [
                "claim your prize", "you have won a prize", "unclaimed winnings",
                "avoid arrest", "pay with gift cards", "send gift card codes",
                "guaranteed crypto returns", "double your bitcoin",
                "your package cannot be delivered pay", "unpaid toll fee pay now",
                "your account will be suspended click", "social security number to verify"
            ])
            let prizeFee = containsAny(body, ["you won", "you have won", "winnings", "your prize"]) &&
                containsActionablePattern(body, #"\bpay (?:a |the )?(?:processing |release )?fee\b"#)
            let tollPayment = containsAny(body, ["toll", "tolls"]) &&
                containsAny(body, ["overdue", "unpaid", "outstanding"]) &&
                containsAny(body, ["https://", "http://"]) &&
                containsActionablePattern(body, #"\b(?:settle (?:your |the )?(?:overdue |outstanding )?balance|pay (?:now|your|the))\b"#)
            let credentials = containsActionablePattern(body,
                #"\b(?:reply|send|share)(?: with)? (?:your )?(?:password|pin)\b"#)
            let billingThreat = containsAny(body, ["payment was declined", "payment failed"]) &&
                containsAny(body, ["lose service", "service will be suspended"]) &&
                containsAny(body, ["https://", "http://"]) &&
                containsActionablePattern(body, #"\bupdate your card\b"#)
            if scamSignals || prizeFee || tollPayment || credentials || billingThreat {
                return FilterResult(decision: .junk, category: "Possible scam",
                                    explanation: "Known suspicious solicitation pattern")
            }
        }

        // Party-neutral by design: no candidate or party receives different treatment.
        let clearCampaignLanguage = containsUnwarnedScam(body, [
            "re-elect", "reelect", "elect our candidate", "elect our senator",
            "elect our governor", "elect our president",
            "support our candidate", "support the candidate",
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
        // Generic voting reminders and opt-out wording do not establish campaign intent.
        let campaignContext = containsAny(body, [
            "our campaign", "our candidate", "campaign rally", "political party",
            "republican", "democrat", "super pac", "committee to elect"
        ])
        let politicalCallToAction = campaignContext && containsAny(body, [
            "vote today", "vote tomorrow", "vote early", "cast your vote",
            "request your ballot", "sign our petition", "join the fight", "your vote matters"
        ])

        if settings.politicalFundraising && campaignFunding {
            return FilterResult(decision: .junk, category: "Political fundraising",
                                explanation: "Political donation solicitation detected")
        }
        if settings.politicalMessages && (campaign || politicalCallToAction) {
            return FilterResult(decision: .junk, category: "Political campaign",
                                explanation: "Campaign or voting solicitation detected")
        }

        let marketing = hasMarketing(body)
        let serviceNotice = containsAny(body, [
            "appointment reminder", "your appointment is", "prescription is ready",
            "out for delivery", "package delivered", "delivery confirmation",
            "flight confirmation", "boarding pass", "fraud alert"
        ])
        if settings.protectImportantMessages && !(settings.advertising && marketing && !serviceNotice) && containsAny(body, [
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

        if settings.advertising && marketing {
            return FilterResult(decision: .promotion, category: "Advertising",
                                explanation: "Promotional marketing message")
        }
        return allow()
    }


    // Suppress only a directly negated or explicitly quoted warning signal.
    // Every occurrence is checked, so a warning never permits the whole message.
    private static func containsUnwarnedScam(_ body: String, _ signals: [String]) -> Bool {
        signals.contains { signal in
            containsActionablePattern(body, "(?<![a-z0-9])" +
                NSRegularExpression.escapedPattern(for: signal) + "(?![a-z0-9])")
        }
    }

    private static func containsActionablePattern(_ body: String, _ pattern: String) -> Bool {
        let nsBody = body as NSString
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        for match in regex.matches(in: body, range: NSRange(location: 0, length: nsBody.length)) {
            let prefix = nsBody.substring(to: match.range.location)
            let warningPattern = #"(?:\bdo not|\bdon't|\bdon’t|\bnever(?: ask (?:you|anyone) to| request that you)?|\b(?:ignore|disregard) (?:texts|messages) (?:saying|that say))\s+(?:(?:ever|to)\s+)?["“']?$"#
            if prefix.range(of: warningPattern, options: .regularExpression) == nil {
                return true
            }
        }
        return false
    }

    private static func hasMarketing(_ body: String) -> Bool {
            let salesCalls = containsAny(body, [
                "limited time offer", "flash sale", "exclusive deal", "buy now",
                "shop now", "promo code", "coupon code", "free shipping",
                "sale ends tonight", "special discount", "today only"
            ])
            let salesContext = containsAny(body, [
                "off your order", "% off", "discount", "offer", "sale", "shop",
                "buy", "redeem", "purchase", "code", "unsubscribe", "reply stop"
            ])

        return salesCalls && salesContext
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
