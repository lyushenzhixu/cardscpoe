//
//  PaywallView.swift
//  cardscpoe
//
//  CardScope 付费墙界面
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaywallPlan = .annual
    
    enum PaywallPlan {
        case monthly
        case annual
    }
    
    var body: some View {
        ZStack {
            Color(NyxTheme.surfacePrimary)
                .ignoresSafeArea()
            
            // 顶部光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [NyxTheme.signalPrimary.opacity(0.06), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(y: -250)
                .blur(radius: 20)
            
            ScrollView {
                VStack(spacing: 0) {
                    // 关闭按钮
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Text("关闭")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(NyxTheme.textTertiary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    
                    // 标题区
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [NyxTheme.signalGold, Color(hex: 0xFB923C)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: NyxTheme.signalGold.opacity(0.3), radius: 8)
                        .padding(.top, 8)
                    
                    Text("解锁 CardScope Pro")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(NyxTheme.textPrimary)
                        .padding(.top, 12)
                    
                    Text("无限识别 · 完整估值 · 价格走势\n让每一张卡的价值尽在掌握")
                        .font(.system(size: 14))
                        .foregroundColor(NyxTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    
                    // 功能列表
                    VStack(alignment: .leading, spacing: 4) {
                        PaywallFeatureRow(text: "无限次 AI 识别球星卡")
                        PaywallFeatureRow(text: "完整市场估值（Raw / PSA 9 / PSA 10）")
                        PaywallFeatureRow(text: "实时价格走势图与成交记录")
                        PaywallFeatureRow(text: "AI 品相预评估 & 假卡检测")
                        PaywallFeatureRow(text: "无限收藏 + Portfolio 追踪")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // 订阅选项
                    VStack(spacing: 10) {
                        PlanRow(
                            title: "月度订阅",
                            desc: "按月付费，随时取消",
                            price: "$7.99",
                            per: "/月",
                            isSelected: selectedPlan == .monthly
                        ) {
                            selectedPlan = .monthly
                        }
                        
                        PlanRow(
                            title: "年度订阅",
                            desc: "3天免费试用 → $39.99/年",
                            price: "$3.33",
                            per: "/月",
                            isSelected: selectedPlan == .annual,
                            badge: "最划算 · 省58%"
                        ) {
                            selectedPlan = .annual
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // CTA
                    Button {
                        dismiss()
                    } label: {
                        Text("开始 3 天免费试用")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(NyxTheme.signalPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    Text("3天试用期结束后自动以 $39.99/年 续费\n可随时在 App Store 设置中取消")
                        .font(.system(size: 11))
                        .foregroundColor(NyxTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    
                    Button("恢复购买") {
                        // 恢复购买逻辑
                    }
                    .font(.system(size: 12))
                    .foregroundColor(NyxTheme.textTertiary)
                    .underline()
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct PaywallFeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(NyxTheme.signalPrimary)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(NyxTheme.textSecondary)
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

private struct PlanRow: View {
    let title: String
    let desc: String
    let price: String
    let per: String
    let isSelected: Bool
    var badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? NyxTheme.signalPrimary : NyxTheme.textTertiary, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(NyxTheme.signalPrimary)
                            .frame(width: 12, height: 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(NyxTheme.textPrimary)
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundColor(NyxTheme.textTertiary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text(price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isSelected ? NyxTheme.signalGold : NyxTheme.textPrimary)
                    Text(per)
                        .font(.system(size: 11))
                        .foregroundColor(NyxTheme.textTertiary)
                }
            }
            .padding(16)
            .background(isSelected ? NyxTheme.signalGold.opacity(0.04) : NyxTheme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? NyxTheme.signalGold.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(NyxTheme.signalGold)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .offset(x: 14, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
}
