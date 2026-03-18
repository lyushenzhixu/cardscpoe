import Foundation
import SwiftData

@MainActor
final class CardService {
    static let shared = CardService()

    private let supabase = SupabaseClient.shared
    private let cache = CacheManager.shared

    private init() {}

    /// 视图行：全部可选 + 缺键默认值，避免 Supabase 返回缺字段时解码失败
    /// View row: all optional with defaults to survive missing fields from Supabase.
    /// CodingKeys use camelCase to match NetworkManager's convertFromSnakeCase strategy.
    private struct PopularSeriesRow: Decodable {
        let brand: String?
        let setName: String?
        let year: String?
        let cardCount: Int?

        enum CodingKeys: String, CodingKey {
            case brand, setName, year, cardCount
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

    /// View row: only reads card_id; handles Supabase string UUID or missing field.
    private struct TrendingCardRefRow: Decodable {
        let cardId: UUID?

        enum CodingKeys: String, CodingKey {
            case cardId  // convertFromSnakeCase: "card_id" → "cardId"
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

    func addScanToHistory(card: SportsCard, extractedText: String = "", context: ModelContext?) {
        guard let context else { return }
        try? cache.insertScanHistory(
            cardId: card.supabaseId ?? card.id,
            extractedText: extractedText,
            context: context
        )
    }

    // MARK: - OCR Candidate Search

    /// Searches Supabase for card candidates using multiple independent queries.
    /// Each query is simple (single ilike filter) to avoid PostgREST decode issues.
    func searchByOCRTokens(
        playerGuesses: [String],
        brandGuesses: [String],
        setGuesses: [String],
        yearGuesses: [String],
        context: ModelContext?
    ) async -> [SportsCard] {
        guard supabase.isConfigured else {
            return await fetchAllCards(context: context)
        }

        var allCandidates: [SportsCard] = []

        // Strategy 1: Search by player name guesses (highest signal)
        for name in playerGuesses.prefix(3) {
            // Split multi-word name into individual words for broader matching
            let words = name.split(separator: " ").map(String.init).filter { $0.count >= 3 }
            for word in words.prefix(2) {
                do {
                    let results: [SportsCard] = try await supabase.select(
                        table: "cards",
                        filters: [.ilike("player_name", "*\(word)*")],
                        limit: 30
                    )
                    allCandidates.append(contentsOf: results)
                    #if DEBUG
                    print("[CardService] Player word '\(word)' → \(results.count) results")
                    #endif
                    if !results.isEmpty { break } // Found matches, skip remaining words
                } catch {
                    #if DEBUG
                    print("[CardService] Player search '\(word)' failed: \(error)")
                    #endif
                }
            }
            if !allCandidates.isEmpty { break } // Found matches, skip remaining guesses
        }

        // Strategy 2: Search by brand + year (simple filter, no OR needed)
        if allCandidates.isEmpty, let brand = brandGuesses.first, let year = yearGuesses.first {
            do {
                let results: [SportsCard] = try await supabase.select(
                    table: "cards",
                    filters: [
                        .ilike("brand", "*\(brand)*"),
                        .eq("year", year)
                    ],
                    limit: 50
                )
                allCandidates.append(contentsOf: results)
                #if DEBUG
                print("[CardService] Brand+Year '\(brand)/\(year)' → \(results.count) results")
                #endif
            } catch {
                #if DEBUG
                print("[CardService] Brand+Year search failed: \(error)")
                #endif
            }
        }

        // Strategy 3: Search by set name + year
        if allCandidates.isEmpty, let setName = setGuesses.first, let year = yearGuesses.first {
            do {
                let results: [SportsCard] = try await supabase.select(
                    table: "cards",
                    filters: [
                        .ilike("set_name", "*\(setName)*"),
                        .eq("year", year)
                    ],
                    limit: 50
                )
                allCandidates.append(contentsOf: results)
                #if DEBUG
                print("[CardService] Set+Year '\(setName)/\(year)' → \(results.count) results")
                #endif
            } catch {
                #if DEBUG
                print("[CardService] Set+Year search failed: \(error)")
                #endif
            }
        }

        // Deduplicate
        var seen = Set<UUID>()
        let unique = allCandidates.filter { card in
            let key = card.supabaseId ?? card.id
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        #if DEBUG
        print("[CardService] OCR search → \(unique.count) unique candidates (from \(allCandidates.count) total)")
        #endif

        if !unique.isEmpty, let context {
            try? cache.upsertCards(unique, context: context)
        }

        // Fallback to all cards if server returned nothing
        if unique.isEmpty {
            #if DEBUG
            print("[CardService] No server results, falling back to fetchAllCards")
            #endif
            return await fetchAllCards(context: context)
        }

        return unique
    }
}
