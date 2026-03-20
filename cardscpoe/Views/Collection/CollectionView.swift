import SwiftUI

struct CollectionView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedFilter = 0
    @State private var visibleCount = 20

    private let filters: [String] = ["All", "NBA", "MLB", "NFL", "Soccer"]
    private let sportFilters: [SportType?] = [nil, .basketball, .baseball, .football, .soccer]

    private var filteredCards: [SportsCard] {
        guard let sportFilter = sportFilters[selectedFilter] else {
            return appState.collectionCards
        }
        return appState.collectionCards.filter { $0.sport == sportFilter }
    }

    let columns = [
        GridItem(.flexible(), spacing: 11),
        GridItem(.flexible(), spacing: 11),
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
        let uniquePlayers = Set(appState.collectionCards.map(\.playerName)).count
        return VStack(alignment: .leading, spacing: 4) {
            Text("My Collection")
                .font(CSFont.title(.bold))
            Text("\(appState.totalCards) cards \u{00B7} \(uniquePlayers) players")
                .font(.system(size: 13))
                .foregroundStyle(CSColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, CSSpacing.sm)
    }

    private var portfolioCard: some View {
        VStack(spacing: 12) {
            Text("Portfolio Value")
                .font(.system(size: 13))
                .foregroundStyle(CSColor.textSecondary)

            Text("$\(formattedPrice(appState.totalValue))")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(CSColor.textPrimary)

            HStack(spacing: CSSpacing.xs) {
                Image(systemName: appState.monthlyChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 12))
                let dollarChange = Int(Double(appState.totalValue) * appState.monthlyChange / 100)
                Text("+$\(formattedPrice(abs(dollarChange))) (\(String(format: "%.1f", abs(appState.monthlyChange)))%) this month")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(appState.monthlyChange >= 0 ? CSColor.signalPrimary : CSColor.signalWarm)
            .padding(.horizontal, CSSpacing.sm)
            .padding(.vertical, CSSpacing.xs)
            .background((appState.monthlyChange >= 0 ? CSColor.signalPrimary : CSColor.signalWarm).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack(spacing: CSSpacing.md) {
                let uniquePlayers = Set(appState.collectionCards.map(\.playerName)).count
                let uniqueSeries = Set(appState.collectionCards.map { "\($0.brand) \($0.setName)" }).count
                portfolioStat(value: "\(appState.totalCards)", label: "Cards")
                portfolioStat(value: "\(uniquePlayers)", label: "Players")
                portfolioStat(value: "\(uniqueSeries)", label: "Series")
            }
        }
        .padding(CSSpacing.md)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x22/255.0),
                    Color(red: 0x0D/255.0, green: 0x2E/255.0, blue: 0x22/255.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.md)
                .stroke(CSColor.signalPrimary.opacity(0.125), lineWidth: 1)
        )
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private func portfolioStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(CSColor.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(CSColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CSSpacing.sm) {
                ForEach(0..<filters.count, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = i
                            visibleCount = 20
                        }
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

    private var displayedCards: [SportsCard] {
        Array(filteredCards.prefix(visibleCount))
    }

    private var hasMore: Bool {
        visibleCount < filteredCards.count
    }

    private var cardGrid: some View {
        Group {
            if filteredCards.isEmpty {
                emptyCollectionState
            } else {
                VStack(spacing: CSSpacing.md) {
                    LazyVGrid(columns: columns, spacing: 11) {
                        ForEach(displayedCards) { card in
                            Button {
                                appState.selectedDetailCard = card
                                appState.showingDetail = true
                            } label: {
                                CollectionGridCard(card: card)
                            }
                            .buttonStyle(NyxPressableStyle())
                        }
                    }

                    if hasMore {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                visibleCount += 20
                            }
                        } label: {
                            HStack(spacing: CSSpacing.sm) {
                                Text("Load More")
                                    .font(CSFont.body(.semibold))
                                Text("(\(filteredCards.count - visibleCount) remaining)")
                                    .font(CSFont.caption())
                                    .foregroundStyle(CSColor.textTertiary)
                            }
                            .foregroundStyle(CSColor.signalPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(CSColor.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: CSRadius.md)
                                    .stroke(CSColor.signalPrimary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, CSSpacing.md)
    }

    private var emptyCollectionState: some View {
        VStack(spacing: CSSpacing.lg) {
            Image("EmptyCollectionState")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
            Text("No cards yet")
                .font(CSFont.headline(.semibold))
                .foregroundStyle(CSColor.textPrimary)
            Text("Scan cards to add them to your collection")
                .font(CSFont.caption())
                .foregroundStyle(CSColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func formattedPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

#Preview("CollectionView") {
    PreviewContainer {
        NavigationStack {
            CollectionView()
        }
    }
}

struct CollectionGridCard: View {
    let card: SportsCard

    var body: some View {
        VStack(spacing: 0) {
            CardArtGridView(card: card)
                .frame(height: 110)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.playerName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CSColor.textPrimary)
                    .lineLimit(1)

                Text(card.shortDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(CSColor.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("$\(card.formattedCurrentPrice)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(CSColor.textPrimary)

                    Text("\(card.priceChange >= 0 ? "+" : "")\(abs(Int(card.priceChange)))%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(card.priceChange >= 0 ? CSColor.signalPrimary : CSColor.signalWarm)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (card.priceChange >= 0 ? CSColor.signalPrimary : CSColor.signalWarm).opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(12)
        }
        .background(CSColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.md)
                .stroke(CSColor.borderSubtle, lineWidth: 0.5)
        )
    }
}

#Preview("CollectionGridCard") {
    CollectionGridCard(card: MockData.lukaDoncic)
        .frame(width: 180)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
