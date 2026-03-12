import SwiftUI

struct ScanResultView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let card: SportsCard
    @State private var isAddedToCollection = false
    @State private var showCheckmark = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBar
                cardDisplay
                playerInfo
                chips
                priceBox
                demandBar
                actionButtons
                Spacer().frame(height: CSSpacing.lg)
            }
        }
        .background(CSColor.surfacePrimary)
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
                appState.showingScan = true
            } label: {
                HStack(spacing: CSSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Rescan")
                        .font(CSFont.body(.semibold))
                }
                .foregroundStyle(CSColor.signalPrimary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {} label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundStyle(CSColor.textSecondary)
                }
                Button {} label: {
                    Image(systemName: "heart")
                        .font(.system(size: 18))
                        .foregroundStyle(CSColor.textSecondary)
                }
            }
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, CSSpacing.sm)
    }

    private var cardDisplay: some View {
        VStack(spacing: CSSpacing.md) {
            CardArtView(card: card, size: .large)
                .rotation3DEffect(.degrees(-2), axis: (x: 0, y: 1, z: 0))

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                Text("\(String(format: "%.1f", card.confidence))% match")
                    .font(CSFont.caption(.bold))
                    .monospacedDigit()
            }
            .foregroundStyle(CSColor.signalPrimary)
            .padding(.horizontal, CSSpacing.md)
            .padding(.vertical, 6)
            .background(CSColor.signalPrimary.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(CSColor.signalPrimary.opacity(0.15), lineWidth: 0.5))
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private var playerInfo: some View {
        VStack(alignment: .leading, spacing: CSSpacing.xs) {
            Text(card.playerName)
                .font(CSFont.title(.bold))
            Text(card.setDescription)
                .font(CSFont.caption())
                .foregroundStyle(CSColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private var chips: some View {
        FlowLayout(spacing: CSSpacing.sm) {
            chipView(label: "Brand", value: card.brand)
            chipView(label: "Set", value: card.setName)
            chipView(label: "Year", value: card.year)
            chipView(label: "Parallel", value: card.parallel)
            if card.isRookie {
                chipView(label: "Type", value: "RC")
            }
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private func chipView(label: String, value: String) -> some View {
        HStack(spacing: CSSpacing.xs) {
            Text(label)
                .foregroundStyle(CSColor.textTertiary)
            Text(value)
                .foregroundStyle(CSColor.textPrimary)
        }
        .font(.system(size: 11, weight: .semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(CSColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.sm)
                .stroke(CSColor.borderSubtle, lineWidth: 0.5)
        )
    }

    private var priceBox: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Text("💰")
                    Text("Market Price")
                        .font(CSFont.body(.bold))
                }
                Spacer()
                HStack(spacing: CSSpacing.xs) {
                    Circle()
                        .fill(CSColor.signalPrimary)
                        .frame(width: 5, height: 5)
                    Text("Live")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CSColor.signalPrimary)
                }
            }
            .padding(.bottom, 12)

            priceRow(label: "Raw (Ungraded)", price: "$\(card.rawPriceLow) – $\(card.rawPriceHigh)", color: CSColor.textPrimary)
            priceRow(label: "PSA 9 Mint", price: "$\(card.psa9PriceLow) – $\(card.psa9PriceHigh)", color: CSColor.signalTertiary)
            priceRow(label: "PSA 10 Gem Mint", price: "$\(card.psa10PriceLow) – $\(card.psa10PriceHigh)", color: CSColor.signalGold, isLast: true)
        }
        .nyxCard()
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private func priceRow(label: String, price: String, color: Color, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(CSFont.caption())
                    .foregroundStyle(CSColor.textSecondary)
                Spacer()
                Text(price)
                    .font(CSFont.data(.bold))
                    .foregroundStyle(color)
            }
            .padding(.vertical, 10)

            if !isLast {
                Divider()
                    .background(CSColor.borderSubtle)
            }
        }
    }

    private var demandBar: some View {
        HStack {
            HStack(spacing: CSSpacing.sm) {
                Text("📈")
                Text("Demand: On the Rise")
                    .font(CSFont.caption(.bold))
                    .foregroundStyle(CSColor.signalPrimary)
            }
            Spacer()
            Text("Last 30 days")
                .font(.system(size: 11))
                .foregroundStyle(CSColor.textTertiary)
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, 12)
        .background(CSColor.signalPrimary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.sm)
                .stroke(CSColor.signalPrimary.opacity(0.1), lineWidth: 0.5)
        )
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private var actionButtons: some View {
        HStack(spacing: CSSpacing.sm) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    appState.addToCollection(card)
                    isAddedToCollection = true
                    showCheckmark = true
                }
            } label: {
                HStack(spacing: CSSpacing.sm) {
                    Image(systemName: isAddedToCollection ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text(isAddedToCollection ? "Added" : "Add to Collection")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isAddedToCollection)
            .opacity(isAddedToCollection ? 0.6 : 1)

            Button {
                appState.selectedDetailCard = card
                appState.showingDetail = true
                dismiss()
            } label: {
                Text("Details")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.horizontal, CSSpacing.md)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}
