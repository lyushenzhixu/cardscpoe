import SwiftUI

// MARK: - Scan & Grade Enums

enum ScanMode {
    case normal
    case ai
}

enum CardGrade: String, CaseIterable, Identifiable {
    case raw = "Raw"
    case psa7 = "PSA 7"
    case psa8 = "PSA 8"
    case psa9 = "PSA 9"
    case psa10 = "PSA 10"

    var id: String { rawValue }

    var label: String { rawValue }
}

// MARK: - Sport Type

enum SportType: String, CaseIterable, Identifiable, Codable {
    case basketball = "NBA"
    case baseball = "MLB"
    case football = "NFL"
    case soccer = "Soccer"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .basketball: return "basketball.fill"
        case .baseball: return "baseball.fill"
        case .football: return "football.fill"
        case .soccer: return "soccerball"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .basketball: return [Color(red: 0.1, green: 0.16, blue: 0.37), Color(red: 0.05, green: 0.08, blue: 0.16)]
        case .baseball: return [Color(red: 0.35, green: 0.08, blue: 0.08), Color(red: 0.16, green: 0.05, blue: 0.05)]
        case .football: return [Color(red: 0.08, green: 0.22, blue: 0.12), Color(red: 0.05, green: 0.16, blue: 0.1)]
        case .soccer: return [Color(red: 0.15, green: 0.1, blue: 0.3), Color(red: 0.1, green: 0.05, blue: 0.2)]
        }
    }

    var accentColor: Color {
        switch self {
        case .basketball: return Color(red: 0.3, green: 0.5, blue: 1.0)
        case .baseball: return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .football: return Color(red: 0.3, green: 0.8, blue: 0.5)
        case .soccer: return Color(red: 0.6, green: 0.4, blue: 1.0)
        }
    }
}

enum CardType: String, CaseIterable, Codable {
    case base = "Base"
    case rookie = "Rookie"
    case insert = "Insert"
}

struct SportsCard: Identifiable, Codable, Hashable {
    let id: UUID
    let supabaseId: UUID?
    let playerName: String
    let team: String
    let position: String
    let sport: SportType
    let brand: String
    let setName: String
    let year: String
    let cardNumber: String
    let parallel: String
    let isRookie: Bool
    let cardType: CardType
    let rawPriceLow: Int
    let rawPriceHigh: Int
    let psa9PriceLow: Int
    let psa9PriceHigh: Int
    let psa10PriceLow: Int
    let psa10PriceHigh: Int
    let currentPrice: Int
    let priceChange: Double
    let confidence: Double
    let grade: String?
    let imageURL: URL?
    let headshotURL: URL?

    init(
        id: UUID = UUID(),
        supabaseId: UUID? = nil,
        playerName: String,
        team: String,
        position: String,
        sport: SportType,
        brand: String,
        setName: String,
        year: String,
        cardNumber: String,
        parallel: String,
        isRookie: Bool,
        cardType: CardType? = nil,
        rawPriceLow: Int,
        rawPriceHigh: Int,
        psa9PriceLow: Int,
        psa9PriceHigh: Int,
        psa10PriceLow: Int,
        psa10PriceHigh: Int,
        currentPrice: Int,
        priceChange: Double,
        confidence: Double,
        grade: String?,
        imageURL: URL? = nil,
        headshotURL: URL? = nil
    ) {
        self.id = id
        self.supabaseId = supabaseId
        self.playerName = playerName
        self.team = team
        self.position = position
        self.sport = sport
        self.brand = brand
        self.setName = setName
        self.year = year
        self.cardNumber = cardNumber
        self.parallel = parallel
        self.isRookie = isRookie
        self.cardType = cardType ?? (isRookie ? .rookie : .base)
        self.rawPriceLow = rawPriceLow
        self.rawPriceHigh = rawPriceHigh
        self.psa9PriceLow = psa9PriceLow
        self.psa9PriceHigh = psa9PriceHigh
        self.psa10PriceLow = psa10PriceLow
        self.psa10PriceHigh = psa10PriceHigh
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        self.confidence = confidence
        self.grade = grade
        self.imageURL = imageURL
        self.headshotURL = headshotURL
    }

