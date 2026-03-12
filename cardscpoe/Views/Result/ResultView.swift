//
//  ResultView.swift
//  cardscpoe
//
//  识别结果页
//

import SwiftUI

struct ResultView: View {
    let card: CardItem
    var onRescan: () -> Void
    var onAddToCollection: () -> Void
    var onViewDetail: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 顶部操作栏
                HStack {
                    Button(action: onRescan) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("重新扫描")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NyxTheme.signalPrimary)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Button { } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundStyle(NyxTheme.textSecondary)
                        }
                        Button { } label: {
                            Image(systemName: "heart")
                                .font(.system(size: 18))
                                .foregroundStyle(NyxTheme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                // 卡片展示区域
                VStack(spacing: 16) {
                    CardImageHelper.cardView(for: card, size: CGSize(width: 180, height: 252))
                        .overlay(alignment: .topLeading) {
                            Text(card.brand.uppercased())
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .foregroundStyle(NyxTheme.textSecondary.opacity(0.7))
                                .padding(4)
                                .padding(.horizontal, 6)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                                .padding(12)
                        }
                        .overlay(alignment: .topTrailing) {
                            if let grade = card.grade {
                                Text(grade)
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        LinearGradient(
                                            colors: [NyxTheme.signalGold, Color(red: 1, green: 0.58, blue: 0.24)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                                    .padding(12)
                            }
                        }
                        .overlay(alignment: .bottomTrailing) {
                            Text(card.cardNumber.hasPrefix("#") ? card.cardNumber : "#\(card.cardNumber)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(NyxTheme.textTertiary)
                                .padding(12)
                        }
                    
                    // 置信度标签
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                        Text("\(String(format: "%.1f", card.confidence * 100))% 匹配")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(NyxTheme.signalPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(NyxTheme.signalPrimary.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(NyxTheme.signalPrimary.opacity(0.15), lineWidth: 0.5)
                            )
                    )
                }
                .padding(.vertical, 20)
                
                // 球员信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.playerName)
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(NyxTheme.textPrimary)
                    Text(card.cardSetDisplay)
                        .font(.system(size: 13))
                        .foregroundStyle(NyxTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                
                // 信息芯片
                FlowLayout(spacing: 8) {
                    ChipView(label: "品牌", value: card.brand)
                    ChipView(label: "系列", value: card.set)
                    ChipView(label: "年份", value: card.year)
                    ChipView(label: "变体", value: card.parallel)
                    ChipView(label: "类型", value: card.typeLabel)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
                
                // 市场估值
                VStack(spacing: 0) {
                    HStack {
                        Text("📊 市场估值")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(NyxTheme.signalPrimary)
                                .frame(width: 6, height: 6)
                            Text("实时数据")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(NyxTheme.signalPrimary)
                        }
                    }
                    .padding(.bottom, 14)
                    
                    PriceRow(label: "Raw（未评级）", value: card.priceRaw, color: NyxTheme.textPrimary)
                    PriceRow(label: "PSA 9", value: card.pricePSA9, color: NyxTheme.signalTertiary)
                    PriceRow(label: "PSA 10 💎", value: card.pricePSA10, color: NyxTheme.signalGold)
                }
                .padding(18)
                .background(NyxTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(NyxTheme.borderSubtle, lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // 需求趋势
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("需求：上涨中")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(NyxTheme.signalPrimary)
                    Spacer()
                    Text("近30天")
                        .font(.system(size: 11))
                        .foregroundStyle(NyxTheme.textTertiary)
                }
                .padding(12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(NyxTheme.signalPrimary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(NyxTheme.signalPrimary.opacity(0.1), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // 操作按钮
                HStack(spacing: 10) {
                    Button(action: onAddToCollection) {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("添加收藏")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(15)
                        .background(NyxTheme.signalPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onViewDetail) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("详情")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(NyxTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(15)
                        .background(NyxTheme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(NyxTheme.border, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(NyxTheme.surfacePrimary)
        .navigationBarHidden(true)
    }
}

private struct ChipView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(NyxTheme.textTertiary)
            Text(value)
                .foregroundStyle(NyxTheme.textPrimary)
        }
        .font(.system(size: 11, weight: .semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(NyxTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(NyxTheme.borderSubtle, lineWidth: 0.5)
        )
    }
}

private struct PriceRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(NyxTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider()
                .background(NyxTheme.borderSubtle)
        }
    }
}

// 简单的流式布局
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(subviews: subviews, maxWidth: proposal.width ?? .infinity)
        return CGSize(width: result.width, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(subviews: subviews, maxWidth: bounds.width)
        for (index, point) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }
    
    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> (width: CGFloat, height: CGFloat, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x + size.width)
            x += size.width + spacing
        }
        
        return (totalWidth, y + rowHeight, positions)
    }
}

#Preview {
    ResultView(
        card: .demoLuka,
        onRescan: {},
        onAddToCollection: {},
        onViewDetail: {}
    )
}
