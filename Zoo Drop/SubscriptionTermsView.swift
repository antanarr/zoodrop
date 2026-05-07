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
                Last updated: May 6, 2026

                Zoo Club is an optional auto-renewable subscription. Benefits shown in the purchase screen may include removing ads and unlocking subscriber-only game rewards or cosmetic content while your subscription is active.

                The subscription period and price are shown before purchase. Payment is charged to your Apple Account when you confirm the purchase.

                The subscription automatically renews unless you cancel at least 24 hours before the end of the current period. Your account may be charged for renewal within 24 hours before the current period ends.

                You can manage or cancel your subscription in App Store account settings. Cancellation stops future renewals but does not immediately end the current paid period.

                If a free trial or introductory offer is available, unused time may be forfeited when you purchase a subscription, where permitted by Apple's rules.

                Refund requests are handled by Apple. Zoo Drop cannot issue App Store refunds directly.

                If the app offers restore purchases, use it after reinstalling the app or changing devices to restore eligible active entitlements.

                For subscription questions, contact support@zoodrop.app.
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
