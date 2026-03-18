import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentStep = 0

    private let totalSteps = 3

    var body: some View {
        ZStack {
            CSColor.surfacePrimary.ignoresSafeArea()

            TabView(selection: $currentStep) {
                OnboardingStepScan(onNext: nextStep, onSkip: skipToPaywall)
                    .tag(0)
                OnboardingStepValue(onNext: nextStep, onSkip: skipToPaywall)
                    .tag(1)
                PaywallView(
                    source: .onboarding,
                    variant: appState.subscription.paywallVariant,
                    onComplete: completeOnboarding
                )
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.4), value: currentStep)
        }
        .preferredColorScheme(.dark)
    }

    private func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation { currentStep += 1 }
        }
    }

    private func skipToPaywall() {
        withAnimation { currentStep = 2 }
    }

    private func completeOnboarding() {
        appState.completeOnboarding()
    }
}

// MARK: - Step 1: Scan
struct OnboardingStepScan: View {
    let onNext: () -> Void
    let onSkip: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            TimelineView(.animation(minimumInterval: 0.02)) { context in
                let floatOffset = sin(context.date.timeIntervalSinceReferenceDate * .pi / 2) * 4
                Image("Onboarding1")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 280)
                    .offset(y: floatOffset)
            }
            .scaleEffect(appeared ? 1 : 0.92)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: appeared)
            .onAppear { withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { appeared = true } }
            .onDisappear { appeared = false }

            Spacer().frame(height: CSSpacing.lg)

            Text("Scan \(Text("Any Card").foregroundStyle(CSColor.signalPrimary))\nInstantly")
                .font(.system(size: 28, weight: .bold))

            Text("Point your camera at any sports card.\nOur AI identifies it in under 2 seconds.")
                .font(CSFont.body())
                .foregroundStyle(CSColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, CSSpacing.sm)

            Spacer()

            VStack(spacing: CSSpacing.sm) {
                dotsIndicator(current: 0, total: 2)
                    .padding(.bottom, CSSpacing.lg)

                Button("Continue", action: onNext)
                    .buttonStyle(PrimaryButtonStyle())

                Button("Skip", action: onSkip)
                    .font(CSFont.body())
                    .foregroundStyle(CSColor.textTertiary)
            }
            .padding(.horizontal, CSSpacing.lg)
            .padding(.bottom, 20)
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Step 2: Value
struct OnboardingStepValue: View {
    let onNext: () -> Void
    let onSkip: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            TimelineView(.animation(minimumInterval: 0.02)) { context in
                let floatOffset = sin(context.date.timeIntervalSinceReferenceDate * .pi / 2) * 4
                Image("Onboarding2")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 280)
                    .offset(y: floatOffset)
            }
            .scaleEffect(appeared ? 1 : 0.92)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: appeared)
            .onAppear { withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { appeared = true } }
            .onDisappear { appeared = false }

            Spacer().frame(height: CSSpacing.lg)

            Text("Know the \(Text("Exact Value").foregroundStyle(CSColor.signalPrimary))")
                .font(.system(size: 28, weight: .bold))

            Text("Real-time market prices based on\nrecent eBay sold comps. By grade.")
                .font(CSFont.body())
                .foregroundStyle(CSColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, CSSpacing.sm)

            Spacer()

            VStack(spacing: CSSpacing.sm) {
                dotsIndicator(current: 1, total: 2)
                    .padding(.bottom, CSSpacing.lg)

                Button("Get Started", action: onNext)
                    .buttonStyle(PrimaryButtonStyle())

                Button("Skip", action: onSkip)
                    .font(CSFont.body())
                    .foregroundStyle(CSColor.textTertiary)
            }
            .padding(.horizontal, CSSpacing.lg)
            .padding(.bottom, 20)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview("OnboardingView") {
    PreviewContainer {
        OnboardingView()
    }
}

#Preview("OnboardingStepScan") {
    OnboardingStepScan(onNext: {}, onSkip: {})
        .preferredColorScheme(.dark)
}

#Preview("OnboardingStepValue") {
    OnboardingStepValue(onNext: {}, onSkip: {})
        .preferredColorScheme(.dark)
}

// MARK: - Shared
func dotsIndicator(current: Int, total: Int) -> some View {
    HStack(spacing: 8) {
        ForEach(0..<total, id: \.self) { i in
            if i == current {
                RoundedRectangle(cornerRadius: 3)
                    .fill(CSColor.signalPrimary)
                    .frame(width: 24, height: 6)
            } else {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
