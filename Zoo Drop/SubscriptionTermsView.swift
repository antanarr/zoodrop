//
//  SubscriptionTermsView.swift
//  Zoo Drop
//
//  Created by Anthony Yarand on 7/6/25.
//


import SwiftUI

struct SubscriptionTermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Subscription Terms")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                    .accessibilityLabel("Subscription Terms")
                    .accessibilityHint("Information about the Zoo Club subscription")

                Text("""
                Zoo Club is a monthly subscription that removes all ads, grants access to exclusive animal skins, and gives you one golden egg reward per day.

                Payment will be charged to your Apple ID account at confirmation of purchase. The subscription automatically renews unless cancelled at least 24 hours before the end of the current period.

                You can manage or cancel your subscription in your App Store account settings.

                No refunds will be provided for unused portions of the term.

                For questions, email support@zoodrop.app.
                """)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel("Zoo Club Subscription Details")
                    .accessibilityHint("Describes subscription benefits, billing, renewal, cancellation, and support")
            }
            .padding()
        }
        .navigationTitle("Subscription Terms")
    }
}

#Preview {
    SubscriptionTermsView()
}
