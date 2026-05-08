import SwiftUI

// --- RET-01: DAILY LOGIN CALENDAR VIEW ---
// This new view provides a 7-day login reward system to encourage daily engagement.
struct DailyLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    // AppStorage is used to persist the user's login streak and last claim date.
    @AppStorage("login_streak") private var loginStreak: Int = 0
    @AppStorage("last_claim_date") private var lastClaimDate: String = ""

    // The rewards for each consecutive day.
    private let rewards = [5, 5, 10, 10, 15, 15, 50]
    
    var body: some View {
        ZStack {
            PremiumTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Text("Daily Bonus")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(.white)
                        .shadow(radius: 3)

                    Text("Come back every day for bigger golden egg rewards.")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 12)], spacing: 12) {
                        ForEach(0..<7) { dayIndex in
                            dayView(day: dayIndex + 1, reward: rewards[dayIndex])
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: 430)
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 128)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 10) {
                claimArea

                Button("Close") {
                    dismiss()
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(.black.opacity(0.74))
        }
    }

    @ViewBuilder
    private var claimArea: some View {
        if canClaimToday() {
            Button(action: claimReward) {
                Label("Claim Today's Reward", systemImage: "gift.fill")
            }
            .buttonStyle(PremiumButtonStyle(tint: PremiumTheme.mint, prominence: .primary))
            .accessibilityIdentifier("claimDailyRewardButton")
        } else {
            Text("You've already claimed today's reward.")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(.white.opacity(0.82))
                .premiumGlass(cornerRadius: 18, tint: .white.opacity(0.1))
        }
    }
    
    /// Constructs the view for a single day in the calendar.
    private func dayView(day: Int, reward: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Text("Day \(day)")
                    .font(.caption.bold())
                
                Image("golden_egg_closed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                
                Text("+\(reward)")
                    .font(.headline)
            }
            .padding(10)
            .frame(width: 90, height: 110)
            .background(backgroundFor(day: day))
            .cornerRadius(15)
            .shadow(radius: 3)
            .foregroundColor(.white)
            .overlay(
                subscriptionManager.isSubscribed ?
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.yellow, lineWidth: 3)
                    : nil
            )

            if subscriptionManager.isSubscribed {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))
                    .padding(6)
            }
        }
    }
    
    /// Determines the background style for a day based on its status (claimed, current, future).
    private func backgroundFor(day: Int) -> some View {
        let isClaimed = day <= loginStreak
        let isCurrent = day == loginStreak + 1

        let material: AnyShapeStyle = {
            if isClaimed {
                return AnyShapeStyle(.green.opacity(0.6))
            } else if isCurrent && canClaimToday() {
                return AnyShapeStyle(.orange.opacity(0.8))
            } else {
                return AnyShapeStyle(.black.opacity(0.2))
            }
        }()

        return RoundedRectangle(cornerRadius: 15)
            .fill(material)
    }
    
    /// Checks if the user can claim a reward today.
    private func canClaimToday() -> Bool {
        let todayString = Date().formatted(date: .abbreviated, time: .omitted)
        return lastClaimDate != todayString
    }
    
    /// Handles the logic for claiming a reward.
    private func claimReward() {
        guard canClaimToday() else { return }
        
        let todayString = Date().formatted(date: .abbreviated, time: .omitted)
        let yesterdayString = Calendar.current.date(byAdding: .day, value: -1, to: Date())!.formatted(date: .abbreviated, time: .omitted)

        // If the last claim was not yesterday, the streak resets.
        if lastClaimDate != yesterdayString {
            loginStreak = 0
        }
        
        // Advance the streak, but cap it at 6 (for the 7th day).
        loginStreak = min(loginStreak + 1, 7)
        
        // Grant the reward. The streak is 1-based, array is 0-based.
        let rewardAmount = rewards[loginStreak - 1]
        subscriptionManager.goldenEggCount += rewardAmount
        
        // Save the claim date.
        lastClaimDate = todayString
        
        // Provide haptic feedback.
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
