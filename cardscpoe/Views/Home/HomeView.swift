//
//  HomeView.swift
//  cardscpoe
//
//  CardScope - 首页
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showPaywall = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: NyxTheme.Layout.xs) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(NyxTheme.Color.signalPrimary)
                        Text("CardScope")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(NyxTheme.Color.textPrimary)
                    }
                    Spacer()
                    Button { showPaywall = true } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(NyxTheme.Color.textSecondary)
                    }
                }
                .padding(.horizontal, NyxTheme.Layout.md)
                .padding(.vertical, NyxTheme.Layout.sm)
                
                // Scan Hero Card
                Button {
                    appState.selectedTab = .scan
                } label: {
                    VStack(alignment: .leading, spacing: NyxTheme.Layout.xs) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 28))
                                .foregroundStyle(NyxTheme.Color.signalPrimary)
                            Spacer()
                        }
                        Text("扫描识别球星卡")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(NyxTheme.Color.textPrimary)
                        Text("拍照即刻获取卡片信息与估值")
                            .font(.system(size: 14))
                            .foregroundStyle(NyxTheme.Color.textSecondary)
                        HStack(spacing: NyxTheme.Layout.sm) {
                            Text("开始扫描")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.black)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.black.opacity(0.8))
                        }
                        .padding(.horizontal, NyxTheme.Layout.lg)
                        .padding(.vertical, NyxTheme.Layout.sm)
                        .background(NyxTheme.Color.signalPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: NyxTheme.Layout.radiusSm))
                    }
                    .padding(NyxTheme.Layout.lg)
                    .background(NyxTheme.Color.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: NyxTheme.Layout.radiusLg))
                    .overlay(
                        RoundedRectangle(cornerRadius: NyxTheme.Layout.radiusLg)
                            .stroke(NyxTheme.Color.borderSubtle, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, NyxTheme.Layout.md)
                .padding(.bottom, NyxTheme.Layout.md)
                
                // Stats Row
                HStack(spacing: NyxTheme.Layout.sm) {
                    StatBox(value: "$2,847", label: "收藏总值", valueColor: NyxTheme.Color.signalGold)
                    StatBox(value: "156", label: "卡片数量", valueColor: NyxTheme.Color.textPrimary)
                    StatBox(value: "+12.3%", label: "月涨幅", valueColor: NyxTheme.Color.signalPrimary)
                }
                .padding(.horizontal, NyxTheme.Layout.md)
                .padding(.bottom, NyxTheme.Layout.md)
                
                // Section: 最近识别
                SectionHeader(title: "最近识别", actionTitle: "查看全部") {
                    // Navigate to collection
                    appState.selectedTab = .collection
                }
                .padding(.horizontal, NyxTheme.Layout.md)
                .padding(.bottom, NyxTheme.Layout.sm)
                
                ForEach(appState.recentCards) { card in
                    CardListItem(card: card)
                        .onTapGesture {
                            appState.navigateToCard = card
                        }
                }
                
                // Section: 今日热门
                SectionHeader(title: "今日热门", actionTitle: "更多") {
                    appState.selectedTab = .collection
                }
                .padding(.horizontal, NyxTheme.Layout.md)
                .padding(.top, NyxTheme.Layout.lg)
                .padding(.bottom, NyxTheme.Layout.sm)
                
                ForEach(Array(appState.trendingCards.prefix(2))) { card in
                    CardListItem(card: card)
                        .onTapGesture {
                            appState.navigateToCard = card
                        }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, NyxTheme.Layout.sm)
        }
        .background(NyxTheme.Color.surfacePrimary)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

private struct StatBox: View {
    let value: String
    let label: String
    var valueColor: Color = NyxTheme.Color.textPrimary
    
    var body: some View {
        VStack(spacing: NyxTheme.Layout.xs) {
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(valueColor)
                .fontDesign(.monospaced)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(NyxTheme.Color.textTertiary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NyxTheme.Layout.md)
        .padding(.horizontal, NyxTheme.Layout.sm)
        .background(NyxTheme.Color.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: NyxTheme.Layout.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: NyxTheme.Layout.radiusMd)
                .stroke(NyxTheme.Color.borderSubtle, lineWidth: 0.5)
        )
    }
}

private struct SectionHeader: View {
    let title: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(NyxTheme.Color.textPrimary)
            Spacer()
            Button(action: action) {
                Text(actionTitle)
                    .font(.system(size: 12))
                    .foregroundStyle(NyxTheme.Color.signalPrimary)
                    .fontWeight(.medium)
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState.shared)
}
