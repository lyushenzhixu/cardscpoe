import Foundation
import UIKit
@preconcurrency import Vision

struct ScanResultPayload {
    let matchedCard: SportsCard?
    let extractedText: String
}

@MainActor
final class ScanService {
    static let shared = ScanService()

    private let cardService = CardService.shared

    private init() {}

    func identifyCard(from image: UIImage) async -> ScanResultPayload {
        guard let cgImage = image.cgImage else {
            return ScanResultPayload(matchedCard: nil, extractedText: "")
        }

        let extractedText = await extractText(from: cgImage)
        let normalized = normalizedText(extractedText)

        let localCards = await cardService.fetchAllCards(context: nil)
        let scored = localCards.map { card in
            (card: card, score: score(card: card, text: normalized))
        }
        .sorted { $0.score > $1.score }

        let best = scored.first
#if DEBUG
        if let best {
            print("[ScanService] OCR=\"\(extractedText)\" | best=\(best.card.playerName) | score=\(best.score)")
        } else {
            print("[ScanService] OCR=\"\(extractedText)\" | no candidates")
        }
#endif
        if let best, best.score >= 2 {
            return ScanResultPayload(matchedCard: best.card, extractedText: extractedText)
        }
        return ScanResultPayload(matchedCard: nil, extractedText: extractedText)
    }

    private func extractText(from image: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let items = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = items.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: " "))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.02

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }
    }

    private func score(card: SportsCard, text: String) -> Int {
        var points = 0

        let player = normalizedText(card.playerName)
        let brand = normalizedText(card.brand)
        let setName = normalizedText(card.setName)
        let cardNumber = normalizedText(card.cardNumber)
        let year = normalizedText(card.year)
        let parallel = normalizedText(card.parallel)

        if text.contains(player) { points += 4 }
        if text.contains(brand) { points += 2 }
        if text.contains(setName) { points += 2 }
        if text.contains(cardNumber) { points += 2 }
        if text.contains(year) { points += 1 }
        if text.contains(parallel) { points += 1 }

        // OCR often misses punctuation/spacing; reward partial player token overlap.
        let textTokens = Set(normalizedTokens(text))
        let playerTokens = normalizedTokens(card.playerName)
        let overlap = playerTokens.filter { textTokens.contains($0) }.count
        points += min(overlap, 2)

        return points
    }

    private func normalizedText(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedTokens(_ value: String) -> [String] {
        normalizedText(value)
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count >= 2 }
    }
}
