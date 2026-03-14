import Foundation
import SwiftData

private struct PriceChartingResponse: Decodable {
    let productName: String?
    let loosePrice: Double?
    let gradedPrice: Double?
    let manualOnlyPrice: Double?
}

private struct FetchPricePayload: Encodable {
    let playerName: String
    let brand: String
    let setName: String
    let year: String
    let cardNumber: String
}

private struct PriceFunctionResult: Decodable {
    let currentPrice: Int
    let priceChange: Double
    let rawLow: Int
    let rawHigh: Int
    let psa9Low: Int
    let psa9High: Int
    let psa10Low: Int
    let psa10High: Int
    let history: [PriceHistoryPoint]
    let recentSales: [RecentSale]
}

@MainActor
final class PriceService {
    static let shared = PriceService()

    private let network = NetworkManager.shared
    private let supabase = SupabaseClient.shared

    private init() {}

    func fetchPriceData(for card: SportsCard, context _: ModelContext?) async -> PriceData {
        if supabase.isConfigured {
            do {
                let payload = FetchPricePayload(
                    playerName: card.playerName,
                    brand: card.brand,
                    setName: card.setName,
                    year: card.year,
                    cardNumber: card.cardNumber
                )
                let remote: PriceFunctionResult = try await supabase.invokeFunction("fetch-prices", body: payload)
                return PriceData(
                    cardId: card.id,
                    rawRange: remote.rawLow ... remote.rawHigh,
                    psa9Range: remote.psa9Low ... remote.psa9High,
                    psa10Range: remote.psa10Low ... remote.psa10High,
                    currentPrice: remote.currentPrice,
                    priceChange: remote.priceChange,
                    history: remote.history,
                    recentSales: remote.recentSales
                )
            } catch {
                // fallback to direct API / local data
            }
        }

        if let charting = await fetchFromPriceCharting(card: card) {
            return charting
        }

        return PriceData(
            cardId: card.id,
            rawRange: card.rawPriceLow ... card.rawPriceHigh,
            psa9Range: card.psa9PriceLow ... card.psa9PriceHigh,
            psa10Range: card.psa10PriceLow ... card.psa10PriceHigh,
            currentPrice: card.currentPrice,
            priceChange: card.priceChange,
            history: MockData.priceHistory,
            recentSales: MockData.recentSales
        )
    }

    func thisMonthGrowth(collection: [SportsCard]) async -> Double {
        guard !collection.isEmpty else { return 0 }
        let avg = collection.map(\.priceChange).reduce(0, +) / Double(collection.count)
        return avg.rounded(toPlaces: 1)
    }

    private func fetchFromPriceCharting(card: SportsCard) async -> PriceData? {
        guard !APIConfig.priceChartingKey.isEmpty else { return nil }
        let q = "\(card.playerName) \(card.year) \(card.brand) \(card.setName) #\(card.cardNumber)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://www.pricecharting.com/api/product?t=\(APIConfig.priceChartingKey)&q=\(q)") else {
            return nil
        }
        let request = NetworkRequest(url: url, headers: ["Accept": "application/json"])
        do {
            let data: PriceChartingResponse = try await network.request(request)
            let loose = Int(data.loosePrice ?? Double(card.currentPrice))
            let graded = Int(data.gradedPrice ?? Double(max(card.psa10PriceLow, card.currentPrice)))
            let current = max(loose, 1)
            return PriceData(
                cardId: card.id,
                rawRange: max(1, Int(Double(current) * 0.85)) ... max(2, Int(Double(current) * 1.15)),
                psa9Range: max(1, Int(Double(current) * 1.45)) ... max(2, Int(Double(current) * 1.7)),
                psa10Range: max(1, Int(Double(graded) * 0.9)) ... max(2, Int(Double(graded) * 1.15)),
                currentPrice: current,
                priceChange: card.priceChange,
                history: MockData.priceHistory,
                recentSales: MockData.recentSales
            )
        } catch {
            return nil
        }
    }
}
