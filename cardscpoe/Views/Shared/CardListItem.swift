//
//  CardListItem.swift
//  cardscpoe
//
//  卡片列表项组件
//

import SwiftUI

struct CardListItem: View {
    let card: CardItem
    
    var body: some View {
        HStack(spacing: 14) {
            CardThumbnail(sport: card.sport, size: CGSize(width: 52, height: 72))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(card.playerName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(NyxTheme.Color.textPrimary)
                    .lineLimit(1)
                Text(card.cardSet)
                    .font(.system(size: 11))
                    .foregroundStyle(NyxTheme.Color.textTertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(card.priceFormatted)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(card.change >= 0 ? NyxTheme.Color.signalPrimary : NyxTheme.Color.signalWarm)
                    .fontDesign(.monospaced)
                Text(card.changeFormatted)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(card.change >= 0 ? NyxTheme.Color.signalPrimary : NyxTheme.Color.signalWarm)
            }
        }
        .padding(.horizontal, NyxTheme.Layout.md)
        .padding(.vertical, 10)
        .background(NyxTheme.Color.surfacePrimary)
        .overlay(
            Rectangle()
                .fill(NyxTheme.Color.borderSubtle)
                .frame(height: 0.5),
            alignment: .bottom
        )
        .padding(.horizontal, NyxTheme.Layout.md)
    }
}

struct CardThumbnail: View {
    let sport: SportType
    let size: CGSize
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: NyxTheme.Layout.radiusSm)
                .fill(
                    LinearGradient(
                        colors: sport.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: NyxTheme.Layout.radiusSm)
                        .stroke(NyxTheme.Color.signalGold.opacity(0.4), lineWidth: 1.5)
                )
            Text(sport.emoji)
                .font(.system(size: 28))
        }
        .frame(width: size.width, height: size.height)
    }
}

#Preview {
    CardListItem(card: CardItem.demoLuka)
        .background(NyxTheme.Color.surfacePrimary)
        .environment(AppState.shared)
}
