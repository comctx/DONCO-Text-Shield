# DONCO Text Shield™

An iPhone text-message filtering app. Designed to filter political campaign solicitations from **all parties equally**, political fundraising messages, scam patterns, and unwanted advertising from eligible unknown senders.

## What's in this project
- SwiftUI settings app with category switches and a test-message screen
- Apple's IdentityLookup Message Filter extension
- Shared, on-device classification rules and App Group settings
- Swift package unit tests and an unsigned iOS build-check workflow

## Important limits
Apple determines which unknown-sender SMS/MMS/RCS messages reach filtering extensions. The app cannot access all messages or guarantee blocking every text, does not delete messages, and does not block iMessages. Legitimate messages can be classified incorrectly, and scams can pass. Review filtered folders regularly; wording does not authenticate a sender. Text classification happens locally, without a web service.

## Build
Install XcodeGen on macOS, run `xcodegen generate`, and open `DONCOTextShield.xcodeproj`. Set up the Apple Developer Team, bundle IDs `com.donco.textshield` and `com.donco.textshield.MessageFilter`, and App Group `group.com.donco.textshield` for **both** targets. Build and install on an iPhone. Enable the extension in iPhone Settings under message filtering. Run `swift test` for the shared classifier. Codemagic includes separate unsigned compile-check and signed TestFlight workflows. The experimental GitHub branch also compiles the simulator app and extension without signing; that does not create an installable iPhone app.

A DONCO-BAYCITY App.

## Privacy and pre-release review
See [PRIVACY.md](PRIVACY.md) and the in-app Privacy & Help screen. Both targets include an App Group preferences privacy manifest. Settings default to no filtering when unreadable; missing settings do not silently enable all filters. Preferences read-back is not proof of durable storage or extension propagation. Sample text is cleared on dismissal/backgrounding.

Review remains incomplete: real-device behavior, interruption/persistence testing, final developer/privacy contact and public-policy URL, App Store privacy disclosures, licensing/branding and legal review. Automated synthetic tests do not establish real-world accuracy or release readiness.
