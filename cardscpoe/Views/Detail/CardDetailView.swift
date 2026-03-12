import SwiftUI

struct CardDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let card: SportsCard
    @State private var selectedChartPeriod = 1

    private let chartPeriods = ["1M", "3M", "1Y", "ALL"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBar
                cardHero
                chartSection
                cardInfoSection
                recentSalesSection
                aiGradeButton
                Spacer().frame(height: CSSpacing.xl)
            }
        }
        .background(CSColor.surfacePrimary)
        .preferredColorScheme(.dark)
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
                Text("💰 Price Trend (Raw)")
                    .font(CSFont.body(.bold))
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<chartPeriods.count, id: \.self) { i in
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedChartPeriod = i }
                        } label: {
                            Text(chartPeriods[i])
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(selectedChartPeriod == i ? .black : CSColor.textTertiary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    selectedChartPeriod == i ? CSColor.signalPrimary : Color.white.opacity(0.05)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .padding(.bottom, CSSpacing.md)

            miniChart

            HStack {
                Text("Jan")
                Spacer()
                Text("Apr")
                Spacer()
                Text("Jul")
                Spacer()
                Text("Dec")
            }
            .font(.system(size: 10))
            .foregroundStyle(CSColor.textTertiary)
            .padding(.top, CSSpacing.sm)
        }
        .nyxCard()
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private var miniChart: some View {
        GeometryReader { geo in
            let data = MockData.priceHistory
            let maxVal = data.map(\.value).max() ?? 1
            let minVal = data.map(\.value).min() ?? 0
            let range = maxVal - minVal
            let w = geo.size.width / CGFloat(data.count)

            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                        let h = range > 0 ? CGFloat((point.value - minVal) / range) * 70 + 10 : 40
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [CSColor.signalPrimary, CSColor.signalPrimary.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: h)
                    }
                }

                Path { path in
                    for (index, point) in data.enumerated() {
                        let x = CGFloat(index) * w + w / 2
                        let y = range > 0 ? 80 - CGFloat((point.value - minVal) / range) * 70 - 10 : 40
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(CSColor.signalPrimary.opacity(0.6), lineWidth: 1.5)
            }
        }
        .frame(height: 80)
    }

    private var cardInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("📋 Card Information")
                .font(CSFont.body(.bold))
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
            Text("💸 Recent Sales")
                .font(CSFont.body(.bold))
                .padding(.bottom, 10)

            ForEach(Array(MockData.recentSales.enumerated()), id: \.element.id) { index, sale in
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

                if index < MockData.recentSales.count - 1 {
                    Divider()
                        .background(CSColor.borderSubtle)
                }
            }
        }
        .padding(.horizontal, CSSpacing.md)
    }

    private var aiGradeButton: some View {
        Button {
            appState.gradeCard = card
            appState.showingGrade = true
            dismiss()
        } label: {
            HStack(spacing: CSSpacing.sm) {
                Text("💎")
                Text("AI Grade This Card")
                    .font(CSFont.body(.bold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(CSColor.signalGold)
            .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
        }
        .buttonStyle(NyxPressableStyle())
        .padding(.horizontal, CSSpacing.md)
        .padding(.top, CSSpacing.lg)
    }

    private func saleColor(for grade: String) -> Color {
        switch grade {
        case "PSA 10": return CSColor.signalGold
        case "PSA 9": return Color(red: 0.38, green: 0.65, blue: 0.98)
        default: return CSColor.signalPrimary
        }
    }
}
