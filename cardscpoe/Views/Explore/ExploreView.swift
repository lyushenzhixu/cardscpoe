import SwiftUI

struct ExploreView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var debounceTask: Task<Void, Never>?

    private var trendingCards: [SportsCard] {
        let trimmed = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return appState.trendingCards
        }
        return appState.trendingCards.filter {
            $0.playerName.localizedCaseInsensitiveContains(trimmed)
                || $0.brand.localizedCaseInsensitiveContains(trimmed)
                || $0.setName.localizedCaseInsensitiveContains(trimmed)
                || $0.team.localizedCaseInsensitiveContains(trimmed)
                || $0.year.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var trendingPlayers: [Player] {
        let trimmed = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return appState.trendingPlayers
        }
        return appState.trendingPlayers.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.team.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                searchBar
                #if DEBUG
                if let err = appState.trendingDataError {
                    debugErrorBanner(message: err)
                }
                #endif
                trendingPlayersSection
                popularSeriesSection
                Spacer().frame(height: 100)
            }
        }
        .background(CSColor.surfacePrimary)
        .onChange(of: searchText) { _, newValue in
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                debouncedSearchText = newValue
            }
        }
    }

    private func debugErrorBanner(message: String) -> some View {
        Text(message)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(CSColor.signalWarm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(CSSpacing.sm)
            .background(CSColor.signalWarm.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
            .padding(.horizontal, CSSpacing.md)
            .padding(.bottom, CSSpacing.sm)
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

            Button {
                if appState.canStartScanFlow() {
                    appState.showingScan = true
                }
            } label: {
                Image(systemName: "viewfinder")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(CSColor.textOnPrimary)
                    .frame(width: 44, height: 44)
                    .background(CSColor.signalPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
            }
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
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(CSColor.signalPrimary)
                    Text("Trending Players")
                        .font(CSFont.headline(.semibold))
                }
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
                    .foregroundStyle(CSColor.signalPrimary)

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
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 14))
                        .foregroundStyle(CSColor.signalPrimary)
                    Text("Popular Series")
                        .font(CSFont.headline(.semibold))
                }
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
                    Image(systemName: series.emoji)
                        .font(.system(size: 18))
                        .foregroundStyle(series.color)
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
        let trimmed = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let source: [PopularSeries]
        if trimmed.isEmpty {
            source = appState.popularSeries
        } else {
            source = appState.popularSeries.filter {
                $0.brand.localizedCaseInsensitiveContains(trimmed)
                    || $0.setName.localizedCaseInsensitiveContains(trimmed)
                    || $0.year.localizedCaseInsensitiveContains(trimmed)
            }
        }

        let palettes: [(String, Color)] = [("diamond", .purple), ("sparkles", .blue), ("flame.fill", .orange), ("wind", .teal), ("star.fill", .yellow)]
        return source.enumerated().map { index, series in
            let palette = palettes[index % palettes.count]
            return .init(
                name: series.displayName,
                subtitle: series.subtitle,
                emoji: palette.0,
                color: palette.1
            )
        }
    }
}

#Preview("ExploreView") {
    PreviewContainer {
        NavigationStack {
            ExploreView()
        }
    }
}

private struct SeriesInfo {
    let name: String
    let subtitle: String
    let emoji: String
    let color: Color
}
