//
//  CardModel.swift
//  cardscpoe
//
//  球星卡数据模型 — Demo 用 mock 数据
//

import Foundation
import SwiftUI

enum SportType: String, CaseIterable, Identifiable {
    case basketball = "NBA"
    case baseball = "MLB"
    case football = "NFL"
    case soccer = "Soccer"
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .basketball: return "🏀"
        case .baseball: return "⚾"
        case .football: return "🏈"
        case .soccer: return "⚽"
        }
    }
    
    var imageName: String {
        switch self {
        case .basketball: return "card_basketball"
        case .baseball: return "card_baseball"
        case .football: return "card_football"
        case .soccer: return "card_soccer"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .basketball: return [Color(red: 0.05, green: 0.15, blue: 0.25), Color(red: 0.03, green: 0.08, blue: 0.15)]
        case .baseball: return [Color(red: 0.15, green: 0.05, blue: 0.05), Color(red: 0.1, green: 0.02, blue: 0.02)]
        case .football: return [Color(red: 0.05, green: 0.15, blue: 0.1), Color(red: 0.02, green: 0.08, blue: 0.05)]
        case .soccer: return [Color(red: 0.12, green: 0.12, blue: 0.15), Color(red: 0.06, green: 0.06, blue: 0.1)]
        }
    }
}

struct CardItem: Identifiable {
    let id: String
    let playerName: String
    let cardSet: String
    let sport: SportType
    let year: String
    let cardNumber: String
    let parallel: String
    let type: String  // Rookie, Base, etc.
    let brand: String
    let priceRaw: String
    let pricePSA9: String
    let pricePSA10: String
    let confidence: Double
    let priceChange: Double
    let grade: String?
    let imageName: String
    let estimatedValue: Double
}

// MARK: - CardItem 计算属性

extension CardItem {
    var priceFormatted: String { "$\(Int(estimatedValue))" }
    var change: Double { priceChange }
    var changeFormatted: String { priceChange >= 0 ? "↑ \(String(format: "%.1f", priceChange))%" : "↓ \(String(format: "%.1f", -priceChange))%" }
    var changeText: String { changeFormatted }
    var cardSetDisplay: String { cardSet }
    var set: String { parallel.isEmpty ? brand : "\(brand) \(parallel)" }
    var typeLabel: String { type }
    var shortSetDisplay: String {
        let parts = cardSet.split(separator: " ")
        if parts.count >= 2 { return "\(parts[0]) \(parts[1])" }
        return String(cardSet.prefix(20))
    }
    
    var cardNumberDisplay: String {
        cardNumber.hasPrefix("#") ? cardNumber : "#\(cardNumber)"
    }
    
    var isRookie: Bool { type.lowercased() == "rookie" }
    var team: String { CardItem.teamForPlayer(playerName) }
    var position: String { CardItem.positionForPlayer(playerName) }
    
    private static func teamForPlayer(_ name: String) -> String {
        switch name {
        case "Luka Dončić": return "Dallas Mavericks"
        case "Shohei Ohtani": return "Los Angeles Dodgers"
        case "Patrick Mahomes": return "Kansas City Chiefs"
        case "Victor Wembanyama": return "San Antonio Spurs"
        case "Jude Bellingham": return "Real Madrid"
        default: return "—"
        }
    }
    
    private static func positionForPlayer(_ name: String) -> String {
        switch name {
        case "Luka Dončić", "Victor Wembanyama": return "Point Guard"
        case "Shohei Ohtani": return "Pitcher / DH"
        case "Patrick Mahomes": return "Quarterback"
        case "Jude Bellingham": return "Midfielder"
        default: return "—"
        }
    }
    
    static let demoLuka = mockBasketball
    static let demoCollection: [CardItem] = DemoData.collectionCards
}

// MARK: - Mock Data

extension CardItem {
    static let mockBasketball = CardItem(
        id: "1",
        playerName: "Luka Dončić",
        cardSet: "2018-19 Panini Prizm Silver #280",
        sport: .basketball,
        year: "2018",
        cardNumber: "#280",
        parallel: "Silver",
        type: "Rookie",
        brand: "Panini",
        priceRaw: "$180 - $250",
        pricePSA9: "$380 - $450",
        pricePSA10: "$800 - $1,200",
        confidence: 97.3,
        priceChange: 8.2,
        grade: "PSA 10",
        imageName: "card_basketball",
        estimatedValue: 485
    )
    
    static let mockBaseball = CardItem(
        id: "2",
        playerName: "Shohei Ohtani",
        cardSet: "2018 Topps Chrome #150",
        sport: .baseball,
        year: "2018",
        cardNumber: "#150",
        parallel: "Chrome",
        type: "Rookie",
        brand: "Topps",
        priceRaw: "$250 - $350",
        pricePSA9: "$600 - $750",
        pricePSA10: "$1,200 - $1,500",
        confidence: 95.1,
        priceChange: 15.1,
        grade: "PSA 9",
        imageName: "card_baseball",
        estimatedValue: 320
    )
    
    static let mockFootball = CardItem(
        id: "3",
        playerName: "Patrick Mahomes",
        cardSet: "2017 Panini Prizm Base #269",
        sport: .football,
        year: "2017",
        cardNumber: "#269",
        parallel: "Base",
        type: "Rookie",
        brand: "Panini",
        priceRaw: "$150 - $220",
        pricePSA9: "$350 - $420",
        pricePSA10: "$700 - $950",
        confidence: 93.8,
        priceChange: -3.4,
        grade: nil,
        imageName: "card_football",
        estimatedValue: 210
    )
    
    static let mockWembanyama = CardItem(
        id: "4",
        playerName: "Victor Wembanyama",
        cardSet: "2023 Prizm Silver RC #275",
        sport: .basketball,
        year: "2023",
        cardNumber: "#275",
        parallel: "Silver",
        type: "Rookie",
        brand: "Panini",
        priceRaw: "$450 - $650",
        pricePSA9: "$800 - $1,000",
        pricePSA10: "$1,800 - $2,200",
        confidence: 96.2,
        priceChange: 22.5,
        grade: "RC",
        imageName: "card_basketball_rookie",
        estimatedValue: 890
    )
    
    static let mockSoccer = CardItem(
        id: "5",
        playerName: "Jude Bellingham",
        cardSet: "2020 Topps Chrome UCL RC",
        sport: .soccer,
        year: "2020",
        cardNumber: "#N/A",
        parallel: "Chrome",
        type: "Rookie",
        brand: "Topps",
        priceRaw: "$200 - $350",
        pricePSA9: "$450 - $600",
        pricePSA10: "$900 - $1,200",
        confidence: 94.5,
        priceChange: 31.2,
        grade: nil,
        imageName: "card_soccer",
        estimatedValue: 340
    )
    
    static let allMocks: [CardItem] = [
        mockBasketball,
        mockBaseball,
        mockFootball,
        mockWembanyama,
        mockSoccer
    ]
    
    static let recentMocks: [CardItem] = [
        mockBasketball,
        mockBaseball,
        mockFootball
    ]
}

/// Demo 数据提供方
enum DemoData {
    static let collectionCards: [CardItem] = [
        .mockBasketball,
        .mockBaseball,
        .mockFootball,
        .mockWembanyama
    ]
    
    static let recentScanned: [CardItem] = [
        .mockBasketball,
        .mockBaseball,
        .mockFootball,
        .mockWembanyama
    ]
}
