import SwiftUI

@Observable
final class AppState {
    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "CardScope.hasSeenOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "CardScope.hasSeenOnboarding") }
    }

    var selectedTab: TabItem = .home
    var showingScan = false
    var showingPaywall = false
    var showingResult = false
    var scannedCard: SportsCard?
    var selectedDetailCard: SportsCard?
    var showingDetail = false
    var showingGrade = false
    var gradeCard: SportsCard?

    var collectionCards: [SportsCard] = MockData.allCards
    var recentScans: [SportsCard] = MockData.allCards

    var totalValue: Int {
        collectionCards.reduce(0) { $0 + $1.currentPrice }
    }

    var totalCards: Int { collectionCards.count }

    func simulateScan() {
        let card = MockData.allCards.randomElement() ?? MockData.lukaDoncic
        scannedCard = card
        showingResult = true
    }

    func addToCollection(_ card: SportsCard) {
        collectionCards.append(card)
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
