import Foundation
import SwiftData

@MainActor
final class CardService {
    static let shared = CardService()

    private let supabase = SupabaseClient.shared
    private let cache = CacheManager.shared

    private init() {}

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

    func addScanToHistory(card: SportsCard) {
        // Hook point for Supabase scan_history table sync.
        _ = card
    }
}
