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
                By using Zoo Drop, you agree to the following terms:

                • You will not attempt to reverse-engineer, duplicate, or redistribute the app.
                • You agree to be bound by the rules of fair play — exploiting bugs or hacks may result in account restrictions.
                • We reserve the right to change these terms at any time. Continued use of Zoo Drop after changes implies acceptance.

                The Zoo Club subscription renews monthly and can be cancelled via your App Store settings.

                For legal questions or complaints, contact support@zoodrop.app.
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
