import SwiftUI
import SwiftData
import UIKit

private let onboardingKey = "CardScope.hasSeenOnboarding"

@Observable
final class AppState {
    /// 是否已完成引导；用存储属性以便 @Observable 能追踪，界面才能响应重置
    var hasSeenOnboarding: Bool = UserDefaults.standard.bool(forKey: onboardingKey) {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: onboardingKey) }
    }

    var selectedTab: TabItem = .home
    var showingScan = false
    var showingPaywall = false
    var activePaywallSource: PaywallSource = .profile
    var showingResult = false
    var scannedCard: SportsCard?
    var selectedDetailCard: SportsCard?
    var showingDetail = false
    var showingGrade = false
    var gradeCard: SportsCard?
    var latestScanImage: UIImage?
    var latestExtractedText: String?
    var latestGradeBreakdown: GradeBreakdown?
    var isLoading = false
    var errorMessage: String?
    let subscription = SubscriptionState()

    var collectionCards: [SportsCard] = []
    var recentScans: [SportsCard] = []
    var trendingCards: [SportsCard] = []
    var trendingPlayers: [Player] = []
    var popularSeries: [PopularSeries] = []
    var monthlyChange: Double = 0

    var totalValue: Int {
        collectionCards.reduce(0) { $0 + $1.currentPrice }
    }

    var totalCards: Int { collectionCards.count }

    @MainActor
    func bootstrap(context: ModelContext?) async {
        isLoading = true
        defer { isLoading = false }
        await refreshHomeData(context: context)
        await refreshCollection(context: context)
    }

    @MainActor
    func refreshHomeData(context: ModelContext?) async {
        let cards = await CardService.shared.fetchAllCards(context: context)
        recentScans = Array(cards.prefix(6))
        trendingCards = await CardService.shared.fetchTrendingCards(context: context)
        trendingPlayers = await PlayerService.shared.fetchTrendingPlayers(context: context)
        popularSeries = await CardService.shared.fetchPopularSeries()
        monthlyChange = await PriceService.shared.thisMonthGrowth(collection: cards)
    }

    @MainActor
    func refreshCollection(context: ModelContext?) async {
        let cards = await CardService.shared.fetchAllCards(context: context)
        if collectionCards.isEmpty {
            collectionCards = cards
        }
        if recentScans.isEmpty {
            recentScans = cards
        }
    }

    @MainActor
    func scan(image: UIImage, context: ModelContext?) async {
        isLoading = true
        defer { isLoading = false }
        latestScanImage = image
        let result = await ScanService.shared.identifyCard(from: image)
        latestExtractedText = result.extractedText
        scannedCard = result.matchedCard
        showingResult = true
        if let card = result.matchedCard {
            subscription.recordSuccessfulScan()
            if !recentScans.contains(where: { $0.id == card.id }) {
                recentScans.insert(card, at: 0)
            }
            CardService.shared.addScanToHistory(card: card)
            if let context {
                try? CacheManager.shared.upsertCards([card], context: context)
            }
        }
    }

    /// 模拟扫描未识别到卡片（用于展示 CardNotFoundView）
    func simulateScanNoResult() {
        scannedCard = nil
        showingResult = true
    }

    func addToCollection(_ card: SportsCard) {
        guard subscription.canAddToCollection(currentCount: collectionCards.count) else {
            presentPaywall(source: .featureLimit)
            return
        }
        if !collectionCards.contains(where: { $0.id == card.id }) {
            collectionCards.append(card)
        }
    }

    func canStartScanFlow() -> Bool {
        guard subscription.canScanToday() else {
            presentPaywall(source: .featureLimit)
            return false
        }
        return true
    }

    func presentPaywall(source: PaywallSource) {
        activePaywallSource = source
        showingPaywall = true
    }

    @MainActor
    func analyzeGrade() async {
        guard let latestScanImage else { return }
        latestGradeBreakdown = await GradeService.shared.analyze(image: latestScanImage)
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
    }
}

enum TabItem: Int, CaseIterable {
    case home, explore, scan, collection, profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .explore: return "Explore"
        case .scan: return "Scan"
        case .collection: return "Collection"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "magnifyingglass"
        case .scan: return "camera.fill"
        case .collection: return "square.grid.2x2.fill"
        case .profile: return "person.fill"
        }
    }
}
