//
//  OnboardingView.swift
//  Zoo Drop
//
//  Created by Anthony Yarand on 7/5/25.
//


import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var appear = false

    var body: some View {
        ZStack {
            AmbientSafariBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 18) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 188)
                            .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
                            .accessibilityLabel("Welcome to Zoo Drop")
                            .accessibilityHint("Introduction screen for the Zoo Drop game")

                        VStack(spacing: 8) {
                            Text("Merge Animals. Reach Elephant.")
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.72)

                            Text("Drop animals into the habitat. Matching pairs evolve into bigger animals. Keep the stack below the red danger line.")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.88))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityLabel("Drop animals into the habitat. Matching pairs evolve into bigger animals. Keep the stack below the red danger line.")
                        .accessibilityHint("Goal summary for Zoo Drop")

                        VStack(alignment: .leading, spacing: 12) {
                            onboardingStep(icon: "hand.draw.fill", title: "Aim", detail: "Drag left or right to place the next animal.")
                            onboardingStep(icon: "arrow.down.circle.fill", title: "Drop", detail: "Release to drop. Tap the Next panel for an accessible drop.")
                            onboardingStep(icon: "equals.circle.fill", title: "Merge", detail: "Two of the same animal become the next animal in the ZooDex.")
                        }
                        .padding(16)
                        .frame(maxWidth: 430, alignment: .leading)
                        .premiumGlass(cornerRadius: 24, tint: PremiumTheme.lagoon.opacity(0.08))

                        Text("The run ends when the pile settles above the red danger line.")
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(PremiumTheme.gold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 430)
                    .padding(.horizontal, 22)
                    .padding(.top, 74)
                    .padding(.bottom, 22)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)

                Button(action: {
                    onFinish()
                }) {
                    Text("Let's Go!")
                        .font(.title2.bold())
                        .padding()
                        .frame(maxWidth: 386)
                        .background(PremiumTheme.heroGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .foregroundColor(PremiumTheme.ink)
                }
                .frame(maxWidth: 386)
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(.black.opacity(0.36))
                .accessibilityLabel("Let's Go")
                .accessibilityHint("Begin playing Zoo Drop")
                .accessibilityIdentifier("onboardingStartButton")
            }
            .opacity(appear ? 1 : 0)
            .animation(.easeIn(duration: 0.5), value: appear)
            .onAppear {
                appear = true
            }
        }
    }

    private func onboardingStep(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
                .foregroundStyle(PremiumTheme.gold)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView {
            // Preview handler
        }
    }
}
