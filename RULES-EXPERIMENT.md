# Rules-first experiment

This branch changes three areas only: scam checks precede important-message phrases; immediate "do not", "don't", "don’t", and "never" warnings suppress only the following scam phrase; generic voting reminders and opt-out instructions no longer establish campaign intent. Campaign solicitation rules remain party-neutral.

Run `swift test` (also run by the existing GitHub Actions workflow). The frozen classifier in Tests/BaselineMessageClassifier.swift is from c9b73f5 and is excluded from the app. RuleComparisonTests prints both classifiers' decisions for 20 synthetic development examples (10 legitimate, 10 unwanted), and separately counts legitimate texts filtered and unwanted messages allowed. Other regression tests cover mixed warning/request messages and settings switches.

These examples guided development. They are NOT a held-out evaluation, real-world accuracy measurement, proof of sender identity, or evidence that a trained model would improve results. Next: author a separate unseen evaluation set, compare both rule versions before tuning again, and test the extension on an installed iPhone. No AI, telemetry, message uploads, or message collection is added.

Limitations: narrow English phrase rules still miss paraphrases, other languages and sophisticated scams, and can misread quoted, educational or unusual messages. A negated request can itself be deceptive. Wording alone cannot authenticate an election office or bank. Settings persistence, privacy policy, user-facing claims and other liability-audit items remain separate unfinished work. This experiment does not clear the app for release.
