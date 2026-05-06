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
                Zoo Drop is a trademark of Zoo Drop LLC. All content, including animal designs, logos, and gameplay mechanics, is protected under U.S. and international copyright laws.

                Unauthorized reproduction, distribution, or modification of this app or its assets is strictly prohibited.

                This app uses third-party services including but not limited to Apple Game Center, Google AdMob, and StoreKit. Their respective terms and conditions apply.

                © 2025 Zoo Drop LLC. All rights reserved.
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
