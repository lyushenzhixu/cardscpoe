import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                scanHeroCard
                statsRow
                recentlyScannedSection
                trendingSection
                Spacer().frame(height: 100)
            }
        }
        .background(CSColor.surfacePrimary)
    }

    private var header: some View {
        HStack {
            HStack(spacing: CSSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: CSRadius.sm)
                        .fill(CSColor.signalPrimary)
                        .frame(width: 28, height: 28)
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.black)
                }
                Text("CardScope")
                    .font(CSFont.headline(.bold))
            }

            Spacer()

            Circle()
                .fill(CSColor.surfaceElevated)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle().stroke(CSColor.border, lineWidth: 0.5)
                )
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(CSColor.textTertiary)
                )
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, CSSpacing.sm)
    }

    private var scanHeroCard: some View {
        Button {
            appState.showingScan = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: CSRadius.lg)
                    .fill(CSColor.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: CSRadius.lg)
                            .stroke(CSColor.borderSubtle, lineWidth: 0.5)
                    )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [CSColor.signalPrimary.opacity(0.06), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .offset(x: 60, y: -40)

                VStack(alignment: .leading, spacing: CSSpacing.xs) {
                    HStack {
                        Text("Identify Cards ")
                            .font(CSFont.title(.bold)) +
                        Text("Instantly")
                            .font(CSFont.title(.bold))
                            .foregroundColor(CSColor.signalPrimary)
                    }

                    Text("Snap a photo to get player info & market value")
                        .font(CSFont.body())
                        .foregroundStyle(CSColor.textSecondary)
                        .padding(.bottom, CSSpacing.sm)

                    HStack(spacing: CSSpacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                        Text("Scan Now")
                            .font(CSFont.body(.bold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, CSSpacing.lg)
                    .padding(.vertical, 10)
                    .background(CSColor.signalPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
                }
                .padding(CSSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(NyxPressableStyle())
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private var statsRow: some View {
        HStack(spacing: CSSpacing.sm) {
            statCard(
                value: "$\(formattedValue(appState.totalValue))",
                label: "TOTAL VALUE",
                color: CSColor.signalGold
            )
            statCard(
                value: "\(appState.totalCards)",
                label: "CARDS",
                color: CSColor.textPrimary
            )
            statCard(
                value: "+12.3%",
                label: "THIS MONTH",
                color: CSColor.signalPrimary
            )
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: CSSpacing.xs) {
            Text(value)
                .font(CSFont.title(.heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(CSColor.textTertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CSSpacing.md)
        .background(CSColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.md)
                .stroke(CSColor.borderSubtle, lineWidth: 0.5)
        )
    }

    private var recentlyScannedSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "Recently Scanned", action: "See All ›")

            ForEach(appState.recentScans.prefix(4)) { card in
                Button {
                    appState.selectedDetailCard = card
                    appState.showingDetail = true
                } label: {
                    CardListItem(card: card)
                }
                .buttonStyle(NyxPressableStyle())
            }
        }
    }

    private var trendingSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "Trending", action: "More ›")
                .padding(.top, CSSpacing.md)

            ForEach([MockData.bellingham]) { card in
                Button {
                    appState.selectedDetailCard = card
                    appState.showingDetail = true
                } label: {
                    CardListItem(card: card)
                }
                .buttonStyle(NyxPressableStyle())
            }
        }
    }

    private func sectionHeader(title: String, action: String) -> some View {
        HStack {
            Text(title)
                .font(CSFont.headline(.semibold))
            Spacer()
            Text(action)
                .font(CSFont.caption(.medium))
                .foregroundStyle(CSColor.signalPrimary)
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.sm)
    }

    private func formattedValue(_ value: Int) -> String {
        if value >= 1000 {
            return String(format: "%.1fK", Double(value) / 1000.0)
        }
        return "\(value)"
    }
}

struct CardListItem: View {
    let card: SportsCard

    var body: some View {
        HStack(spacing: 12) {
            CardArtView(card: card, size: .thumbnail)

            VStack(alignment: .leading, spacing: 2) {
                Text(card.playerName)
                    .font(CSFont.body(.semibold))
                    .foregroundStyle(CSColor.textPrimary)
                Text(card.shortDescription)
                    .font(CSFont.caption())
                    .foregroundStyle(CSColor.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(card.currentPrice)")
                    .font(CSFont.body(.bold))
                    .monospacedDigit()
                    .foregroundStyle(card.priceChange >= 0 ? CSColor.signalPrimary : CSColor.signalWarm)
                Text("\(card.priceChangeArrow) \(card.priceChangeFormatted)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(card.priceChange >= 0 ? CSColor.signalPrimary : CSColor.signalWarm)
            }
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, 10)
    }
}
