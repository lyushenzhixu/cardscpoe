import SwiftUI

struct PaywallView: View {
    private enum PlanOption: Int {
        case monthly
        case yearly
        case lifetime
    }

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PlanOption = .yearly
    var source: PaywallSource = .profile
    var variant: PaywallVariant = .soft
    /// 可选：来自 Onboarding 时传入，完成/关闭时调用（如 completeOnboarding）；来自 Profile 弹窗时不传。
    var onComplete: (() -> Void)? = nil

    var body: some View {
        ZStack {
            CSColor.surfacePrimary.ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [CSColor.signalPrimary.opacity(0.04), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(y: -200)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 顶部视频 Hero 区域：视频 + 底部渐变过渡 + 叠在上方的关闭按钮
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if let videoURL = Bundle.main.url(forResource: "PaywallVideo", withExtension: "mp4") {
                                LoopingVideoPlayer(url: videoURL, fillMode: .aspectFill)
                            } else {
                                Image("CollectionShowcase")
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 260)
                        .clipped()
                        .overlay(
                            // 底部渐变：视频自然融入下方深色背景
                            LinearGradient(
                                colors: [.clear, CSColor.surfacePrimary.opacity(0.6), CSColor.surfacePrimary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))

                        if shouldShowCloseButton {
                            Button {
                                onComplete?()
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(CSColor.textPrimary)
                                    .frame(width: 32, height: 32)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .padding(CSSpacing.md)
                        }
                    }
                    .padding(.horizontal, -CSSpacing.lg)
                    .padding(.top, CSSpacing.sm)

                    // 标题块：主标题 + 副标题 + 信任标识成组，与视频间距统一
                    VStack(spacing: CSSpacing.sm) {
                        Text(headerTitle)
                            .font(CSFont.title(.bold))

                        Text(headerSubtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(CSColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)

                        HStack(spacing: 6) {
                            Text("★★★★★")
                                .font(.system(size: 12))
                                .foregroundStyle(CSColor.signalGold)
                            Text("4.9")
                                .font(CSFont.caption(.semibold))
                                .foregroundStyle(CSColor.textSecondary)
                            Text("·")
                                .foregroundStyle(CSColor.textTertiary)
                            Text("50K+ collectors")
                                .font(CSFont.caption())
                                .foregroundStyle(CSColor.textTertiary)
                        }
                    }
                    .padding(.top, CSSpacing.md)

                    // 功能列表：小标题 + 列表
                    Text("Pro features")
                        .font(CSFont.caption())
                        .foregroundStyle(CSColor.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, CSSpacing.lg)

                    VStack(alignment: .leading, spacing: CSSpacing.sm) {
                        featureItem("Unlimited AI card identification")
                        featureItem("Full market prices (Raw / PSA 9 / 10)")
                        featureItem("Price history charts & trends")
                        featureItem("AI condition pre-grading")
                        featureItem("Unlimited collection & portfolio")
                        featureItem("Fake card detection")
                    }
                    .padding(.top, CSSpacing.xs)

                    VStack(spacing: CSSpacing.sm) {
                        planButton(
                            option: .monthly,
                            name: "Monthly",
                            desc: "Cancel anytime",
                            price: "$7.99/month"
                        )
                        planButton(
                            option: .yearly,
                            name: "Annual",
                            desc: "3-day free trial · $39.99/year",
                            price: "$3.33/mo",
                            badge: "BEST VALUE · SAVE 58%"
                        )
                        planButton(
                            option: .lifetime,
                            name: "Lifetime",
                            desc: "One-time purchase",
                            price: "$79.99 once"
                        )
                    }
                    .padding(.top, CSSpacing.md)

                    Button(primaryCTA) { handlePrimaryAction() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, CSSpacing.md)

                    Text(footnoteText)
                        .font(.system(size: 10))
                        .foregroundStyle(CSColor.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, CSSpacing.sm)

                    Button("Restore Purchase") {}
                        .font(.system(size: 11))
                        .foregroundStyle(CSColor.textTertiary)
                        .underline()
                        .padding(.top, CSSpacing.xs)
                        .padding(.bottom, CSSpacing.lg)
                }
                .padding(.horizontal, CSSpacing.lg)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func featureItem(_ text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(CSColor.signalPrimary.opacity(0.1))
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(CSColor.signalPrimary)
            }
            Text(text)
                .font(CSFont.body())
                .foregroundStyle(CSColor.textSecondary)
                .lineSpacing(2)
        }
    }

    private var headerTitle: AttributedString {
        var title = AttributedString("Unlock CardScope Pro")
        if let range = title.range(of: "CardScope Pro") {
            title[range].foregroundColor = CSColor.signalPrimary
        }
        return title
    }

    private var headerSubtitle: String {
        switch source {
        case .onboarding:
            return "Start with a 3-day free trial and unlock\nall premium features from day one."
        case .featureLimit:
            return "You've used your 3 free scans today.\nUpgrade for unlimited identification."
        case .valueUnlock:
            return "Unlock full valuation ranges and\nhistorical price trend charts."
        case .profile:
            return "Unlimited scans, full market data,\nand AI-powered grading insights"
        }
    }

    private var primaryCTA: String {
        switch selectedPlan {
        case .lifetime:
            return "Unlock Lifetime Pro"
        case .monthly, .yearly:
            return "Start 3-Day Free Trial"
        }
    }

    private var footnoteText: String {
        switch selectedPlan {
        case .lifetime:
            return "One-time purchase. Lifetime access to all Pro features."
        case .monthly:
            return "After trial, auto-renews at $7.99/month. Cancel anytime."
        case .yearly:
            return "After trial, auto-renews at $39.99/year. Cancel anytime."
        }
    }

    private var shouldShowCloseButton: Bool {
        if source == .profile { return true }
        if variant == .soft { return true }
        return source == .valueUnlock
    }

    private func planButton(option: PlanOption, name: String, desc: String, price: String, badge: String? = nil) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { selectedPlan = option }
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .stroke(selectedPlan == option ? CSColor.signalPrimary : CSColor.textTertiary, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Group {
                            if selectedPlan == option {
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
                        .font(CSFont.mono(18, weight: .heavy))
                        .foregroundStyle(selectedPlan == option ? CSColor.signalPrimary : CSColor.textPrimary)
                }
            }
            .padding(CSSpacing.md)
            .background(
                selectedPlan == option ? CSColor.signalPrimary.opacity(0.03) : CSColor.surfaceElevated
            )
            .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CSRadius.md)
                    .stroke(
                        selectedPlan == option ? CSColor.signalPrimary : CSColor.border,
                        lineWidth: selectedPlan == option ? 1.5 : 0.5
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

    private func handlePrimaryAction() {
        switch selectedPlan {
        case .monthly:
            appState.subscription.startTrial(days: 3)
            appState.subscription.setTier(.proMonthly)
        case .yearly:
            appState.subscription.startTrial(days: 3)
            appState.subscription.setTier(.proYearly)
        case .lifetime:
            appState.subscription.clearTrial()
            appState.subscription.setTier(.lifetime)
        }
        onComplete?()
        dismiss()
    }
}

#Preview("PaywallView - Soft") {
    PreviewContainer {
        PaywallView(source: .profile, variant: .soft)
    }
}

#Preview("PaywallView - Hard") {
    PreviewContainer {
        PaywallView(source: .onboarding, variant: .hard)
    }
}
