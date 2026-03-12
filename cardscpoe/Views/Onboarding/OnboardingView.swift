//
//  OnboardingView.swift
//  cardscpoe
//
//  CardScope Onboarding - 4 steps + Paywall
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentStep = 0
    @State private var selectedPlanIndex = 1
    
    private let totalSteps = 5
    
    var body: some View {
        ZStack {
            Color(NyxTheme.surfacePrimary)
                .ignoresSafeArea()
            
            if currentStep < 4 {
                onboardStepView
            } else {
                paywallStepView
            }
        }
        .animation(.easeInOut(duration: 0.35), value: currentStep)
    }
    
    private var onboardStepView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Step content
            TabView(selection: $currentStep) {
                scanStepContent.tag(0)
                valueStepContent.tag(1)
                gradeStepContent.tag(2)
                portfolioStepContent.tag(3)
                Color.clear.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 340)
            .onChange(of: currentStep) { _, _ in }
            
            Spacer()
            
            // Dots
            HStack(spacing: NyxTheme.spacingSm) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(i == currentStep ? NyxTheme.signalPrimary : Color.white.opacity(0.12))
                        .frame(width: i == currentStep ? 24 : 6, height: 6)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentStep)
                }
            }
            .padding(.bottom, NyxTheme.spacingLg)
            
            // CTA
            Button {
                if currentStep < 3 {
                    withAnimation { currentStep += 1 }
                } else {
                    withAnimation { currentStep = 4 }
                }
            } label: {
                Text(currentStep == 3 ? "开始使用" : "继续")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NyxTheme.spacingMd)
                    .background(NyxTheme.signalPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: NyxTheme.radiusMd))
            }
            .buttonStyle(NyxPressableStyle())
            .padding(.horizontal, NyxTheme.spacingLg)
            .padding(.bottom, NyxTheme.spacingSm)
            
            Button("跳过") {
                withAnimation { currentStep = 4 }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(NyxTheme.textTertiary)
            .padding(.bottom, NyxTheme.spacingLg)
        }
    }
    
    private var scanStepContent: some View {
        VStack(spacing: NyxTheme.spacingLg) {
            CardScopeImage.cardImage(for: .obScanCard)
                .frame(width: 170, height: 238)
                .clipShape(RoundedRectangle(cornerRadius: NyxTheme.radiusMd))
            
            VStack(spacing: NyxTheme.spacingSm) {
                Text("拍照识别")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NyxTheme.textPrimary)
                + Text("任何球星卡")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NyxTheme.signalPrimary)
                
                Text("对准卡片拍照，AI 2 秒内即可识别")
                    .font(.system(size: 15))
                    .foregroundStyle(NyxTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
    
    private var valueStepContent: some View {
        VStack(spacing: NyxTheme.spacingLg) {
            CardScopeImage.cardImage(for: .obValueCard)
                .frame(width: 220, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: NyxTheme.radiusLg))
            
            VStack(spacing: NyxTheme.spacingSm) {
                Text("秒知")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NyxTheme.textPrimary)
                + Text("市场价值")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NyxTheme.signalGold)
                
                Text("基于 eBay 近期成交的实时估值\n按品相分级展示价格区间")
                    .font(.system(size: 15))
                    .foregroundStyle(NyxTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
    
    private var gradeStepContent: some View {
        VStack(spacing: NyxTheme.spacingLg) {
            CardScopeImage.cardImage(for: .obGradeCard)
                .frame(width: 160, height: 224)
                .clipShape(RoundedRectangle(cornerRadius: NyxTheme.radiusMd))
            
            VStack(spacing: NyxTheme.spacingSm) {
                Text("AI ")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NyxTheme.textPrimary)
                + Text("品相预评估")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NyxTheme.signalTertiary)
                
                Text("送评前先 AI 预估，降低 PSA 送评风险")
                    .font(.system(size: 15))
                    .foregroundStyle(NyxTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
    
    private var portfolioStepContent: some View {
        VStack(spacing: NyxTheme.spacingLg) {
            CardScopeImage.cardImage(for: .obPortfolio)
                .frame(width: 260, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: NyxTheme.radiusLg))
            
            VStack(spacing: NyxTheme.spacingSm) {
                Text("追踪你的")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NyxTheme.textPrimary)
                + Text("Portfolio")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NyxTheme.signalGold)
                
                Text("收藏总价值、涨跌趋势\n像炒股一样管理球星卡投资")
                    .font(.system(size: 15))
                    .foregroundStyle(NyxTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
    
    private var paywallStepView: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("关闭")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(NyxTheme.textTertiary)
                    }
                    .padding(.trailing, NyxTheme.spacingLg)
                    .padding(.top, NyxTheme.spacingSm)
                }
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(NyxTheme.signalGold)
                    .padding(.top, NyxTheme.spacingSm)
                
                Text("解锁 ")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(NyxTheme.textPrimary)
                + Text("CardScope Pro")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(NyxTheme.signalPrimary)
                
                Text("无限识别 · 完整估值 · 价格走势\n让每一张卡的价值尽在掌握")
                    .font(.system(size: 14))
                    .foregroundStyle(NyxTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, NyxTheme.spacingSm)
                    .padding(.horizontal)
                
                // Features
                VStack(alignment: .leading, spacing: NyxTheme.spacingSm) {
                    paywallFeatureRow("无限次 AI 识别球星卡")
                    paywallFeatureRow("完整市场估值（Raw / PSA 9 / PSA 10）")
                    paywallFeatureRow("实时价格走势图与成交记录")
                    paywallFeatureRow("AI 品相预评估 & 假卡检测")
                    paywallFeatureRow("无限收藏 + Portfolio 追踪")
                }
                .padding(.horizontal, NyxTheme.spacingLg)
                .padding(.top, NyxTheme.spacingLg)
                
                // Plans
                VStack(spacing: NyxTheme.spacingSm) {
                    planRow(
                        title: "月度订阅",
                        desc: "按月付费，随时取消",
                        price: "$7.99",
                        per: "/月",
                        isSelected: selectedPlanIndex == 0,
                        badge: nil
                    ) { selectedPlanIndex = 0 }
                    
                    planRow(
                        title: "年度订阅",
                        desc: "3天免费试用 → $39.99/年",
                        price: "$3.33",
                        per: "/月",
                        isSelected: selectedPlanIndex == 1,
                        badge: "最划算 · 省58%"
                    ) { selectedPlanIndex = 1 }
                }
                .padding(.horizontal, NyxTheme.spacingLg)
                .padding(.top, NyxTheme.spacingMd)
                
                Button {
                    completeOnboarding()
                } label: {
                    Text("开始 3 天免费试用")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NyxTheme.spacingMd)
                        .background(NyxTheme.signalPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: NyxTheme.radiusMd))
                }
                .buttonStyle(NyxPressableStyle())
                .padding(.horizontal, NyxTheme.spacingLg)
                .padding(.top, NyxTheme.spacingLg)
                
                Text("3天试用期结束后自动以 $39.99/年 续费\n可随时在 App Store 设置中取消")
                    .font(.system(size: 10))
                    .foregroundStyle(NyxTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, NyxTheme.spacingSm)
                
                Button("恢复购买") {
                    // Demo: no-op
                }
                .font(.system(size: 12))
                .foregroundStyle(NyxTheme.textTertiary)
                .underline()
                .padding(.top, NyxTheme.spacingSm)
                .padding(.bottom, NyxTheme.spacingXl)
            }
        }
        .scrollIndicators(.hidden)
    }
    
    private func paywallFeatureRow(_ text: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(NyxTheme.signalPrimary)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(NyxTheme.textSecondary)
        }
    }
    
    private func planRow(
        title: String,
        desc: String,
        price: String,
        per: String,
        isSelected: Bool,
        badge: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Circle()
                    .strokeBorder(isSelected ? NyxTheme.signalPrimary : NyxTheme.textTertiary, lineWidth: 2)
                    .background(Circle().fill(isSelected ? NyxTheme.signalPrimary : Color.clear))
                    .frame(width: 22, height: 22)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(NyxTheme.textPrimary)
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundStyle(NyxTheme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text(price)
                        .font(.system(size: 18, weight: .bold).monospacedDigit())
                        .foregroundStyle(isSelected ? NyxTheme.signalPrimary : NyxTheme.textPrimary)
                    Text(per)
                        .font(.system(size: 11))
                        .foregroundStyle(NyxTheme.textTertiary)
                }
            }
            .padding(NyxTheme.spacingMd)
            .background(NyxTheme.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: NyxTheme.radiusMd)
                    .strokeBorder(isSelected ? NyxTheme.signalPrimary : Color.clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(NyxTheme.signalGold)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .offset(y: -10)
                        .padding(.trailing, 14)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: NyxTheme.radiusMd))
        }
        .buttonStyle(.plain)
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .preferredColorScheme(.dark)
}
