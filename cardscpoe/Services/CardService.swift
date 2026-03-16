import Foundation
import SwiftData

@MainActor
final class CardService {
    static let shared = CardService()

    private let supabase = SupabaseClient.shared
    private let cache = CacheManager.shared

    private init() {}

    /// 视图行：全部可选 + 缺键默认值，避免 Supabase 返回缺字段时解码失败
    private struct PopularSeriesRow: Decodable {
        let brand: String?
        let setName: String?
        let year: String?
        let cardCount: Int?

        enum CodingKeys: String, CodingKey {
            case brand
            case setName = "set_name"
            case year
            case cardCount = "card_count"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            brand = try c.decodeIfPresent(String.self, forKey: .brand)
            setName = try c.decodeIfPresent(String.self, forKey: .setName)
            cardCount = try c.decodeIfPresent(Int.self, forKey: .cardCount)
            if let y = try c.decodeIfPresent(String.self, forKey: .year) {
                year = y
            } else if let n = try c.decodeIfPresent(Int.self, forKey: .year) {
                year = String(n)
            } else {
                year = nil
            }
        }
    }

    /// 视图行只取 card_id；兼容 Supabase 返回的字符串 UUID 或缺失字段
    private struct TrendingCardRefRow: Decodable {
        let cardId: UUID?

        enum CodingKeys: String, CodingKey {
            case cardId = "card_id"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            if let uuid = try? c.decodeIfPresent(UUID.self, forKey: .cardId) {
                cardId = uuid
            } else if let str = try? c.decodeIfPresent(String.self, forKey: .cardId), !str.isEmpty {
                cardId = UUID(uuidString: str)
            } else {
                cardId = nil
            }
        }
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

    func fetchPopularSeries() async throws -> [PopularSeries] {
        guard supabase.isConfigured else { return [] }
        do {
            let rows: [PopularSeriesRow] = try await supabase.select(
                table: "popular_series_view",
                limit: 30
            )
            return rows.compactMap { row in
                let b = row.brand ?? ""
                let s = row.setName ?? ""
                guard !b.isEmpty || !s.isEmpty else { return nil }
                return PopularSeries(
                    brand: b,
                    setName: s,
                    year: row.year ?? "Unknown",
                    cardCount: row.cardCount ?? 0
                )
            }
        } catch {
            #if DEBUG
            if let raw = try? await supabase.selectRaw(table: "popular_series_view", limit: 30),
               let str = String(data: raw, encoding: .utf8) {
                print("[CardService] popular_series_view raw response: \(str.prefix(500))")
            }
            #endif
            throw error
        }
    }

    func fetchTrendingCards(context: ModelContext?) async throws -> [SportsCard] {
        guard supabase.isConfigured else {
            let allCards = await fetchAllCards(context: context)
            return Array(allCards.sorted(by: { $0.priceChange > $1.priceChange }).prefix(5))
        }
        let refs: [TrendingCardRefRow]
        do {
            refs = try await supabase.select(
                table: "trending_players_view",
                columns: "card_id",
                limit: 20
            )
        } catch {
            #if DEBUG
            if let raw = try? await supabase.selectRaw(table: "trending_players_view", columns: "card_id", limit: 20),
               let str = String(data: raw, encoding: .utf8) {
                print("[CardService] trending_players_view (card_id) raw: \(str.prefix(500))")
            }
            #endif
            // View shape may differ across environments; fall back to cards table ordering.
            let fallbackRemote: [SportsCard] = try await supabase.select(
                table: "cards",
                columns: "*",
                filters: [SupabaseQueryFilter.gt("current_price", "0")],
                order: "price_change.desc.nullslast,current_price.desc",
                limit: 5
            )
            if !fallbackRemote.isEmpty, let context {
                try? cache.upsertCards(fallbackRemote, context: context)
            }
            if !fallbackRemote.isEmpty { return fallbackRemote }
            throw error
        }
        let orderedIds = refs.compactMap(\.cardId)
        guard !orderedIds.isEmpty else {
            let fallbackRemote: [SportsCard] = try await supabase.select(
                table: "cards",
                columns: "*",
                filters: [SupabaseQueryFilter.gt("current_price", "0")],
                order: "price_change.desc.nullslast,current_price.desc",
                limit: 5
            )
            if !fallbackRemote.isEmpty, let context {
                try? cache.upsertCards(fallbackRemote, context: context)
            }
            if !fallbackRemote.isEmpty { return fallbackRemote }
            let allCards = await fetchAllCards(context: context)
            return Array(allCards.sorted(by: { $0.priceChange > $1.priceChange }).prefix(5))
        }
        let quotedIds = orderedIds.map { "\"\($0.uuidString.lowercased())\"" }
        let filters = [SupabaseQueryFilter.inValues("id", quotedIds)]
        let remoteCards: [SportsCard] = try await supabase.select(
            table: "cards",
            filters: filters,
            limit: orderedIds.count
        )
        let cardMap = Dictionary(uniqueKeysWithValues: remoteCards.map { ($0.supabaseId ?? $0.id, $0) })
        let orderedCards = orderedIds.compactMap { cardMap[$0] }
        if !orderedCards.isEmpty, let context {
            try? cache.upsertCards(orderedCards, context: context)
        }
        if !orderedCards.isEmpty {
            return orderedCards
        }
        let allCards = await fetchAllCards(context: context)
        return Array(allCards.sorted(by: { $0.priceChange > $1.priceChange }).prefix(5))
    }

    func addScanToHistory(card: SportsCard) {
        // Hook point for Supabase scan_history table sync.
        _ = card
    }
}
