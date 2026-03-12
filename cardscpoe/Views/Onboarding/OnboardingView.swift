import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentStep = 0

    private let totalSteps = 5

    var body: some View {
        ZStack {
            CSColor.surfacePrimary.ignoresSafeArea()

            TabView(selection: $currentStep) {
                OnboardingStepScan(onNext: nextStep, onSkip: skipToPaywall)
                    .tag(0)
                OnboardingStepValue(onNext: nextStep, onSkip: skipToPaywall)
                    .tag(1)
                OnboardingStepGrade(onNext: nextStep, onSkip: skipToPaywall)
                    .tag(2)
                OnboardingStepPortfolio(onNext: nextStep, onSkip: skipToPaywall)
                    .tag(3)
                OnboardingPaywallStep(onComplete: completeOnboarding)
                    .tag(4)
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
        withAnimation { currentStep = 4 }
    }

    private func completeOnboarding() {
        appState.completeOnboarding()
    }
}

// MARK: - Step 1: Scan
struct OnboardingStepScan: View {
    let onNext: () -> Void
    let onSkip: () -> Void
    @State private var cardOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [CSColor.signalPrimary.opacity(0.06), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)

                ZStack {
                    RoundedRectangle(cornerRadius: CSRadius.md)
                        .fill(CSColor.surfaceElevated)
                        .frame(width: 170, height: 238)
                        .overlay(
                            RoundedRectangle(cornerRadius: CSRadius.md)
                                .stroke(CSColor.border, lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 20, y: 16)

                    Image(systemName: "figure.basketball")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white.opacity(0.7), Color.blue.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    ScanBeamView()
                        .frame(width: 150, height: 210)

                    ViewfinderFrame(color: CSColor.signalPrimary)
                        .frame(width: 170, height: 238)
                        .padding(-6)
                }
                .offset(y: cardOffset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        cardOffset = -8
                    }
                }
            }

            Spacer().frame(height: CSSpacing.lg)

            Text("Scan ")
                .font(.system(size: 28, weight: .bold)) +
            Text("Any Card")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(CSColor.signalPrimary) +
            Text("\nInstantly")
                .font(.system(size: 28, weight: .bold))

            Text("Point your camera at any sports card.\nOur AI identifies it in under 2 seconds.")
                .font(CSFont.body())
                .foregroundStyle(CSColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, CSSpacing.sm)

            Spacer()

            VStack(spacing: CSSpacing.sm) {
                dotsIndicator(current: 0, total: 4)
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

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [CSColor.signalGold.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)

                VStack(spacing: CSSpacing.md) {
                    VStack(spacing: CSSpacing.sm) {
                        Image(systemName: "figure.baseball")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Color.red.opacity(0.6))

                        Text("Shohei Ohtani")
                            .font(CSFont.body(.bold))
                        Text("2018 Topps Chrome #150 RC")
                            .font(.system(size: 11))
                            .foregroundStyle(CSColor.textTertiary)

                        Text("$1,280")
                            .font(CSFont.mono(32, weight: .heavy))
                            .foregroundStyle(CSColor.signalGold)

                        Text("CURRENT MARKET VALUE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CSColor.textTertiary)
                            .tracking(1)

                        HStack(spacing: CSSpacing.xs) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                            Text("24.5% this month")
                                .font(CSFont.caption(.bold))
                        }
                        .foregroundStyle(CSColor.signalPrimary)
                        .padding(.horizontal, CSSpacing.sm)
                        .padding(.vertical, CSSpacing.xs)
                        .background(CSColor.signalPrimary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .nyxCard(padding: CSSpacing.lg)

                    HStack(spacing: CSSpacing.sm) {
                        priceTier(grade: "Raw", price: "$320", color: CSColor.textPrimary)
                        priceTier(grade: "PSA 9", price: "$680", color: CSColor.signalTertiary)
                        priceTier(grade: "PSA 10", price: "$1,280", color: CSColor.signalGold)
                    }
                }
            }

            Spacer().frame(height: CSSpacing.lg)

            Text("Know the ")
                .font(.system(size: 28, weight: .bold)) +
            Text("Exact Value")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(CSColor.signalGold)

            Text("Real-time market prices based on\nrecent eBay sold comps. By grade.")
                .font(CSFont.body())
                .foregroundStyle(CSColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, CSSpacing.sm)

            Spacer()

            VStack(spacing: CSSpacing.sm) {
                dotsIndicator(current: 1, total: 4)
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

    private func priceTier(grade: String, price: String, color: Color) -> some View {
        VStack(spacing: CSSpacing.xs) {
            Text(grade)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CSColor.textTertiary)
            Text(price)
                .font(CSFont.data(.heavy))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(CSColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.sm)
                .stroke(CSColor.borderSubtle, lineWidth: 0.5)
        )
    }
}

// MARK: - Step 3: Grade
struct OnboardingStepGrade: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [CSColor.signalTertiary.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)

                VStack(spacing: CSSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CSRadius.md)
                            .fill(CSColor.surfaceElevated)
                            .frame(width: 160, height: 224)
                            .overlay(
                                RoundedRectangle(cornerRadius: CSRadius.md)
                                    .stroke(CSColor.border, lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 16, y: 10)

                        Image(systemName: "figure.american.football")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(Color.green.opacity(0.5))

                        LinearGradient(
                            colors: [.clear, CSColor.signalPrimary.opacity(0.04)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                        .frame(width: 160, height: 224)

                        cornerMarkers
                    }

                    HStack(spacing: CSSpacing.sm) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Grade")
                                .font(CSFont.caption(.semibold))
                                .foregroundStyle(CSColor.textSecondary)
                            Text("9.5")
                                .font(CSFont.mono(22, weight: .heavy))
                                .foregroundStyle(CSColor.signalGold)
                        }

                        Divider()
                            .frame(height: 32)
                            .background(CSColor.border)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Condition")
                                .font(CSFont.caption(.semibold))
                                .foregroundStyle(CSColor.textSecondary)
                            Text("Gem Mint")
                                .font(CSFont.body(.bold))
                                .foregroundStyle(CSColor.signalPrimary)
                        }
                    }
                    .nyxCard(padding: CSSpacing.sm)

                    gradeBarsMini
                }
            }

            Spacer().frame(height: CSSpacing.lg)

            Text("AI-Powered ")
                .font(.system(size: 28, weight: .bold)) +
            Text("Grading")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(CSColor.signalTertiary)

            Text("Know if your card is worth grading\nbefore spending $50+ at PSA.")
                .font(CSFont.body())
                .foregroundStyle(CSColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, CSSpacing.sm)

            Spacer()

            VStack(spacing: CSSpacing.sm) {
                dotsIndicator(current: 2, total: 4)
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

    private var cornerMarkers: some View {
        ZStack {
            markerCorner(x: 80 - 68, y: 112 - 100)
            markerCorner(x: 80 + 68, y: 112 - 100)
            markerCorner(x: 80 - 68, y: 112 + 100)
            markerCorner(x: 80 + 68, y: 112 + 100)
        }
        .frame(width: 160, height: 224)
    }

    private func markerCorner(x: CGFloat, y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .stroke(CSColor.signalPrimary, lineWidth: 2)
            .frame(width: 16, height: 16)
            .position(x: x, y: y)
    }

    private var gradeBarsMini: some View {
        VStack(spacing: CSSpacing.sm) {
            gradeBar(label: "Centering", value: 0.95, score: "9.5", color: CSColor.signalPrimary)
            gradeBar(label: "Corners", value: 1.0, score: "10", color: CSColor.signalGold)
            gradeBar(label: "Edges", value: 0.9, score: "9.0", color: CSColor.signalTertiary)
            gradeBar(label: "Surface", value: 0.95, score: "9.5", color: CSColor.signalPrimary)
        }
        .frame(maxWidth: 240)
    }

    private func gradeBar(label: String, value: Double, score: String, color: Color) -> some View {
        HStack(spacing: CSSpacing.sm) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(CSColor.textTertiary)
                .frame(width: 64, alignment: .trailing)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.04))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * value)
                }
            }
            .frame(height: 4)

            Text(score)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 28)
        }
    }
}

