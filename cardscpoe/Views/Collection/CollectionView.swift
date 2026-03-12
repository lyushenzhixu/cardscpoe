//
//  CollectionView.swift
//  cardscpoe
//
//  我的收藏
//

import SwiftUI

struct CollectionView: View {
    @Binding var collection: [CardItem]
    var onCardTap: (CardItem) -> Void
    
    @State private var selectedFilter: SportFilter = .all
    
    private var filteredCards: [CardItem] {
        switch selectedFilter {
        case .all: return collection
        case .basketball: return collection.filter { $0.sport == .basketball }
        case .baseball: return collection.filter { $0.sport == .baseball }
        case .football: return collection.filter { $0.sport == .football }
        case .soccer: return collection.filter { $0.sport == .soccer }
        }
    }
    
    private var portfolioValue: Double {
        collection.reduce(0) { $0 + $1.estimatedValue }
    }
    
    private var monthlyChange: Double {
        12.3
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 标题
                VStack(alignment: .leading, spacing: 2) {
                    Text("我的收藏")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(NyxTheme.textPrimary)
                    Text("Portfolio 总览与管理")
                        .font(.system(size: 12))
                        .foregroundStyle(NyxTheme.textTertiary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
                
                if collection.isEmpty {
                    EmptyCollectionView()
                } else {
                    // Portfolio 卡片
                    VStack(alignment: .leading, spacing: 4) {
                        Text("收藏总估值")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(NyxTheme.textTertiary)
                            .textCase(.uppercase)
                        Text("$\(Int(portfolioValue).formatted())")
                            .font(.system(size: 36, weight: .black, design: .monospaced))
                            .foregroundStyle(NyxTheme.signalGold)
                        Text("↑ $\(Int(portfolioValue * monthlyChange / 100).formatted()) (\(String(format: "%.1f", monthlyChange))%) 本月")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(NyxTheme.signalPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(NyxTheme.signalPrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        HStack(spacing: 16) {
                            PortfolioStat(value: "\(collection.count)", label: "总卡片数", color: NyxTheme.textPrimary)
                            PortfolioStat(value: "\(Set(collection.map { $0.playerName }).count)", label: "球员数", color: NyxTheme.signalGold)
                            PortfolioStat(value: "\(Set(collection.map { $0.set }).count)", label: "系列数", color: NyxTheme.signalPrimary)
                        }
                        .padding(.top, 16)
                        .padding(.top, 16)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.04, blue: 0.29),
                                Color(red: 0.16, green: 0.06, blue: 0.38)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(NyxTheme.signalTertiary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                    
                    // 筛选标签
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SportFilter.allCases, id: \.self) { filter in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFilter = filter
                                    }
                                } label: {
                                    Text(filter.rawValue)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(selectedFilter == filter ? .black : NyxTheme.textTertiary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? NyxTheme.signalPrimary : NyxTheme.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selectedFilter == filter ? Color.clear : NyxTheme.borderSubtle, lineWidth: 0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 16)
                    
                    // 卡片网格
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(filteredCards) { card in
                            CollectionCardCell(card: card) {
                                onCardTap(card)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(NyxTheme.surfacePrimary)
    }
}

private struct PortfolioStat: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(NyxTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CollectionCardCell: View {
    let card: CardItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    CardImageHelper.cardView(for: card, size: CGSize(width: 999, height: 130))
                        .frame(height: 130)
                        .clipped()
                    
                    if let grade = card.grade {
                        Text(grade)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [NyxTheme.signalGold, Color(red: 1, green: 0.58, blue: 0.24)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 5)
                            )
                            .padding(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.playerName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(NyxTheme.textPrimary)
                        .lineLimit(1)
                    Text(card.shortSetDisplay)
                        .font(.system(size: 10))
                        .foregroundStyle(NyxTheme.textTertiary)
                        .lineLimit(1)
                    HStack {
                        Text("$\(Int(card.estimatedValue).formatted())")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundStyle(NyxTheme.signalGold)
                        Spacer()
                        Text(card.changeText)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(card.change >= 0 ? NyxTheme.signalPrimary : NyxTheme.signalWarm)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill((card.change >= 0 ? NyxTheme.signalPrimary : NyxTheme.signalWarm).opacity(0.1))
                            )
                    }
                    .padding(.top, 6)
                }
                .padding(12)
            }
            .background(NyxTheme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(NyxTheme.borderSubtle, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyCollectionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.dashed.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(NyxTheme.signalPrimary.opacity(0.5))
            
            Text("还没有收藏")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(NyxTheme.textSecondary)
            Text("扫描球星卡后点击「添加收藏」\n即可将卡片加入你的收藏夹")
                .font(.system(size: 14))
                .foregroundStyle(NyxTheme.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }
}

enum SportFilter: String, CaseIterable {
    case all = "全部"
    case basketball = "🏀 NBA"
    case baseball = "⚾ MLB"
    case football = "🏈 NFL"
    case soccer = "⚽ Soccer"
}

#Preview {
    CollectionView(collection: .constant(CardItem.demoCollection), onCardTap: { _ in })
}
