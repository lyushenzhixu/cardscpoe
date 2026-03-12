import SwiftUI

struct CollectionView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedFilter = 0

    private let filters: [String] = ["All", "🏀 NBA", "⚾ MLB", "🏈 NFL", "⚽ Soccer"]
    private let sportFilters: [SportType?] = [nil, .basketball, .baseball, .football, .soccer]

    private var filteredCards: [SportsCard] {
        guard let sportFilter = sportFilters[selectedFilter] else {
            return appState.collectionCards
        }
        return appState.collectionCards.filter { $0.sport == sportFilter }
    }

    let columns = [
        GridItem(.flexible(), spacing: CSSpacing.sm),
        GridItem(.flexible(), spacing: CSSpacing.sm),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                portfolioCard
                filterTabs
                cardGrid
                Spacer().frame(height: 100)
            }
        }
        .background(CSColor.surfacePrimary)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("My Collection")
                .font(CSFont.title(.bold))
            Text("\(appState.totalCards) Cards · 8 Series")
                .font(CSFont.caption())
                .foregroundStyle(CSColor.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, CSSpacing.sm)
    }

    private var portfolioCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: CSSpacing.sm) {
                Text("TOTAL EST. VALUE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(CSColor.textTertiary)
                    .tracking(1)

                Text("$\(formattedPrice(appState.totalValue))")
                    .font(CSFont.mono(34, weight: .heavy))
                    .foregroundStyle(CSColor.signalGold)

                HStack(spacing: CSSpacing.xs) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10))
                    Text("$532 (+12.3%) this month")
                        .font(CSFont.caption(.bold))
                }
                .foregroundStyle(CSColor.signalPrimary)
                .padding(.horizontal, CSSpacing.sm)
                .padding(.vertical, CSSpacing.xs)
                .background(CSColor.signalPrimary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Divider()
                .background(CSColor.borderSubtle)
                .padding(.top, CSSpacing.md)

            HStack(spacing: CSSpacing.md) {
                portfolioStat(value: "\(appState.totalCards)", label: "Cards", color: CSColor.textPrimary)
                portfolioStat(value: "23", label: "Players", color: CSColor.signalGold)
                portfolioStat(value: "8", label: "Series", color: CSColor.signalPrimary)
            }
            .padding(.top, CSSpacing.md)
        }
        .padding(CSSpacing.lg)
        .background(CSColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.lg)
                .stroke(CSColor.border, lineWidth: 0.5)
        )
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private func portfolioStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(CSFont.title(.heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(CSColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CSSpacing.sm) {
                ForEach(0..<filters.count, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedFilter = i }
                    } label: {
                        Text(filters[i])
                            .font(CSFont.caption(.semibold))
                            .foregroundStyle(selectedFilter == i ? .black : CSColor.textTertiary)
                            .padding(.horizontal, CSSpacing.md)
                            .padding(.vertical, CSSpacing.sm)
                            .background(
                                selectedFilter == i ? CSColor.signalPrimary : CSColor.surfaceElevated
                            )
                            .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: CSRadius.sm)
                                    .stroke(
                                        selectedFilter == i ? CSColor.signalPrimary : CSColor.borderSubtle,
                                        lineWidth: 0.5
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, CSSpacing.md)
        }
        .padding(.bottom, CSSpacing.md)
    }

    private var cardGrid: some View {
        LazyVGrid(columns: columns, spacing: CSSpacing.sm) {
            ForEach(filteredCards) { card in
                Button {
                    appState.selectedDetailCard = card
                    appState.showingDetail = true
                } label: {
                    CollectionGridCard(card: card)
                }
                .buttonStyle(NyxPressableStyle())
            }
        }
        .padding(.horizontal, CSSpacing.md)
    }

    private func formattedPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

struct CollectionGridCard: View {
    let card: SportsCard

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                CardArtGridView(card: card)
            }
            .frame(height: 110)

            VStack(alignment: .leading, spacing: 2) {
                Text(card.playerName)
                    .font(CSFont.caption(.bold))
                    .foregroundStyle(CSColor.textPrimary)
                    .lineLimit(1)

                Text(card.shortDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(CSColor.textTertiary)
                    .lineLimit(1)

                HStack {
                    Text("$\(card.currentPrice)")
                        .font(CSFont.data(.heavy))
                        .foregroundStyle(CSColor.signalGold)

                    Spacer()

                    Text("\(card.priceChangeArrow) \(abs(Int(card.priceChange)))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(card.priceChange >= 0 ? CSColor.signalPrimary : CSColor.signalWarm)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (card.priceChange >= 0 ? CSColor.signalPrimary : CSColor.signalWarm).opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(.top, CSSpacing.sm)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(CSColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.md)
                .stroke(CSColor.borderSubtle, lineWidth: 0.5)
        )
    }
}
