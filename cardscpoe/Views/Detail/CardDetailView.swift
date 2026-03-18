import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let card: SportsCard
    @State private var selectedChartPeriod = 1
    @State private var priceData: PriceData?

    private let chartPeriods = ["7D", "1M", "3M", "6M", "1Y"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBar
                cardHero
                if appState.subscription.hasFullValuation() && appState.subscription.hasPriceChart() {
                    chartSection
                } else {
                    lockedValuationSection
                }
                cardInfoSection
                if appState.subscription.hasFullValuation() {
                    recentSalesSection
                }
                Spacer().frame(height: CSSpacing.xl)
            }
        }
        .background(CSColor.surfacePrimary)
        .preferredColorScheme(.dark)
        .task {
            priceData = await PriceService.shared.fetchPriceData(for: card, context: modelContext)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: CSSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(CSFont.body(.semibold))
                }
                .foregroundStyle(CSColor.signalPrimary)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundStyle(CSColor.textSecondary)
            }
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, CSSpacing.sm)
    }

    private var cardHero: some View {
        HStack(spacing: CSSpacing.md) {
            CardArtView(card: card, size: .medium)

            VStack(alignment: .leading, spacing: CSSpacing.xs) {
                Text(card.playerName)
                    .font(.system(size: 20, weight: .heavy))

                Text(card.setDescription)
                    .font(CSFont.caption())
                    .foregroundStyle(CSColor.textSecondary)
                    .padding(.bottom, CSSpacing.sm)

                FlowLayout(spacing: 6) {
                    tagLabel("\(card.sport.rawValue)")
                    tagLabel(card.team)
                    if card.isRookie { tagLabel("Rookie") }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private func tagLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(CSColor.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(CSColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var chartSection: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14))
                        .foregroundStyle(CSColor.signalPrimary)
                    Text("Price Trend (Raw)")
                        .font(CSFont.body(.bold))
                }
                Spacer()
                PeriodSelectorView(periods: chartPeriods, selected: $selectedChartPeriod)
            }
            .padding(.bottom, CSSpacing.md)

            AreaChartView(data: priceData?.history ?? MockData.priceHistory)

            HStack {
                let labels = chartLabels
                ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                    if index < labels.count - 1 {
                        Spacer()
                    }
                }
            }
            .font(.system(size: 10))
            .foregroundStyle(CSColor.textTertiary)
            .padding(.top, CSSpacing.sm)
        }
        .nyxCard()
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private var cardInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(CSColor.signalPrimary)
                Text("Card Information")
                    .font(CSFont.body(.bold))
            }
                .padding(.bottom, 10)

            infoRow(label: "Player", value: card.playerName)
            infoRow(label: "Team", value: card.team)
            infoRow(label: "Position", value: card.position)
            infoRow(label: "Brand", value: card.brand)
            infoRow(label: "Set", value: card.setName)
            infoRow(label: "Year", value: card.year)
            infoRow(label: "Card #", value: "#\(card.cardNumber)")
            infoRow(label: "Parallel", value: "\(card.parallel) \(card.setName)")
            infoRow(label: "Type", value: card.isRookie ? "Rookie Card" : "Base", isLast: true)
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private func infoRow(label: String, value: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(CSFont.data())
                    .foregroundStyle(CSColor.textTertiary)
                Spacer()
                Text(value)
                    .font(CSFont.data(.semibold))
                    .foregroundStyle(CSColor.textPrimary)
            }
            .padding(.vertical, 10)

            if !isLast {
                Divider()
                    .background(CSColor.borderSubtle)
            }
        }
    }

    private var recentSalesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
                    .foregroundStyle(CSColor.signalPrimary)
                Text("Recent Sales")
                    .font(CSFont.body(.bold))
            }
                .padding(.bottom, 10)

            let sales = priceData?.recentSales ?? MockData.recentSales
            ForEach(Array(sales.enumerated()), id: \.element.id) { index, sale in
                HStack {
                    Text("\(sale.grade) · \(sale.date)")
                        .font(CSFont.data())
                        .foregroundStyle(CSColor.textTertiary)
                    Spacer()
                    Text("$\(sale.price)")
                        .font(CSFont.data(.semibold))
                        .foregroundStyle(saleColor(for: sale.grade))
                }
                .padding(.vertical, 10)

                if index < sales.count - 1 {
                    Divider()
                        .background(CSColor.borderSubtle)
                }
            }
        }
        .padding(.horizontal, CSSpacing.md)
    }

    private var lockedValuationSection: some View {
        VStack(alignment: .leading, spacing: CSSpacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(CSColor.signalPrimary)
                Text("Price Trend (Pro)")
                    .font(CSFont.body(.bold))
            }

            Text("Unlock full valuation ranges, historical price trends, and recent sales.")
                .font(CSFont.caption())
                .foregroundStyle(CSColor.textSecondary)

            Button("Unlock Full Valuation") {
                appState.presentPaywall(source: .valueUnlock)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, CSSpacing.xs)
        }
        .nyxCard()
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private func saleColor(for grade: String) -> Color {
        switch grade {
        case "PSA 10": return CSColor.signalPrimary
        case "PSA 9": return Color(red: 0.38, green: 0.65, blue: 0.98)
        default: return CSColor.signalPrimary
        }
    }

    private var chartLabels: [String] {
        let history = priceData?.history ?? MockData.priceHistory
        guard !history.isEmpty else { return ["-", "-", "-", "-"] }
        let first = history.first?.month ?? "-"
        let q1 = history[min(history.count / 3, history.count - 1)].month
        let q2 = history[min((history.count * 2) / 3, history.count - 1)].month
        let last = history.last?.month ?? "-"
        return [first, q1, q2, last]
    }
}

#Preview("CardDetailView") {
    PreviewContainer {
        NavigationStack {
            CardDetailView(card: MockData.lukaDoncic)
        }
    }
}
