//
//  PrivacyPolicyView.swift
//  Zoo Drop
//
//  Created by Anthony Yarand on 7/6/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                    .accessibilityLabel("Privacy Policy")
                    .accessibilityHint("Explanation of how Zoo Drop handles your data and privacy")

                Text("""
                Zoo Drop does not collect any personal data without your consent. We use third-party services such as AdMob and Game Center, which may collect anonymized data in accordance with their own privacy policies.

                We display ads through Google AdMob. If you choose to subscribe to Zoo Club, ads are removed. We do not sell your data, but some services may track interactions to improve ad relevance.

                By using Zoo Drop, you agree to the use of these services. If you do not agree, you may uninstall the app.

                For questions or concerns, contact us at support@zoodrop.app.
                """)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel("Zoo Drop Privacy Policy Text")
                    .accessibilityHint("Details about data collection, ad usage, and third-party services")
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

#Preview {
    PrivacyPolicyView()
}