    var formattedCurrentPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: currentPrice)) ?? "\(currentPrice)"
    }

    var priceChangeFormatted: String {
        let sign = priceChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", priceChange))%"
    }

    var priceChangeArrow: String {
        priceChange >= 0 ? "↑" : "↓"
    }

    var setDescription: String {
        let rc = isRookie ? " RC" : ""
        return "\(year) \(brand) \(setName) \(parallel) #\(cardNumber)\(rc)"
    }

    var shortDescription: String {
        let rc = isRookie ? " RC" : ""
        return "\(year) \(setName) \(parallel)\(rc)"
    }

    func priceRange(for grade: CardGrade) -> ClosedRange<Int> {
        switch grade {
        case .raw: return rawPriceLow...rawPriceHigh
        case .psa7:
            let low = rawPriceLow + (psa9PriceLow - rawPriceLow) / 3
            let high = rawPriceHigh + (psa9PriceHigh - rawPriceHigh) / 3
            return low...high
        case .psa8:
            let low = rawPriceLow + (psa9PriceLow - rawPriceLow) * 2 / 3
            let high = rawPriceHigh + (psa9PriceHigh - rawPriceHigh) * 2 / 3
            return low...high
        case .psa9: return psa9PriceLow...psa9PriceHigh
        case .psa10: return psa10PriceLow...psa10PriceHigh
        }
    }

    // NetworkManager.decoder uses .convertFromSnakeCase, which auto-converts
    // JSON keys like "player_name" → "playerName". We only need explicit mapping
    // for properties where Swift's auto-conversion doesn't match (URL acronyms).
    enum CodingKeys: String, CodingKey {
        case id, supabaseId, playerName, team, position, sport, brand, setName
        case year, cardNumber, parallel, isRookie, cardType
        case rawPriceLow, rawPriceHigh
        case psa9PriceLow, psa9PriceHigh
        case psa10PriceLow, psa10PriceHigh
        case currentPrice, priceChange
        case confidence, grade
        case imageURL = "imageUrl"
        case headshotURL = "headshotUrl"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        supabaseId = try container.decodeIfPresent(UUID.self, forKey: .supabaseId)
        playerName = try container.decode(String.self, forKey: .playerName)
        team = try container.decode(String.self, forKey: .team)
        position = try container.decode(String.self, forKey: .position)
        sport = try container.decode(SportType.self, forKey: .sport)
        brand = try container.decode(String.self, forKey: .brand)
        setName = try container.decode(String.self, forKey: .setName)
        year = try container.decode(String.self, forKey: .year)
        cardNumber = try container.decode(String.self, forKey: .cardNumber)
        parallel = try container.decode(String.self, forKey: .parallel)
        isRookie = try container.decode(Bool.self, forKey: .isRookie)
        let decodedCardType = try container.decodeIfPresent(CardType.self, forKey: .cardType)
        cardType = decodedCardType ?? (isRookie ? .rookie : .base)
        rawPriceLow = try container.decode(Int.self, forKey: .rawPriceLow)
        rawPriceHigh = try container.decode(Int.self, forKey: .rawPriceHigh)
        psa9PriceLow = try container.decode(Int.self, forKey: .psa9PriceLow)
        psa9PriceHigh = try container.decode(Int.self, forKey: .psa9PriceHigh)
        psa10PriceLow = try container.decode(Int.self, forKey: .psa10PriceLow)
        psa10PriceHigh = try container.decode(Int.self, forKey: .psa10PriceHigh)
        currentPrice = try container.decode(Int.self, forKey: .currentPrice)
        priceChange = try container.decode(Double.self, forKey: .priceChange)
        confidence = try container.decode(Double.self, forKey: .confidence)
        grade = try container.decodeIfPresent(String.self, forKey: .grade)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        headshotURL = try container.decodeIfPresent(URL.self, forKey: .headshotURL)
    }
}

