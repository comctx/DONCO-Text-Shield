import SwiftUI

private enum ShieldTheme {
    static let navy = Color(red: 0.05, green: 0.11, blue: 0.20)
    static let teal = Color(red: 0.12, green: 0.66, blue: 0.56)
    static let card = Color(red: 0.10, green: 0.18, blue: 0.28)
    static let muted = Color(red: 0.68, green: 0.76, blue: 0.83)
}

struct ContentView: View {
    @State private var settings: FilterSettings
    @State private var settingsWarning: String?

    init() {
        let snapshot = SharedFilterSettings.snapshot()
        _settings = State(initialValue: snapshot.settings)
        _settingsWarning = State(initialValue: snapshot.warning)
    }
    @State private var sample = "Hi, our campaign needs your vote. Chip in $10 today to win this election."
    @State private var showingTest = false
    @State private var showingPrivacy = false
    @Environment(\.scenePhase) private var scenePhase

    private var groupReady: Bool { SharedFilterSettings.isAppGroupAvailable }
    private var previewResult: FilterResult { MessageClassifier.classify(sample, settings: settings) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    activationCard
                    limitationsCard
                    filterCard
                    if let warning = settingsWarning {
                        Label(warning, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                            .accessibilityLabel(warning)
                    }
                    privacyCard
                    testCard
                    footer
                }
                .padding(18)
            }
            .background(ShieldTheme.navy.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingTest, onDismiss: { sample = "" }) { testSheet }
            .sheet(isPresented: $showingPrivacy) { PrivacyHelpView() }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    let snapshot = SharedFilterSettings.snapshot()
                    settings = snapshot.settings
                    settingsWarning = snapshot.warning
                } else {
                    sample = ""
                }
            }
        }
        .tint(ShieldTheme.teal)
        .preferredColorScheme(.dark)
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(ShieldTheme.teal)
                .padding(.top, 12)
            Text("DONCO Text Shield™")
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Text("A DONCO-BAYCITY App")
                .font(.caption)
                .tracking(1.3)
                .foregroundStyle(ShieldTheme.muted)
            Text("Less noise. More peace of mind.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.86))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var activationCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label("Finish activation in iPhone Settings", systemImage: "checkmark.shield")
                .font(.headline)
                .foregroundStyle(.white)
            Text("The switches below configure your filter rules. Apple requires you to enable the Text Shield extension separately.")
                .foregroundStyle(ShieldTheme.muted)
                .font(.subheadline)
            Text("1. Open Messages and tap the Filters button.\n2. Tap Manage Filtering.\n3. Open Text Message Filter and enable DONCO Text Shield.")
                .foregroundStyle(.white)
                .font(.subheadline)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            Text("This app cannot confirm activation automatically.")
                .font(.caption)
                .foregroundStyle(ShieldTheme.muted)
            if !groupReady {
                Label("Shared settings unavailable. Text Shield will allow messages.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .cardBackground()
    }

    private var limitationsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Check your filtered messages", systemImage: "exclamationmark.triangle")
                .font(.headline)
            Text("Important texts can be filtered, and scams can get through. Review Junk or Spam, Promotions, and Unknown Senders, especially when expecting a code or appointment.")
                .font(.subheadline)
            Button("Privacy, limitations & help") { showingPrivacy = true }
            Button("Turn all filtering off") { saveChoices(.disabled) }
        }
        .foregroundStyle(.white)
        .cardBackground()
    }

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FILTER CATEGORIES")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(ShieldTheme.muted)
            filterToggle("Political campaign texts", detail: "All parties and candidates", icon: "checkmark.seal", enabled: settingBinding(\.politicalMessages))
            Divider().overlay(.white.opacity(0.12))
            filterToggle("Political fundraising", detail: "Campaign donations and PAC appeals", icon: "dollarsign.circle", enabled: settingBinding(\.politicalFundraising))
            Divider().overlay(.white.opacity(0.12))
            filterToggle("Scams & suspicious offers", detail: "Known suspicious wording; scams can still get through", icon: "exclamationmark.shield", enabled: settingBinding(\.scams))
            Divider().overlay(.white.opacity(0.12))
            filterToggle("Advertising", detail: "Move detected marketing to Promotions", icon: "tag", enabled: settingBinding(\.advertising))
            Divider().overlay(.white.opacity(0.12))
            filterToggle("Prefer likely important texts", detail: "Codes and reminders can still be filtered; check Junk", icon: "lock", enabled: settingBinding(\.protectImportantMessages))
        }
        .cardBackground()
    }

    private func filterToggle(_ name: String, detail: String, icon: String,
                              enabled: Binding<Bool>) -> some View {
        Toggle(isOn: enabled) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundStyle(ShieldTheme.teal)
                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text(detail).font(.caption).foregroundStyle(ShieldTheme.muted)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: ShieldTheme.teal))

    }

    private func settingBinding(_ keyPath: WritableKeyPath<FilterSettings, Bool>) -> Binding<Bool> {
        Binding(get: { settings[keyPath: keyPath] }, set: { value in
            var proposed = settings
            proposed[keyPath: keyPath] = value
            saveChoices(proposed)
        })
    }

    private func saveChoices(_ proposed: FilterSettings) {
        if SharedFilterSettings.save(proposed) {
            settings = proposed
            settingsWarning = nil
        } else {
            let snapshot = SharedFilterSettings.snapshot()
            settings = snapshot.settings
            settingsWarning = "Your change could not be verified. The switches show the choices currently readable by this app. Try again before relying on filtering."
        }
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "hand.raised.fill")
                .font(.title3)
                .foregroundStyle(ShieldTheme.teal)
            VStack(alignment: .leading, spacing: 5) {
                Text("Private by design").font(.headline).foregroundStyle(.white)
                Text("Filtering happens on your iPhone. No account, analytics, message uploads, or remote scanning.")
                    .font(.subheadline)
                    .foregroundStyle(ShieldTheme.muted)
            }
        }
        .cardBackground()
    }

    private var testCard: some View {
        Button { showingTest = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Try a sample message").font(.headline)
                    Text("Preview how the rules classify sample text")
                        .font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white)
            .padding(16)
            .background(ShieldTheme.teal.opacity(0.22), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(ShieldTheme.teal.opacity(0.55)))
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text("Detects some unsolicited SMS, MMS, and RCS texts from unknown senders.")
            Text("Cannot filter iMessages, saved contacts, or every unwanted text. Nothing is deleted.")
        }
        .font(.caption2)
        .multilineTextAlignment(.center)
        .foregroundStyle(ShieldTheme.muted)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private var testSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Sample message")
                    .font(.headline)
                TextEditor(text: $sample)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 125, maxHeight: 190)
                    .padding(10)
                    .background(ShieldTheme.card, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 7) {
                    Text("Result: \(previewResult.category)")
                        .font(.title3.bold())
                    Text(previewResult.explanation)
                    Text("Suggested category: \(destination(previewResult.decision))")
                        .foregroundStyle(ShieldTheme.teal)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(ShieldTheme.card, in: RoundedRectangle(cornerRadius: 14))
                Text("Sample test only. This does not read or change your Messages inbox.")
                    .font(.caption)
                    .foregroundStyle(ShieldTheme.muted)
                Spacer()
            }
            .padding(18)
            .background(ShieldTheme.navy.ignoresSafeArea())
            .navigationTitle("Test a message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingTest = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func destination(_ decision: FilterDecision) -> String {
        switch decision {
        case .allow: return "Allow (other Messages filters may still apply)"
        case .junk: return "Junk"
        case .promotion: return "Promotions"
        }
    }
}

private extension View {
    func cardBackground() -> some View {
        self.padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ShieldTheme.card, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08)))
    }
}
