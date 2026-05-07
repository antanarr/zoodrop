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
                Last updated: May 7, 2026

                Zoo Drop is an ad-supported iOS game. We do not require you to create an account, and we do not sell personal information.

                Game progress, settings, unlocks, and similar gameplay data are stored locally on your device. Deleting the app may delete local progress unless it is also stored by Apple services.

                If you sign in to Apple Game Center, Apple may process your Game Center profile, achievements, leaderboard scores, and related identifiers so game features can work.

                Purchases and subscriptions use Apple StoreKit. Apple processes payment, billing, refund, and transaction information. Zoo Drop receives purchase status needed to unlock paid features, grant consumable Golden Eggs, restore non-consumable purchases such as Remove Ads, and determine whether ads should be removed.

                Ads are provided through Google AdMob unless your active entitlements remove ads. Zoo Drop requests limited, non-personalized ads. Google and its partners may process consent signals, device information, approximate location, ad interactions, and diagnostics to deliver, measure, and limit ads.

                Where required, Google User Messaging Platform may show privacy options that let you manage advertising choices. You can also use iOS privacy settings such as App Tracking Transparency and Apple advertising settings.

                We use diagnostics only to maintain, secure, and improve the app. We keep information only as long as needed for the purposes described here or as required by law.

                For privacy questions, contact support@zoodrop.app.
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
