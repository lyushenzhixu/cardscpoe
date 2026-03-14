import SwiftUI

struct ExploreView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""

    private var trendingCards: [SportsCard] {
        let source = appState.trendingCards.isEmpty ? appState.recentScans : appState.trendingCards
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return source
        }
        return source.filter {
            $0.playerName.localizedCaseInsensitiveContains(searchText)
                || $0.brand.localizedCaseInsensitiveContains(searchText)
                || $0.setName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var trendingPlayers: [Player] {
        guard !appState.trendingPlayers.isEmpty else {
            return trendingCards.map {
                Player(name: $0.playerName, sport: $0.sport, team: $0.team, position: $0.position, headshotURL: $0.headshotURL)
            }
        }
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return appState.trendingPlayers
        }
        return appState.trendingPlayers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.team.localizedCaseInsensitiveContains(searchText)
        }
    }

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
                    ForEach(Array(trendingPlayers.enumerated()), id: \.element.id) { index, player in
                        Button {
                            if let matchedCard = trendingCards.first(where: { $0.playerName.localizedCaseInsensitiveContains(player.name) }) {
                                appState.selectedDetailCard = matchedCard
                                appState.showingDetail = true
                            }
                        } label: {
                            trendingPlayerCard(player, index: index)
                        }
                        .buttonStyle(NyxPressableStyle())
                    }
                }
                .padding(.horizontal, CSSpacing.md)
            }
            .padding(.bottom, CSSpacing.lg)
        }
    }

    private static let playerImageNames = ["Player1", "Player2", "Player3", "Player4", "Player5"]

    private func trendingPlayerCard(_ player: Player, index: Int) -> some View {
        let matchedCard = trendingCards.first(where: { $0.playerName.localizedCaseInsensitiveContains(player.name) })
        let imageName = Self.playerImageNames[index % Self.playerImageNames.count]
        return VStack(spacing: CSSpacing.sm) {
            if let url = player.headshotURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(imageName).resizable().scaledToFill()
                }
                .frame(width: 100, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
            } else {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
            }

            Text(player.name)
                .font(CSFont.caption(.bold))
                .foregroundStyle(CSColor.textPrimary)
                .lineLimit(1)

            HStack(spacing: CSSpacing.xs) {
                Text("$\(matchedCard?.currentPrice ?? 0)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(CSColor.signalGold)

                Text(matchedCard?.priceChangeFormatted ?? "0.0%")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle((matchedCard?.priceChange ?? 0) >= 0 ? CSColor.signalPrimary : CSColor.signalWarm)
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
        let source = appState.trendingCards.isEmpty ? appState.recentScans : appState.trendingCards
        let grouped = Dictionary(grouping: source) { "\($0.brand) \($0.setName)" }
        let palettes: [(String, Color)] = [("💎", .purple), ("✨", .blue), ("🔥", .orange), ("🌀", .teal), ("⭐", .yellow)]
        return grouped.keys.sorted().enumerated().map { index, key in
            let cards = grouped[key] ?? []
            let years = cards.map(\.year).sorted()
            let minYear = years.first ?? "N/A"
            let maxYear = years.last ?? "N/A"
            let palette = palettes[index % palettes.count]
            return .init(
                name: key,
                subtitle: "\(minYear)-\(maxYear) · \(cards.count) cards",
                emoji: palette.0,
                color: palette.1
            )
        }
    }
}

private struct SeriesInfo {
    let name: String
    let subtitle: String
    let emoji: String
    let color: Color
}
