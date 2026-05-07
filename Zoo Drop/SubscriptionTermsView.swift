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
                Last updated: May 7, 2026

                Zoo Club is an optional auto-renewable subscription available in monthly and yearly plans. Benefits shown in the purchase screen may include removing ads while subscribed, daily Golden Eggs, subscriber-only animals, and other subscriber-only rewards or cosmetic content while your subscription is active.

                The subscription period and price are shown before purchase. Payment is charged to your Apple Account when you confirm the purchase.

                The subscription automatically renews unless you cancel at least 24 hours before the end of the current period. Your account may be charged for renewal within 24 hours before the current period ends.

                You can manage or cancel your subscription in App Store account settings. Cancellation stops future renewals but does not immediately end the current paid period.

                If a free trial or introductory offer is available, unused time may be forfeited when you purchase a subscription, where permitted by Apple's rules.

                Refund requests are handled by Apple. Zoo Drop cannot issue App Store refunds directly.

                Remove Ads is a separate non-consumable in-app purchase. It is not a subscription and can be restored with Restore Purchases. Golden Egg packs and Starter Pack are consumable purchases. Consumables are granted after Apple verifies the transaction and are not restored as reusable entitlements.

                Use Restore Purchases after reinstalling the app or changing devices to restore eligible active subscriptions and non-consumable purchases.

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