// MARK: - Step 4: Portfolio
struct OnboardingStepPortfolio: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [CSColor.signalGold.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)

                VStack(spacing: CSSpacing.md) {
                    VStack(spacing: CSSpacing.sm) {
                        Text("PORTFOLIO VALUE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CSColor.textTertiary)
                            .tracking(1)

                        Text("$12,847")
                            .font(CSFont.mono(36, weight: .heavy))
                            .foregroundStyle(CSColor.signalGold)

                        HStack(spacing: CSSpacing.xs) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                            Text("$1,320 (+11.4%) this month")
                                .font(CSFont.caption(.bold))
                        }
                        .foregroundStyle(CSColor.signalPrimary)
                        .padding(.horizontal, CSSpacing.sm)
                        .padding(.vertical, CSSpacing.xs)
                        .background(CSColor.signalPrimary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .nyxCard(padding: CSSpacing.lg)

                    HStack(spacing: CSSpacing.sm) {
                        miniCard(sport: .basketball, name: "Luka", price: "$485")
                        miniCard(sport: .baseball, name: "Ohtani", price: "$1,280")
                        miniCard(sport: .football, name: "Mahomes", price: "$210")
                    }
                }
            }

            Spacer().frame(height: CSSpacing.lg)

            Text("Track Your ")
                .font(.system(size: 28, weight: .bold)) +
            Text("Portfolio")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(CSColor.signalGold)

            Text("Monitor your collection's total value.\nGet alerts when prices spike or drop.")
                .font(CSFont.body())
                .foregroundStyle(CSColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, CSSpacing.sm)

            Spacer()

            VStack(spacing: CSSpacing.sm) {
                dotsIndicator(current: 3, total: 4)
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

    private func miniCard(sport: SportType, name: String, price: String) -> some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: sport.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: sport.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .frame(height: 56)

            VStack(spacing: 2) {
                Text(name)
                    .font(.system(size: 9, weight: .bold))
                    .lineLimit(1)
                Text(price)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(CSColor.signalGold)
            }
            .padding(6)
        }
        .frame(width: 80)
        .background(CSColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.sm)
                .stroke(CSColor.borderSubtle, lineWidth: 0.5)
        )
    }
}

