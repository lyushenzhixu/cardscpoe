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
    @State private var selectedGrade: CardGrade = .raw

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBar
                cardDisplay
                playerInfo
                chips
                if appState.latestConfidenceLevel == .weak {
                    weakMatchBanner
                }
                if appState.latestScanMode == .normal {
                    gradePicker
                }
                if appState.latestScanMode == .ai {
                    aiGradeBreakdownSection
                }
                if appState.subscription.hasFullValuation() {
                    selectedPriceBox
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
            if appState.latestScanMode == .ai, let breakdown = appState.latestGradeBreakdown {
                selectedGrade = breakdown.estimatedGrade
            }
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

            confidenceBadge
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private var weakMatchBanner: some View {
        HStack(spacing: CSSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(CSColor.signalGold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Low confidence match")
                    .font(CSFont.caption(.bold))
                    .foregroundStyle(CSColor.signalGold)
                Text("This might not be the correct card. Please verify the details above.")
                    .font(.system(size: 11))
                    .foregroundStyle(CSColor.textTertiary)
            }
            Spacer()
        }
        .padding(CSSpacing.sm)
        .background(CSColor.signalGold.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.sm)
                .stroke(CSColor.signalGold.opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private var confidenceBadge: some View {
        let level = appState.latestConfidenceLevel
        let badgeColor: Color = switch level {
        case .strong: CSColor.signalPrimary
        case .moderate: CSColor.signalTertiary
        case .weak: CSColor.signalGold
        case .none: CSColor.textTertiary
        }
        return HStack(spacing: 6) {
            Image(systemName: level.icon)
                .font(.system(size: 12))
            Text(level.label)
                .font(CSFont.caption(.bold))
            Text("· \(String(format: "%.0f", card.confidence))%")
                .font(CSFont.caption(.bold))
                .monospacedDigit()
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, 6)
        .background(badgeColor.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(badgeColor.opacity(0.15), lineWidth: 0.5))
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

    // MARK: - Grade Picker (Normal Mode)

    private var gradePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CardGrade.allCases) { grade in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedGrade = grade
                        }
                    } label: {
                        Text(grade.label)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selectedGrade == grade ? .black : CSColor.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedGrade == grade ? CSColor.signalPrimary : CSColor.surfaceElevated)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(selectedGrade == grade ? CSColor.signalPrimary : CSColor.border, lineWidth: 0.5)
                            )
                    }
                }
            }
            .padding(.horizontal, CSSpacing.md)
        }
        .padding(.bottom, CSSpacing.md)
    }

    // MARK: - AI Grade Breakdown (AI Mode)

    private var aiGradeBreakdownSection: some View {
        let breakdown = appState.latestGradeBreakdown ?? GradeBreakdown(centering: 9.1, corners: 9.0, edges: 8.8, surface: 8.9)
        return VStack(spacing: 0) {
            HStack {
                HStack(spacing: CSSpacing.sm) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(CSColor.signalPrimary)
                    Text("AI Grade")
                        .font(CSFont.headline(.bold))
                }
                Spacer()
                Text(String(format: "%.1f", breakdown.overall))
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .foregroundStyle(CSColor.signalPrimary)
            }
            .padding(.bottom, CSSpacing.xs)

            Text("Estimated \(selectedGrade.label) · /10")
                .font(CSFont.caption())
                .foregroundStyle(CSColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, CSSpacing.md)

            gradeBarRow(label: "Centering", value: breakdown.centering / 10, score: String(format: "%.1f", breakdown.centering), color: CSColor.signalPrimary)
            gradeBarRow(label: "Corners", value: breakdown.corners / 10, score: String(format: "%.1f", breakdown.corners), color: CSColor.signalPrimary)
            gradeBarRow(label: "Edges", value: breakdown.edges / 10, score: String(format: "%.1f", breakdown.edges), color: CSColor.signalTertiary)
            gradeBarRow(label: "Surface", value: breakdown.surface / 10, score: String(format: "%.1f", breakdown.surface), color: CSColor.signalPrimary)
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

    private func gradeBarRow(label: String, value: Double, score: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(CSFont.caption())
                    .foregroundStyle(CSColor.textSecondary)
                Spacer()
                Text(score)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.04))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * value)
                }
            }
            .frame(height: 4)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Selected Price Box

    private var selectedPriceBox: some View {
        let range = priceRangeForGrade(selectedGrade)
        return VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(CSColor.signalPrimary)
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

            HStack {
                Text(selectedGrade.label)
                    .font(CSFont.caption())
                    .foregroundStyle(CSColor.textSecondary)
                Spacer()
                Text("$\(range.lowerBound) – $\(range.upperBound)")
                    .font(CSFont.data(.bold))
                    .foregroundStyle(CSColor.signalPrimary)
            }
            .padding(.vertical, 10)
        }
        .nyxCard()
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private func priceRangeForGrade(_ grade: CardGrade) -> ClosedRange<Int> {
        if let priceData {
            return priceData.priceRange(for: grade)
        }
        return card.priceRange(for: grade)
    }

    private var demandBar: some View {
        HStack {
            HStack(spacing: CSSpacing.sm) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14))
                    .foregroundStyle(CSColor.signalPrimary)
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
                VStack(alignment: .leading, spacing: CSSpacing.sm) {
                    HStack(alignment: .top, spacing: CSSpacing.sm) {
                        Image(systemName: "text.viewfinder")
                            .foregroundStyle(CSColor.signalPrimary)
                        Text(text)
                            .font(.system(size: 11))
                            .foregroundStyle(CSColor.textTertiary)
                            .lineLimit(3)
                    }
                    #if DEBUG
                    if let debug = appState.latestScanDebugInfo, !debug.isEmpty {
                        Divider().background(CSColor.borderSubtle)
                        Text(debug)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CSColor.textTertiary.opacity(0.7))
                            .lineLimit(8)
                    }
                    #endif
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
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(CSColor.signalPrimary)
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

            VStack(spacing: CSSpacing.sm) {
                Text("We couldn’t identify this card.")
                    .font(CSFont.body())
                    .foregroundStyle(CSColor.textSecondary)

                VStack(alignment: .leading, spacing: 6) {
                    tipRow(icon: "sun.max", text: "Ensure good, even lighting")
                    tipRow(icon: "camera.viewfinder", text: "Center the card in the frame")
                    tipRow(icon: "text.magnifyingglass", text: "Make sure text on card is visible")
                }
                .padding(.horizontal, CSSpacing.lg)
            }

            if let ocr = appState.latestExtractedText, !ocr.isEmpty {
                VStack(alignment: .leading, spacing: CSSpacing.sm) {
                    HStack(alignment: .top, spacing: CSSpacing.sm) {
                        Image(systemName: "text.viewfinder")
                            .foregroundStyle(CSColor.signalPrimary)
                        Text(ocr)
                            .font(.system(size: 11))
                            .foregroundStyle(CSColor.textTertiary)
                            .lineLimit(4)
                    }
                    #if DEBUG
                    if let debug = appState.latestScanDebugInfo, !debug.isEmpty {
                        Divider().background(CSColor.borderSubtle)
                        Text(debug)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(CSColor.textTertiary.opacity(0.7))
                            .lineLimit(8)
                    }
                    #endif
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

            HStack(spacing: CSSpacing.sm) {
                Button {
                    appState.showingResult = false
                    appState.showingScan = true
                } label: {
                    Text("Try Again")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    appState.showingResult = false
                    appState.selectedTab = .explore
                } label: {
                    Text("Search Manually")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, CSSpacing.xl)
            Spacer()
        }
        .background(CSColor.surfacePrimary)
        .preferredColorScheme(.dark)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: CSSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(CSColor.signalPrimary)
                .frame(width: 20)
            Text(text)
                .font(CSFont.caption())
                .foregroundStyle(CSColor.textTertiary)
        }
    }
}

#Preview("ScanResultView – Normal") {
    PreviewContainer {
        NavigationStack {
            ScanResultView(card: MockData.lukaDoncic)
        }
    }
}

#Preview("ScanResultView – AI") {
    let state = AppState.preview
    state.latestScanMode = .ai
    state.latestGradeBreakdown = GradeBreakdown(centering: 9.1, corners: 9.0, edges: 8.8, surface: 8.9)
    return PreviewContainer(appState: state) {
        NavigationStack {
            ScanResultView(card: MockData.lukaDoncic)
        }
    }
}

#Preview("CardNotFoundView") {
    PreviewContainer {
        NavigationStack {
            CardNotFoundView()
        }
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
