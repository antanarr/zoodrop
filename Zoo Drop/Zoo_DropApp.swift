import SwiftUI

@main
struct Zoo_DropApp: App {
    @StateObject private var subscriptionManager: SubscriptionManager
    @StateObject private var zooDexManager: ZooDexManager
    @StateObject private var soundManager: SoundManager
    @StateObject private var adManager: AdManager
    @StateObject private var gameCenterManager: GameCenterManager
    @StateObject private var questManager: QuestManager

    @State private var launchStep: LaunchStep = .loading

    @AppStorage("hasConsentedToPrivacy") private var hasConsentedToPrivacy = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        let subscriptionManager = SubscriptionManager()
        let soundManager = SoundManager()

        _subscriptionManager = StateObject(wrappedValue: subscriptionManager)
        _zooDexManager = StateObject(wrappedValue: ZooDexManager())
        _soundManager = StateObject(wrappedValue: soundManager)
        _adManager = StateObject(wrappedValue: AdManager())
        _gameCenterManager = StateObject(wrappedValue: GameCenterManager())
        _questManager = StateObject(wrappedValue: QuestManager(
            soundManager: soundManager,
            subscriptionManager: subscriptionManager
        ))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch launchStep {
                case .loading:
                    LoadingView()
                        .transition(.opacity)
                        .task {
                            await finishLoading()
                        }

                case .privacyNotice:
                    PrivacyConsentView {
                        hasConsentedToPrivacy = true
                        withAnimation(.easeInOut(duration: 0.25)) {
                            launchStep = nextLaunchStep
                        }
                    }
                    .transition(.opacity)

                case .onboarding:
                    OnboardingView {
                        hasCompletedOnboarding = true
                        withAnimation(.easeInOut(duration: 0.25)) {
                            launchStep = .home
                        }
                    }
                    .transition(.opacity)

                case .home:
                    homeView
                        .transition(.opacity)
                }
            }
        }
    }

    private var homeView: some View {
        HomeView()
            .environmentObject(subscriptionManager)
            .environmentObject(zooDexManager)
            .environmentObject(soundManager)
            .environmentObject(adManager)
            .environmentObject(gameCenterManager)
            .environmentObject(questManager)
    }

    private var nextLaunchStep: LaunchStep {
        if !hasConsentedToPrivacy {
            return .privacyNotice
        }
        if !hasCompletedOnboarding {
            return .onboarding
        }
        return .home
    }

    @MainActor
    private func finishLoading() async {
        if ProcessInfo.processInfo.arguments.contains("UITEST_MODE") {
            UserDefaults.standard.removeObject(forKey: "savedRunSnapshot")
            hasConsentedToPrivacy = true
            hasCompletedOnboarding = true
            launchStep = .home
            return
        }

        try? await Task.sleep(nanoseconds: 450_000_000)
        withAnimation(.easeInOut(duration: 0.25)) {
            launchStep = nextLaunchStep
        }
    }
}

private enum LaunchStep {
    case loading
    case privacyNotice
    case onboarding
    case home
}

private struct PrivacyConsentView: View {
    let onContinue: () -> Void
    @State private var showingPrivacyPolicy = false

    var body: some View {
        ZStack {
            Image("nightscreen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Image("zoologoegg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 118, height: 118)

                Text("Privacy & Ads")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("Zoo Drop stores progress on this device and uses Apple Game Center, StoreKit, and Google AdMob. Ads are requested only after Google's privacy checks, and Zoo Club subscribers or Remove Ads owners do not receive ads.")
                    .font(.callout.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    Button("Continue", action: onContinue)
                        .buttonStyle(PrimaryConsentButton(color: .green))
                        .accessibilityIdentifier("privacyContinueButton")
                }

                Button("Privacy Policy") {
                    showingPrivacyPolicy = true
                }
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white)
                .accessibilityIdentifier("privacyPolicyButton")
            }
            .padding(24)
            .frame(maxWidth: 430)
            .background(.black.opacity(0.46), in: RoundedRectangle(cornerRadius: 24))
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationStack {
                PrivacyPolicyView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingPrivacyPolicy = false
                            }
                        }
                    }
                    .foregroundStyle(.white)
            }
        }
    }
}

private struct PrimaryConsentButton: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(configuration.isPressed ? 0.75 : 0.95), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
    }
}
