import Foundation
import SwiftData

@MainActor
final class CardService {
    static let shared = CardService()

    private let supabase = SupabaseClient.shared
    private let cache = CacheManager.shared

    private init() {}

    private struct PopularSeriesRow: Decodable {
        let brand: String
        let setName: String
        let year: String
        let cardCount: Int
    }

    private struct TrendingCardRefRow: Decodable {
        let cardId: UUID
    }

    func fetchAllCards(context: ModelContext?) async -> [SportsCard] {
        if supabase.isConfigured {
            do {
                let remote: [SportsCard] = try await supabase.select(table: "cards", limit: 200)
                if !remote.isEmpty, let context {
                    try cache.upsertCards(remote, context: context)
                }
                if !remote.isEmpty { return remote }
            } catch {
                // Fall through to local cache/mock data.
            }
        }

        if let context, let cached = try? cache.fetchCards(context: context), !cached.isEmpty {
            return cached
        }
        return MockData.allCards
    }

    func searchCards(query: String, context: ModelContext?) async -> [SportsCard] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return await fetchAllCards(context: context)
        }

        if supabase.isConfigured {
            do {
                let filters = [
                    SupabaseQueryFilter.ilike("player_name", "*\(trimmed)*"),
                ]
                let remote: [SportsCard] = try await supabase.select(
                    table: "cards",
                    filters: filters,
                    limit: 40
                )
                if !remote.isEmpty, let context {
                    try cache.upsertCards(remote, context: context)
                }
                if !remote.isEmpty { return remote }
            } catch {
                // Ignore and fallback
            }
        }

        let local = await fetchAllCards(context: context)
        return local.filter {
            $0.playerName.localizedCaseInsensitiveContains(trimmed)
                || $0.brand.localizedCaseInsensitiveContains(trimmed)
                || $0.setName.localizedCaseInsensitiveContains(trimmed)
                || $0.year.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func fetchPopularSeries() async -> [PopularSeries] {
        guard supabase.isConfigured else { return [] }
        do {
            let rows: [PopularSeriesRow] = try await supabase.select(
                table: "popular_series_view",
                limit: 30
            )
            return rows.map {
                PopularSeries(
                    brand: $0.brand,
                    setName: $0.setName,
                    year: $0.year,
                    cardCount: $0.cardCount
                )
            }
        } catch {
            return []
        }
    }

    func fetchTrendingCards(context: ModelContext?) async -> [SportsCard] {
        if supabase.isConfigured {
            do {
                let refs: [TrendingCardRefRow] = try await supabase.select(
                    table: "trending_players_view",
                    columns: "card_id",
                    limit: 20
                )
                let orderedIds = refs.map(\.cardId)
                if !orderedIds.isEmpty {
                    let quotedIds = orderedIds.map { "\"\($0.uuidString.lowercased())\"" }
                    let filters = [SupabaseQueryFilter.inValues("id", quotedIds)]
                    let remoteCards: [SportsCard] = try await supabase.select(
                        table: "cards",
                        filters: filters,
                        limit: orderedIds.count
                    )
                    let cardMap = Dictionary(uniqueKeysWithValues: remoteCards.map { ($0.supabaseId ?? $0.id, $0) })
                    let orderedCards = orderedIds.compactMap { cardMap[$0] }
                    if !orderedCards.isEmpty {
                        if let context {
                            try? cache.upsertCards(orderedCards, context: context)
                        }
                        return orderedCards
                    }
                }
            } catch {
                // fallback below
            }
        }

        let allCards = await fetchAllCards(context: context)
        return Array(allCards.sorted(by: { $0.priceChange > $1.priceChange }).prefix(5))
    }

    func addScanToHistory(card: SportsCard) {
        // Hook point for Supabase scan_history table sync.
        _ = card
    }
}
