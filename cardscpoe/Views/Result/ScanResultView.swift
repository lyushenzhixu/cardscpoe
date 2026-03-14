import SwiftUI
import SwiftData

struct ScanResultView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let card: SportsCard
    @State private var isAddedToCollection = false
    @State private var showCheckmark = false
    @State private var priceData: PriceData?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBar
                cardDisplay
                playerInfo
                chips
                if appState.subscription.hasFullValuation() {
                    priceBox
                } else {
                    lockedPriceBox
                }
                ocrHint
                demandBar
                actionButtons
                Spacer().frame(height: CSSpacing.lg)
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
            Image("ScanSuccessState")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320, maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))

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

            priceRow(label: "Raw (Ungraded)", price: "$\(rawRange.lowerBound) – $\(rawRange.upperBound)", color: CSColor.textPrimary)
            priceRow(label: "PSA 9 Mint", price: "$\(psa9Range.lowerBound) – $\(psa9Range.upperBound)", color: CSColor.signalTertiary)
            priceRow(label: "PSA 10 Gem Mint", price: "$\(psa10Range.lowerBound) – $\(psa10Range.upperBound)", color: CSColor.signalGold, isLast: true)
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

    private var ocrHint: some View {
        Group {
            if let text = appState.latestExtractedText, !text.isEmpty {
                HStack(alignment: .top, spacing: CSSpacing.sm) {
                    Image(systemName: "text.viewfinder")
                        .foregroundStyle(CSColor.signalPrimary)
                    Text(text)
                        .font(.system(size: 11))
                        .foregroundStyle(CSColor.textTertiary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CSSpacing.md)
                .padding(.vertical, 10)
                .background(CSColor.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: CSRadius.sm)
                        .stroke(CSColor.borderSubtle, lineWidth: 0.5)
                )
                .padding(.horizontal, CSSpacing.md)
                .padding(.bottom, CSSpacing.md)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: CSSpacing.sm) {
            Button {
                if isCollectionLimitReached {
                    appState.presentPaywall(source: .featureLimit)
                    return
                }
                withAnimation(.spring(response: 0.3)) {
                    appState.addToCollection(card)
                    isAddedToCollection = true
                    showCheckmark = true
                }
            } label: {
                HStack(spacing: CSSpacing.sm) {
                    Image(systemName: isAddedToCollection ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text(addButtonTitle)
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

    private var lockedPriceBox: some View {
        VStack(alignment: .leading, spacing: CSSpacing.sm) {
            HStack(spacing: 6) {
                Text("💰")
                Text("Market Price (Pro)")
                    .font(CSFont.body(.bold))
            }

            Text("Free plan shows basic card info only. Upgrade to unlock full valuation and trend data.")
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

    private var addButtonTitle: String {
        if isAddedToCollection { return "Added" }
        if isCollectionLimitReached { return "Free max: 20 cards" }
        return "Add to Collection"
    }

    private var isCollectionLimitReached: Bool {
        !appState.subscription.canAddToCollection(currentCount: appState.collectionCards.count)
    }

    private var rawRange: ClosedRange<Int> {
        priceData?.rawRange ?? (card.rawPriceLow ... card.rawPriceHigh)
    }

    private var psa9Range: ClosedRange<Int> {
        priceData?.psa9Range ?? (card.psa9PriceLow ... card.psa9PriceHigh)
    }

    private var psa10Range: ClosedRange<Int> {
        priceData?.psa10Range ?? (card.psa10PriceLow ... card.psa10PriceHigh)
    }
}

struct CardNotFoundView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: CSSpacing.xl) {
            Spacer()
            Image("CardNotFoundState")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320)
            Text("Card Not Found")
                .font(CSFont.title(.bold))
                .foregroundStyle(CSColor.textPrimary)
            Text("We couldn’t identify this card. Try again with better lighting or a clearer photo.")
                .font(CSFont.body())
                .foregroundStyle(CSColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CSSpacing.lg)
            if let ocr = appState.latestExtractedText, !ocr.isEmpty {
                HStack(alignment: .top, spacing: CSSpacing.sm) {
                    Image(systemName: "text.viewfinder")
                        .foregroundStyle(CSColor.signalPrimary)
                    Text(ocr)
                        .font(.system(size: 11))
                        .foregroundStyle(CSColor.textTertiary)
                        .lineLimit(4)
                }
                .padding(.horizontal, CSSpacing.md)
                .padding(.vertical, 10)
                .background(CSColor.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: CSRadius.sm)
                        .stroke(CSColor.borderSubtle, lineWidth: 0.5)
                )
                .padding(.horizontal, CSSpacing.lg)
            }
            Button {
                appState.showingResult = false
                appState.showingScan = true
            } label: {
                Text("Try Again")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, CSSpacing.xl)
            Spacer()
        }
        .background(CSColor.surfacePrimary)
        .preferredColorScheme(.dark)
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
