# DONCO Text Shield™

An iPhone text-message filtering app. Designed to filter political campaign solicitations from **all parties equally**, political fundraising messages, scam patterns, and unwanted advertising from eligible unknown senders.

## What's in this project
- SwiftUI settings app with category switches and a test-message screen
- Apple's IdentityLookup Message Filter extension
- Shared, on-device classification rules and App Group settings
- Swift package unit tests and an unsigned iOS build-check workflow

## Important limits
Apple determines which unknown-sender SMS/MMS/RCS messages reach filtering extensions. The app cannot access all messages or guarantee blocking every text, does not delete messages, and does not block iMessages. Legitimate messages could occasionally be classified incorrectly. Text classification happens locally, without a web service.

## Build
Install XcodeGen on macOS, run `xcodegen generate`, and open `DONCOTextShield.xcodeproj`. Set up the Apple Developer Team, bundle IDs `com.donco.textshield` and `com.donco.textshield.MessageFilter`, and App Group `group.com.donco.textshield` for **both** targets. Build and install on an iPhone. Enable the extension in iPhone Settings under message filtering. Run `swift test` for the shared classifier. The included Codemagic workflow performs an **unsigned simulator compile check**, not a distributable TestFlight build.

A DONCO-BAYCITY App.
