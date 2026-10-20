# Rules-first experiment

This branch changes three areas only: scam checks precede important-message phrases; immediate "do not", "don't", "don’t", and "never" warnings suppress only the following scam phrase; generic voting reminders and opt-out instructions no longer establish campaign intent. Campaign solicitation rules remain party-neutral.

Run `swift test` (also run by the existing GitHub Actions workflow). The frozen classifier in Tests/BaselineMessageClassifier.swift is from c9b73f5 and is excluded from the app. RuleComparisonTests prints both classifiers' decisions for 20 synthetic development examples (10 legitimate, 10 unwanted), and separately counts legitimate texts filtered and unwanted messages allowed. Other regression tests cover mixed warning/request messages and settings switches.

These examples guided development. They are NOT a held-out evaluation, real-world accuracy measurement, proof of sender identity, or evidence that a trained model would improve results. Next: author a separate unseen evaluation set, compare both rule versions before tuning again, and test the extension on an installed iPhone. No AI, telemetry, message uploads, or message collection is added.

Limitations: narrow English phrase rules still miss paraphrases, other languages and sophisticated scams, and can misread quoted, educational or unusual messages. A negated request can itself be deceptive. Wording alone cannot authenticate an election office or bank. Settings persistence, privacy policy, user-facing claims and other liability-audit items remain separate unfinished work. This experiment does not clear the app for release.


## Subsequent review

Settings now default to no filtering when missing/corrupt/unavailable; the UI reports failed preference read-back. Read-back is not a guarantee of durable writes or extension synchronization. Four storage tests cover missing/corrupt settings, unavailable storage, and preserving choices.

The first fresh 30-message set found 3 legitimate texts filtered and 4 unwanted messages allowed. These seven errors were then addressed and asserted in regression tests. The next fresh 20-message set found 1 legitimate warning filtered and 1 phishing message allowed; those two are now also development regressions. All sets are synthetic and authored by the same assistant; neither remains a held-out set after tuning. Do not describe success on them as real-world accuracy.

Rule changes extend scoped warning/quotation recognition, add combined prize/fee, toll/payment/link, password/PIN request, and declined-payment/card-update/threat patterns. Marketing mixed with security-code wording is categorized as promotion; likely service notices retain their existing preference. These heuristics can mistake legitimate messages and miss scams. Sender identity is never authenticated by wording.

An unsigned simulator compilation workflow checks the SwiftUI app and message extension without accepting agreements, creating signing assets, uploading to Apple or publishing. Device behavior, persistence across process termination, privacy policy/support and remaining liability findings still require review.
