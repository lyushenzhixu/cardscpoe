import SwiftUI

struct ExploreView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                searchBar
                trendingPlayersSection
                popularSeriesSection
                Spacer().frame(height: 100)
            }
        }
        .background(CSColor.surfacePrimary)
    }

    private var header: some View {
        Text("Explore")
            .font(CSFont.title(.bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, CSSpacing.md)
            .padding(.vertical, CSSpacing.sm)
    }

    private var searchBar: some View {
        HStack(spacing: CSSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(CSColor.textTertiary)

            TextField("Search players, sets, brands...", text: $searchText)
                .font(CSFont.body())
                .foregroundStyle(CSColor.textPrimary)
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, 12)
        .background(CSColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.md)
                .stroke(CSColor.borderSubtle, lineWidth: 0.5)
        )
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.lg)
    }

    private var trendingPlayersSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("🔥 Trending Players")
                    .font(CSFont.headline(.semibold))
                Spacer()
                Text("See All ›")
                    .font(CSFont.caption(.medium))
                    .foregroundStyle(CSColor.signalPrimary)
            }
            .padding(.horizontal, CSSpacing.md)
            .padding(.bottom, CSSpacing.sm)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CSSpacing.sm) {
                    ForEach(MockData.allCards) { card in
                        Button {
                            appState.selectedDetailCard = card
                            appState.showingDetail = true
                        } label: {
                            trendingPlayerCard(card)
                        }
                        .buttonStyle(NyxPressableStyle())
                    }
                }
                .padding(.horizontal, CSSpacing.md)
            }
            .padding(.bottom, CSSpacing.lg)
        }
    }

    private func trendingPlayerCard(_ card: SportsCard) -> some View {
        VStack(spacing: CSSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: CSRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: card.sport.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 80)

                Image(systemName: card.sport.icon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            Text(card.playerName)
                .font(CSFont.caption(.bold))
                .foregroundStyle(CSColor.textPrimary)
                .lineLimit(1)

            HStack(spacing: CSSpacing.xs) {
                Text("$\(card.currentPrice)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(CSColor.signalGold)

                Text(card.priceChangeFormatted)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(card.priceChange >= 0 ? CSColor.signalPrimary : CSColor.signalWarm)
            }
        }
        .frame(width: 100)
        .padding(.vertical, CSSpacing.sm)
        .background(CSColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.md)
                .stroke(CSColor.borderSubtle, lineWidth: 0.5)
        )
    }

    private var popularSeriesSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("📦 Popular Series")
                    .font(CSFont.headline(.semibold))
                Spacer()
                Text("More ›")
                    .font(CSFont.caption(.medium))
                    .foregroundStyle(CSColor.signalPrimary)
            }
            .padding(.horizontal, CSSpacing.md)
            .padding(.bottom, CSSpacing.sm)

            ForEach(seriesData, id: \.name) { series in
                seriesRow(series)
            }
        }
    }

    private func seriesRow(_ series: SeriesInfo) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: CSRadius.sm)
                .fill(
                    LinearGradient(
                        colors: [series.color.opacity(0.3), series.color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Text(series.emoji)
                        .font(.system(size: 20))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(series.name)
                    .font(CSFont.body(.semibold))
                    .foregroundStyle(CSColor.textPrimary)
                Text(series.subtitle)
                    .font(CSFont.caption())
                    .foregroundStyle(CSColor.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CSColor.textTertiary)
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, 10)
    }

    private var seriesData: [SeriesInfo] {
        [
            .init(name: "Panini Prizm", subtitle: "2018-2024 · 120K+ cards", emoji: "💎", color: .purple),
            .init(name: "Topps Chrome", subtitle: "2015-2024 · 95K+ cards", emoji: "✨", color: .blue),
            .init(name: "Panini Select", subtitle: "2019-2024 · 80K+ cards", emoji: "🔥", color: .orange),
            .init(name: "Panini Mosaic", subtitle: "2020-2024 · 60K+ cards", emoji: "🌀", color: .teal),
            .init(name: "Donruss Optic", subtitle: "2017-2024 · 55K+ cards", emoji: "⭐", color: .yellow),
        ]
    }
}

private struct SeriesInfo {
    let name: String
    let subtitle: String
    let emoji: String
    let color: Color
}
