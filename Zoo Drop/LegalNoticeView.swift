import SwiftUI

struct LegalNoticeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Legal Notice")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                    .accessibilityLabel("Legal Notice")
                    .accessibilityHint("Legal and copyright information about Zoo Drop")

                Text("""
                Last updated: May 7, 2026

                Zoo Drop, its name, artwork, characters, game content, user interface, sounds, and other original materials are owned by Your Skin Matters LLC or its licensors and are protected by applicable copyright, trademark, and other laws.

                You may use the app only as permitted by the Terms of Use and Apple's App Store terms. Unauthorized copying, modification, distribution, public display, or commercial use of the app or its assets is prohibited.

                Apple, App Store, Game Center, and StoreKit are trademarks or service marks of Apple Inc. Google AdMob is a trademark or service mark of Google LLC. All third-party names and marks belong to their respective owners.

                Third-party services may be used to provide ads, consent, purchases, leaderboards, achievements, diagnostics, and platform features. Their own terms and privacy practices apply to those services.

                Nothing in these notices grants rights to any Zoo Drop or third-party intellectual property except the limited right to use the app as installed from the App Store.

                (c) 2026 Your Skin Matters LLC. All rights reserved.
                """)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel("Zoo Drop Legal Text")
                    .accessibilityHint("Includes copyright, trademark, and third-party usage information")
            }
            .padding()
        }
        .navigationTitle("Legal Notice")
    }
}

#Preview {
    LegalNoticeView()
}