struct PriceHistoryPoint: Identifiable, Codable, Hashable {
    let id: UUID
    let month: String
    let value: Double

    init(id: UUID = UUID(), month: String, value: Double) {
        self.id = id
        self.month = month
        self.value = value
    }
}

struct RecentSale: Identifiable, Codable, Hashable {
    let id: UUID
    let grade: String
    let date: String
    let price: Int

    init(id: UUID = UUID(), grade: String, date: String, price: Int) {
        self.id = id
        self.grade = grade
        self.date = date
        self.price = price
    }
}

struct Player: Identifiable, Codable, Hashable {
    let id: UUID
    let supabaseId: UUID?
    let name: String
    let sport: SportType
    let team: String
    let position: String
    let headshotURL: URL?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case id, supabaseId, name, sport, team, position, bio
        case headshotURL = "headshotUrl"
    }

    init(
        id: UUID = UUID(),
        supabaseId: UUID? = nil,
        name: String,
        sport: SportType,
        team: String,
        position: String,
        headshotURL: URL? = nil,
        bio: String? = nil
    ) {
        self.id = id
        self.supabaseId = supabaseId
        self.name = name
        self.sport = sport
        self.team = team
        self.position = position
        self.headshotURL = headshotURL
        self.bio = bio
    }
}

struct PopularSeries: Identifiable, Codable, Hashable {
    let id: String
    let brand: String
    let setName: String
    let year: String
    let cardCount: Int

    init(
        brand: String,
        setName: String,
        year: String,
        cardCount: Int
    ) {
        self.brand = brand
        self.setName = setName
        self.year = year
        self.cardCount = cardCount
        self.id = "\(brand)-\(setName)-\(year)"
    }

    var displayName: String {
        "\(brand) \(setName)"
    }

    var subtitle: String {
        "\(year) · \(cardCount) cards"
    }
}

struct PriceData: Codable, Hashable {
    let cardId: UUID
    let rawRange: ClosedRange<Int>
    let psa9Range: ClosedRange<Int>
    let psa10Range: ClosedRange<Int>
    let currentPrice: Int
    let priceChange: Double
    let history: [PriceHistoryPoint]
    let recentSales: [RecentSale]

    func priceRange(for grade: CardGrade) -> ClosedRange<Int> {
        switch grade {
        case .raw: return rawRange
        case .psa7:
            let low = rawRange.lowerBound + (psa9Range.lowerBound - rawRange.lowerBound) / 3
            let high = rawRange.upperBound + (psa9Range.upperBound - rawRange.upperBound) / 3
            return low...high
        case .psa8:
            let low = rawRange.lowerBound + (psa9Range.lowerBound - rawRange.lowerBound) * 2 / 3
            let high = rawRange.upperBound + (psa9Range.upperBound - rawRange.upperBound) * 2 / 3
            return low...high
        case .psa9: return psa9Range
        case .psa10: return psa10Range
        }
    }
}

struct GradeBreakdown: Codable, Hashable {
    let centering: Double
    let corners: Double
    let edges: Double
    let surface: Double

    var overall: Double {
        ((centering * 0.3) + (corners * 0.25) + (edges * 0.2) + (surface * 0.25))
            .rounded(toPlaces: 1)
    }

