import SwiftUI

@main
struct Zoo_DropApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var zooDexManager = ZooDexManager()
    @StateObject private var soundManager = SoundManager()
    @StateObject private var adManager = AdManager()
    @StateObject private var gameCenterManager = GameCenterManager()
    @StateObject private var questManager = QuestManager(soundManager: SoundManager())
    
    @State private var showLoading = true
    
    @AppStorage("hasConsentedToPrivacy") private var hasConsentedToPrivacy = false
    @State private var showingConsent = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLoading {
                    LoadingView()
                        .transition(.opacity)
                        .onAppear {
                            // --- THIS IS THE FIX ---
                            // We now explicitly call our managers to start their work here.
                            adManager.initializeAndLoadAds() // This now runs in the background.
                            
                            Task {
                                // Await any async setup functions here if you have them.
                                // For now, just simulate immediate completion since initializeAndLoadAds is sync.
                                try? await Task.sleep(nanoseconds: 1_000_000_000) // Optional short delay to avoid flicker, can remove
                                withAnimation {
                                    showLoading = false
                                    if !hasConsentedToPrivacy {
                                        showingConsent = true
                                    }
                                }
                            }
                        }
                } else {
                    HomeView()
                        .environmentObject(subscriptionManager)
                        .environmentObject(zooDexManager)
                        .environmentObject(soundManager)
                        .environmentObject(adManager)
                        .environmentObject(gameCenterManager)
                        .environmentObject(questManager)
                        .transition(.opacity)
                        .disabled(showingConsent)
                        .blur(radius: showingConsent ? 3 : 0)
                        .fullScreenCover(isPresented: $showingConsent) {
                            // This would be your GDPR consent view.
                            // We'll use a simple placeholder.
                            VStack {
                                Text("Privacy Policy Consent")
                                    .font(.title)
                                Button("Accept") {
                                    hasConsentedToPrivacy = true
                                    showingConsent = false
                                }
                            }
                        }
                        .fullScreenCover(
                            isPresented: Binding(
                                get: { !hasCompletedOnboarding },
                                set: { if !$0 { hasCompletedOnboarding = true } }
                            )
                        ) {
                            OnboardingView(onFinish: {
                                hasCompletedOnboarding = true
                            })
                        }
                }
            }
        }
    }
}
