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
    @State private var wiggle = false

    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Welcome to Zoo Drop!")
                    .font(.largeTitle.bold())
                    .accessibilityLabel("Welcome to Zoo Drop")
                    .accessibilityHint("Introduction screen for the Zoo Drop game")

                Text("Stack animals, unlock chaos, and build the wobbliest zoo tower ever.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityLabel("Stack animals, unlock chaos, and build the wobbliest zoo tower ever")
                    .accessibilityHint("Instructions and goal summary for Zoo Drop")

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .scaleEffect(appear ? 1.0 : 0.7)
                    .rotationEffect(.degrees(wiggle ? 2 : -2))
                    .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: wiggle)
                    .accessibilityLabel("Zoo Drop Logo")
                    .accessibilityHint("Animated Zoo Drop logo")

                Spacer()

                Button(action: {
                    onFinish()
                }) {
                    Text("Let's Go!")
                        .font(.title2.bold())
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .accessibilityLabel("Let's Go")
                .accessibilityHint("Begin playing Zoo Drop")
            }
            .padding()
            .opacity(appear ? 1 : 0)
            .animation(.easeIn(duration: 0.5), value: appear)
            .onAppear {
                appear = true
                wiggle = true
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
