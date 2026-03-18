import SwiftUI
import SwiftData

/// Provides a pre-populated AppState for SwiftUI Previews.
extension AppState {
    static var preview: AppState {
        let state = AppState()
        state.hasSeenOnboarding = true
        state.collectionCards = MockData.allCards
        state.recentScans = Array(MockData.allCards.prefix(4))
        state.trendingCards = MockData.allCards
        state.trendingPlayers = [
            Player(name: "Luka Dončić", sport: .basketball, team: "Dallas Mavericks", position: "PG"),
            Player(name: "Shohei Ohtani", sport: .baseball, team: "Los Angeles Angels", position: "P/DH"),
            Player(name: "Patrick Mahomes", sport: .football, team: "Kansas City Chiefs", position: "QB"),
            Player(name: "Victor Wembanyama", sport: .basketball, team: "San Antonio Spurs", position: "C"),
            Player(name: "Jude Bellingham", sport: .soccer, team: "Real Madrid", position: "MF"),
        ]
        state.popularSeries = [
            PopularSeries(brand: "Panini", setName: "Prizm", year: "2023", cardCount: 300),
            PopularSeries(brand: "Topps", setName: "Chrome", year: "2023", cardCount: 220),
            PopularSeries(brand: "Panini", setName: "Select", year: "2023", cardCount: 250),
        ]
        state.monthlyChange = 5.2
        state.latestConfidenceLevel = .strong
        state.latestGradeBreakdown = GradeBreakdown(centering: 9.1, corners: 9.0, edges: 8.8, surface: 8.9)
        return state
    }
}

/// Wraps a view with the required environment for previews (AppState + ModelContainer).
struct PreviewContainer<Content: View>: View {
    let appState: AppState
    let content: () -> Content

    init(appState: AppState = .preview, @ViewBuilder content: @escaping () -> Content) {
        self.appState = appState
        self.content = content
    }

    var body: some View {
        content()
            .environment(appState)
            .modelContainer(previewContainer)
            .preferredColorScheme(.dark)
    }
}

@MainActor
let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: StoredCard.self, StoredPlayer.self, StoredScanHistory.self,
        configurations: config
    )
    return container
}()
