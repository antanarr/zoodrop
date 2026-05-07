import SwiftUI

struct TermsOfUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Use")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                    .accessibilityLabel("Terms of Use")
                    .accessibilityHint("Legal agreement for using the Zoo Drop app")

                Text("""
                Last updated: May 7, 2026

                By downloading or using Zoo Drop, you agree to these terms and to Apple's standard licensed application terms: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

                Zoo Drop is provided for personal, non-commercial entertainment use. You may not copy, modify, reverse engineer, redistribute, sell, or misuse the app or its content except as allowed by law.

                Play fairly. Do not exploit bugs, automate play, tamper with scores, interfere with Game Center, or use the app in a way that harms other players, the service, or the app.

                Zoo Drop may include ads, Game Center features, consumable Golden Egg purchases, a non-consumable Remove Ads purchase, and monthly or yearly auto-renewable Zoo Club subscriptions. Purchases are handled by Apple and are subject to Apple's App Store rules.

                Paid items, rewards, subscriptions, and game features may change as the app evolves. We will not intentionally remove paid access without a reasonable replacement where required by law.

                The app is provided "as is" and may be unavailable, interrupted, or updated. To the maximum extent allowed by law, Your Skin Matters LLC is not liable for indirect, incidental, special, or consequential damages from use of the app.

                We may update these terms. Continued use after an update means you accept the updated terms.

                For legal questions, contact support@zoodrop.app.
                """)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel("Zoo Drop Terms and Conditions")
                    .accessibilityHint("Details the rules, usage guidelines, and subscription terms")
            }
            .padding()
        }
        .navigationTitle("Terms of Use")
    }
}

#Preview {
    TermsOfUseView()
}
