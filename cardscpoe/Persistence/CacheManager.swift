import Foundation
import SwiftData

@MainActor
final class CacheManager {
    static let shared = CacheManager()

    private init() {}

    func upsertCards(_ cards: [SportsCard], context: ModelContext) throws {
        for card in cards {
            let descriptor = FetchDescriptor<StoredCard>(predicate: #Predicate { $0.id == card.id })
            if let existing = try context.fetch(descriptor).first {
                existing.supabaseId = card.supabaseId
                existing.playerName = card.playerName
                existing.team = card.team
                existing.position = card.position
                existing.sportRaw = card.sport.rawValue
                existing.brand = card.brand
                existing.setName = card.setName
                existing.year = card.year
                existing.cardNumber = card.cardNumber
                existing.parallel = card.parallel
                existing.isRookie = card.isRookie
                existing.rawPriceLow = card.rawPriceLow
                existing.rawPriceHigh = card.rawPriceHigh
                existing.psa9PriceLow = card.psa9PriceLow
                existing.psa9PriceHigh = card.psa9PriceHigh
                existing.psa10PriceLow = card.psa10PriceLow
                existing.psa10PriceHigh = card.psa10PriceHigh
                existing.currentPrice = card.currentPrice
                existing.priceChange = card.priceChange
                existing.confidence = card.confidence
                existing.grade = card.grade
                existing.imageURL = card.imageURL?.absoluteString
                existing.headshotURL = card.headshotURL?.absoluteString
                existing.updatedAt = .now
            } else {
                context.insert(StoredCard(from: card))
            }
        }
        try context.save()
    }

    func fetchCards(context: ModelContext, limit: Int? = nil) throws -> [SportsCard] {
        var descriptor = FetchDescriptor<StoredCard>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map(\.asSportsCard)
    }

    func upsertPlayers(_ players: [Player], context: ModelContext) throws {
        for player in players {
            let descriptor = FetchDescriptor<StoredPlayer>(predicate: #Predicate { $0.id == player.id })
            if let existing = try context.fetch(descriptor).first {
                existing.supabaseId = player.supabaseId
                existing.name = player.name
                existing.sportRaw = player.sport.rawValue
                existing.team = player.team
                existing.position = player.position
                existing.headshotURL = player.headshotURL?.absoluteString
                existing.bio = player.bio
                existing.updatedAt = .now
            } else {
                context.insert(StoredPlayer(from: player))
            }
        }
        try context.save()
    }

    // MARK: - Scan History

    func insertScanHistory(cardId: UUID?, extractedText: String, imagePath: String? = nil, context: ModelContext) throws {
        let entry = StoredScanHistory(cardId: cardId, extractedText: extractedText, imagePath: imagePath)
        context.insert(entry)
        try context.save()
    }

    func fetchScanHistory(context: ModelContext, limit: Int = 50) throws -> [StoredScanHistory] {
        var descriptor = FetchDescriptor<StoredScanHistory>(
            sortBy: [SortDescriptor(\.scannedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    // MARK: - Players

    func fetchPlayers(context: ModelContext, sport: SportType? = nil) throws -> [Player] {
        let descriptor: FetchDescriptor<StoredPlayer>
        if let sport {
            descriptor = FetchDescriptor<StoredPlayer>(
                predicate: #Predicate { $0.sportRaw == sport.rawValue },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<StoredPlayer>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
        }
        return try context.fetch(descriptor).map(\.asPlayer)
    }
}
