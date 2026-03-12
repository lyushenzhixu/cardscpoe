import SwiftUI

enum SportType: String, CaseIterable, Identifiable {
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

struct SportsCard: Identifiable {
    let id = UUID()
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
}

struct PriceHistoryPoint: Identifiable {
    let id = UUID()
    let month: String
    let value: Double
}

struct RecentSale: Identifiable {
    let id = UUID()
    let grade: String
    let date: String
    let price: Int
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