    var estimatedGrade: CardGrade {
        let score = overall
        if score >= 9.0 { return .psa10 }
        if score >= 8.0 { return .psa9 }
        if score >= 7.0 { return .psa8 }
        if score >= 6.0 { return .psa7 }
        return .raw
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

struct MockData {
    static let lukaDoncic = SportsCard(
        playerName: "Luka Dončić",
        team: "Dallas Mavericks",
        position: "Point Guard",
        sport: .basketball,
        brand: "Panini",
        setName: "Prizm",
        year: "2018",
        cardNumber: "280",
        parallel: "Silver",
        isRookie: true,
        rawPriceLow: 180, rawPriceHigh: 250,
        psa9PriceLow: 380, psa9PriceHigh: 450,
        psa10PriceLow: 800, psa10PriceHigh: 1200,
        currentPrice: 485,
        priceChange: 8.2,
        confidence: 97.3,
        grade: "PSA 10"
    )

    static let ohtani = SportsCard(
        playerName: "Shohei Ohtani",
        team: "Los Angeles Angels",
        position: "Pitcher / DH",
        sport: .baseball,
        brand: "Topps",
        setName: "Chrome",
        year: "2018",
        cardNumber: "150",
        parallel: "Refractor",
        isRookie: true,
        rawPriceLow: 150, rawPriceHigh: 220,
        psa9PriceLow: 400, psa9PriceHigh: 500,
        psa10PriceLow: 900, psa10PriceHigh: 1400,
        currentPrice: 320,
        priceChange: 15.1,
        confidence: 95.8,
        grade: "PSA 9"
    )

    static let mahomes = SportsCard(
        playerName: "Patrick Mahomes",
        team: "Kansas City Chiefs",
        position: "Quarterback",
        sport: .football,
        brand: "Panini",
        setName: "Prizm",
        year: "2017",
        cardNumber: "269",
        parallel: "Base",
        isRookie: true,
        rawPriceLow: 100, rawPriceHigh: 150,
        psa9PriceLow: 250, psa9PriceHigh: 320,
        psa10PriceLow: 500, psa10PriceHigh: 700,
        currentPrice: 210,
        priceChange: -3.4,
        confidence: 94.1,
        grade: nil
    )

    static let wembanyama = SportsCard(
        playerName: "Victor Wembanyama",
        team: "San Antonio Spurs",
        position: "Center",
        sport: .basketball,
        brand: "Panini",
        setName: "Prizm",
        year: "2023",
        cardNumber: "275",
        parallel: "Silver",
        isRookie: true,
        rawPriceLow: 400, rawPriceHigh: 600,
        psa9PriceLow: 800, psa9PriceHigh: 1000,
        psa10PriceLow: 1500, psa10PriceHigh: 2200,
        currentPrice: 890,
        priceChange: 22.5,
        confidence: 96.2,
        grade: "RC"
    )

    static let bellingham = SportsCard(
        playerName: "Jude Bellingham",
        team: "Real Madrid",
        position: "Midfielder",
        sport: .soccer,
        brand: "Topps",
        setName: "Chrome UCL",
        year: "2020",
        cardNumber: "74",
        parallel: "Refractor",
        isRookie: true,
        rawPriceLow: 150, rawPriceHigh: 250,
        psa9PriceLow: 350, psa9PriceHigh: 450,
        psa10PriceLow: 600, psa10PriceHigh: 900,
        currentPrice: 340,
        priceChange: 31.2,
        confidence: 93.5,
        grade: nil
    )

    static let allCards: [SportsCard] = [lukaDoncic, ohtani, mahomes, wembanyama, bellingham]

    static let priceHistory: [PriceHistoryPoint] = [
        .init(month: "Jan", value: 380),
        .init(month: "Feb", value: 395),
        .init(month: "Mar", value: 370),
        .init(month: "Apr", value: 410),
        .init(month: "May", value: 430),
        .init(month: "Jun", value: 415),
        .init(month: "Jul", value: 440),
        .init(month: "Aug", value: 460),
        .init(month: "Sep", value: 450),
        .init(month: "Oct", value: 470),
        .init(month: "Nov", value: 465),
        .init(month: "Dec", value: 485),
    ]

    static let recentSales: [RecentSale] = [
        .init(grade: "Raw", date: "Mar 10", price: 235),
        .init(grade: "Raw", date: "Mar 8", price: 220),
        .init(grade: "PSA 9", date: "Mar 5", price: 425),
        .init(grade: "PSA 10", date: "Mar 2", price: 1050),
    ]
}
