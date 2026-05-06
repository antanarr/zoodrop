import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    // Using AppStorage to persist user settings is a modern and efficient approach.
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        // Form provides a standard, platform-consistent settings layout.
        Form {
            Section(header: Text("Audio")) {
                Toggle("Sound Effects", isOn: $soundEnabled)
            }
            
            Section(header: Text("Subscription")) {
                if subscriptionManager.isSubscribed {
                    // Provides clear, positive feedback to the user.
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("You are a Zoo Club member!")
                    }
                    .foregroundColor(.green)
                } else {
                    // The NavigationLink correctly points to the standalone ZooClubView.
                    NavigationLink("Join Zoo Club", destination: ZooClubView())
                }
                
                Button("Restore Purchases") {
                    Task {
                        // Using a Task for modern Swift concurrency.
                        await subscriptionManager.restore()
                    }
                }
            }
            
            Section(header: Text("Legal")) {
                // Each NavigationLink now correctly points to its own standalone View file.
                // This removes the duplicate struct definition that was causing the compiler issue.
                NavigationLink("Privacy Policy", destination: PrivacyPolicyView())
                NavigationLink("Terms of Use", destination: TermsOfUseView())
                NavigationLink("Subscription Terms", destination: SubscriptionTermsView())
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    // Setting up a preview with necessary environment objects for accurate representation.
    NavigationView {
        SettingsView()
            .environmentObject(SubscriptionManager())
    }
}
