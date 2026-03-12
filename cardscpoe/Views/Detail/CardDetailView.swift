//
//  CardDetailView.swift
//  cardscpoe
//
//  卡片详情页
//

import SwiftUI

struct CardDetailView: View {
    let card: CardItem
    var onBack: () -> Void
    
    @State private var selectedChartRange = "3M"
    private let chartRanges = ["1M", "3M", "1Y", "ALL"]
    
    // 模拟价格走势数据
    private var chartData: [CGFloat] {
        [0.45, 0.50, 0.42, 0.55, 0.60, 0.52, 0.58, 0.65, 0.62, 0.70, 0.68, 0.75, 0.80, 0.78, 0.85, 0.90, 0.88, 0.95]
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 返回按钮
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NyxTheme.signalPrimary)
                }
                .padding(.bottom, 16)
                
                // 卡片头部
                HStack(alignment: .top, spacing: 16) {
                    CardImageHelper.cardView(for: card, size: CGSize(width: 120, height: 168))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.playerName)
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(NyxTheme.textPrimary)
                        Text(card.cardSetDisplay)
                            .font(.system(size: 13))
                            .foregroundStyle(NyxTheme.textSecondary)
                            .padding(.bottom, 12)
                        
                        FlowLayout(spacing: 6) {
                            SportTag(sport: card.sport)
                            Text(card.team)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(NyxTheme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(NyxTheme.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            if card.isRookie {
                                Text("Rookie")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(NyxTheme.signalGold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(NyxTheme.signalGoldDim)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.bottom, 20)
                
                // 价格走势
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("💰 价格走势 (Raw)")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(chartRanges, id: \.self) { range in
                                Button {
                                    selectedChartRange = range
                                } label: {
                                    Text(range)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(selectedChartRange == range ? .black : NyxTheme.textTertiary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(selectedChartRange == range ? NyxTheme.signalPrimary : Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 简易柱状图
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(Array(chartData.enumerated()), id: \.offset) { _, value in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [NyxTheme.signalTertiary, NyxTheme.signalTertiary.opacity(0.3)],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: max(8, value * 80))
                        }
                    }
                    .frame(height: 80)
                    .padding(.horizontal, 4)
                    
                    HStack {
                        Text("Apr")
                        Spacer()
                        Text("May")
                        Spacer()
                        Text("Jun")
                        Spacer()
                        Text("Jul")
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(NyxTheme.textTertiary)
                }
                .padding(18)
                .background(NyxTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(NyxTheme.borderSubtle, lineWidth: 0.5)
                )
                .padding(.bottom, 18)
                
                // 卡片信息
                Text("📋 卡片信息")
                    .font(.system(size: 15, weight: .bold))
                    .padding(.bottom, 10)
                
                DetailInfoRow(label: "球员", value: card.playerName)
                DetailInfoRow(label: "球队", value: card.team)
                DetailInfoRow(label: "位置", value: card.position)
                DetailInfoRow(label: "品牌", value: card.brand)
                DetailInfoRow(label: "系列", value: card.set)
                DetailInfoRow(label: "年份", value: card.year)
                DetailInfoRow(label: "卡号", value: card.cardNumberDisplay)
                DetailInfoRow(label: "变体", value: card.parallel)
                DetailInfoRow(label: "类型", value: card.typeLabel)
                
                Text("💸 近期成交")
                    .font(.system(size: 15, weight: .bold))
                    .padding(.top, 18)
                    .padding(.bottom, 10)
                
                DetailInfoRow(label: "Raw · Jul 12", value: "$235", valueColor: NyxTheme.signalPrimary)
                DetailInfoRow(label: "Raw · Jul 10", value: "$220", valueColor: NyxTheme.signalPrimary)
                DetailInfoRow(label: "PSA 9 · Jul 8", value: "$425", valueColor: NyxTheme.signalTertiary)
                DetailInfoRow(label: "PSA 10 · Jul 5", value: "$1,050", valueColor: NyxTheme.signalGold)
            }
            .padding(20)
        }
        .background(NyxTheme.surfacePrimary)
        .navigationBarHidden(true)
    }
}

private struct DetailInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = NyxTheme.textPrimary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(NyxTheme.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider()
                .background(NyxTheme.borderSubtle)
        }
    }
}

private struct SportTag: View {
    let sport: SportType
    
    var body: some View {
        HStack(spacing: 4) {
            Text(sport.emoji)
                .font(.system(size: 11))
            Text(sport.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(NyxTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(NyxTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    CardDetailView(card: .demoLuka, onBack: {})
}