// MARK: - Step 5: Paywall
struct OnboardingPaywallStep: View {
    let onComplete: () -> Void
    @State private var selectedPlan = 1

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onComplete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(CSColor.textTertiary)
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, CSSpacing.lg)
                .padding(.top, CSSpacing.sm)

                Text("👑")
                    .font(.system(size: 48))
                    .padding(.bottom, CSSpacing.sm)

                Text("Unlock ")
                    .font(CSFont.title(.bold)) +
                Text("CardScope Pro")
                    .font(CSFont.title(.bold))
                    .foregroundColor(CSColor.signalPrimary)

                Text("Unlimited scans, full market data,\nand AI-powered grading insights")
                    .font(CSFont.body())
                    .foregroundStyle(CSColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, CSSpacing.xs)

                HStack(spacing: CSSpacing.sm) {
                    Text("★★★★★")
                        .font(.system(size: 13))
                        .foregroundStyle(CSColor.signalGold)
                    Text("4.9")
                        .font(CSFont.caption(.semibold))
                        .foregroundStyle(CSColor.textSecondary)
                    Text("· 50K+ collectors")
                        .font(CSFont.caption())
                        .foregroundStyle(CSColor.textTertiary)
                }
                .padding(.top, CSSpacing.md)

                VStack(alignment: .leading, spacing: CSSpacing.sm) {
                    featureRow("Unlimited AI card identification")
                    featureRow("Full market prices (Raw / PSA 9 / 10)")
                    featureRow("Price history charts & trends")
                    featureRow("AI condition pre-grading")
                    featureRow("Unlimited collection & portfolio")
                    featureRow("Fake card detection")
                }
                .padding(.top, CSSpacing.lg)

                reviewCard
                    .padding(.top, CSSpacing.md)

                VStack(spacing: CSSpacing.sm) {
                    planOption(
                        index: 0,
                        name: "Monthly",
                        desc: "Cancel anytime",
                        price: "$7.99",
                        period: "/month",
                        badge: nil
                    )
                    planOption(
                        index: 1,
                        name: "Annual",
                        desc: "3-day free trial",
                        price: "$3.33",
                        period: "/month",
                        badge: "BEST VALUE · SAVE 58%"
                    )
                }
                .padding(.top, CSSpacing.md)

                Button("Start 3-Day Free Trial", action: onComplete)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, CSSpacing.md)

                Text("After trial, auto-renews at $39.99/year. Cancel anytime in Settings.")
                    .font(.system(size: 10))
                    .foregroundStyle(CSColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, CSSpacing.sm)

                Button("Restore Purchase") {}
                    .font(.system(size: 11))
                    .foregroundStyle(CSColor.textTertiary)
                    .underline()
                    .padding(.top, CSSpacing.sm)
                    .padding(.bottom, CSSpacing.lg)
            }
            .padding(.horizontal, CSSpacing.lg)
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(CSColor.signalPrimary.opacity(0.1))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().stroke(CSColor.signalPrimary.opacity(0.15), lineWidth: 0.5)
                    )
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(CSColor.signalPrimary)
            }
            Text(text)
                .font(CSFont.body())
                .foregroundStyle(CSColor.textSecondary)
        }
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: CSSpacing.sm) {
            HStack(spacing: CSSpacing.sm) {
                Circle()
                    .fill(CSColor.surfaceSecondary)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("M")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(CSColor.textSecondary)
                    )
                VStack(alignment: .leading) {
                    Text("Mike R.")
                        .font(CSFont.caption(.bold))
                    Text("★★★★★")
                        .font(.system(size: 10))
                        .foregroundStyle(CSColor.signalGold)
                }
            }
            Text("\"Saved me from buying a $400 fake Prizm Silver. The AI grading feature alone is worth the subscription.\"")
                .font(CSFont.caption())
                .foregroundStyle(CSColor.textSecondary)
                .lineSpacing(4)
        }
        .nyxCard()
    }

    private func planOption(index: Int, name: String, desc: String, price: String, period: String, badge: String?) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { selectedPlan = index }
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .stroke(selectedPlan == index ? CSColor.signalPrimary : CSColor.textTertiary, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Group {
                            if selectedPlan == index {
                                Circle()
                                    .fill(CSColor.signalPrimary)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(CSFont.body(.bold))
                        .foregroundStyle(CSColor.textPrimary)
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundStyle(CSColor.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(price)
                        .font(CSFont.mono(22, weight: .heavy))
                        .foregroundStyle(selectedPlan == index ? CSColor.signalPrimary : CSColor.textPrimary)
                    Text(period)
                        .font(.system(size: 11))
                        .foregroundStyle(CSColor.textTertiary)
                }
            }
            .padding(CSSpacing.md)
            .background(
                selectedPlan == index ? CSColor.signalPrimary.opacity(0.03) : CSColor.surfaceElevated
            )
            .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CSRadius.md)
                    .stroke(
                        selectedPlan == index ? CSColor.signalPrimary : CSColor.border,
                        lineWidth: selectedPlan == index ? 1.5 : 0.5
                    )
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, CSSpacing.sm)
                        .padding(.vertical, 3)
                        .background(CSColor.signalPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .offset(x: -12, y: -9)
                }
            }
        }
        .buttonStyle(.plain)
    }
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
