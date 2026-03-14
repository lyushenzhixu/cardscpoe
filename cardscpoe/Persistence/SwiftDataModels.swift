import Foundation
import SwiftData

@Model
final class StoredCard {
    @Attribute(.unique) var id: UUID
    var supabaseId: UUID?
    var playerName: String
    var team: String
    var position: String
    var sportRaw: String
    var brand: String
    var setName: String
    var year: String
    var cardNumber: String
    var parallel: String
    var isRookie: Bool
    var rawPriceLow: Int
    var rawPriceHigh: Int
    var psa9PriceLow: Int
    var psa9PriceHigh: Int
    var psa10PriceLow: Int
    var psa10PriceHigh: Int
    var currentPrice: Int
    var priceChange: Double
    var confidence: Double
    var grade: String?
    var imageURL: String?
    var headshotURL: String?
    var updatedAt: Date

    init(from card: SportsCard, updatedAt: Date = .now) {
        id = card.id
        supabaseId = card.supabaseId
        playerName = card.playerName
        team = card.team
        position = card.position
        sportRaw = card.sport.rawValue
        brand = card.brand
        setName = card.setName
        year = card.year
        cardNumber = card.cardNumber
        parallel = card.parallel
        isRookie = card.isRookie
        rawPriceLow = card.rawPriceLow
        rawPriceHigh = card.rawPriceHigh
        psa9PriceLow = card.psa9PriceLow
        psa9PriceHigh = card.psa9PriceHigh
        psa10PriceLow = card.psa10PriceLow
        psa10PriceHigh = card.psa10PriceHigh
        currentPrice = card.currentPrice
        priceChange = card.priceChange
        confidence = card.confidence
        grade = card.grade
        imageURL = card.imageURL?.absoluteString
        headshotURL = card.headshotURL?.absoluteString
        self.updatedAt = updatedAt
    }

    var asSportsCard: SportsCard {
        SportsCard(
            id: id,
            supabaseId: supabaseId,
            playerName: playerName,
            team: team,
            position: position,
            sport: SportType(rawValue: sportRaw) ?? .basketball,
            brand: brand,
            setName: setName,
            year: year,
            cardNumber: cardNumber,
            parallel: parallel,
            isRookie: isRookie,
            rawPriceLow: rawPriceLow,
            rawPriceHigh: rawPriceHigh,
            psa9PriceLow: psa9PriceLow,
            psa9PriceHigh: psa9PriceHigh,
            psa10PriceLow: psa10PriceLow,
            psa10PriceHigh: psa10PriceHigh,
            currentPrice: currentPrice,
            priceChange: priceChange,
            confidence: confidence,
            grade: grade,
            imageURL: imageURL.flatMap(URL.init(string:)),
            headshotURL: headshotURL.flatMap(URL.init(string:))
        )
    }
}

@Model
final class StoredPlayer {
    @Attribute(.unique) var id: UUID
    var supabaseId: UUID?
    var name: String
    var sportRaw: String
    var team: String
    var position: String
    var headshotURL: String?
    var bio: String?
    var updatedAt: Date

    init(from player: Player, updatedAt: Date = .now) {
        id = player.id
        supabaseId = player.supabaseId
        name = player.name
        sportRaw = player.sport.rawValue
        team = player.team
        position = player.position
        headshotURL = player.headshotURL?.absoluteString
        bio = player.bio
        self.updatedAt = updatedAt
    }

    var asPlayer: Player {
        Player(
            id: id,
            supabaseId: supabaseId,
            name: name,
            sport: SportType(rawValue: sportRaw) ?? .basketball,
            team: team,
            position: position,
            headshotURL: headshotURL.flatMap(URL.init(string:)),
            bio: bio
        )
    }
}

@Model
final class StoredScanHistory {
    @Attribute(.unique) var id: UUID
    var scannedAt: Date
    var cardId: UUID?
    var extractedText: String
    var imagePath: String?

    init(id: UUID = UUID(), scannedAt: Date = .now, cardId: UUID?, extractedText: String, imagePath: String?) {
        self.id = id
        self.scannedAt = scannedAt
        self.cardId = cardId
        self.extractedText = extractedText
        self.imagePath = imagePath
    }
}
