import Foundation
import UIKit
@preconcurrency import Vision

enum MatchConfidenceLevel: String {
    case strong   // score >= 8
    case moderate // score 4-7
    case weak     // score 2-3
    case none     // score < 2

    var label: String {
        switch self {
        case .strong:   return "Strong Match"
        case .moderate: return "Likely Match"
        case .weak:     return "Possible Match — Please Verify"
        case .none:     return "Not Found"
        }
    }

    var icon: String {
        switch self {
        case .strong:   return "checkmark.circle.fill"
        case .moderate: return "checkmark.circle"
        case .weak:     return "questionmark.circle"
        case .none:     return "xmark.circle"
        }
    }
}

struct ScanResultPayload {
    let matchedCard: SportsCard?
    let extractedText: String
    let debugInfo: String
    let confidenceLevel: MatchConfidenceLevel
}

@MainActor
final class ScanService {
    static let shared = ScanService()

    private let cardService = CardService.shared

    private init() {}

    // MARK: - Known Dictionaries

    private static let knownBrands: Set<String> = [
        "panini", "topps", "upper deck", "bowman", "donruss", "fleer", "leaf"
    ]

    private static let knownSets: Set<String> = [
        "prizm", "select", "donruss", "mosaic", "optic", "national treasures", "flawless",
        "sp authentic", "chrome", "series 1", "series 2", "bowman", "heritage", "inception",
        "diamond kings", "contenders", "finest", "merlin",
        "prizm draft", "donruss optic", "bowman chrome"
    ]

    /// Words to exclude from player name guessing — brands, sets, cities, teams, common card words
    private static let noiseWords: Set<String> = {
        var s: Set<String> = [
            // brands & sets (already in knownBrands/knownSets, but also as single words)
            "panini", "topps", "upper", "deck", "bowman", "donruss", "fleer", "leaf",
            "prizm", "select", "mosaic", "optic", "chrome", "heritage", "inception",
            "finest", "merlin", "contenders", "flawless",
            // card terms
            "rookie", "rated", "silver", "gold", "base", "refractor", "holo",
            "parallel", "insert", "auto", "patch", "numbered", "card", "cards",
            "test", "html", "http", "https", "www", "com",
            // common noise from browser / device
            "using", "skills", "accelerate", "print", "photograph", "screen",
            "openchamber", "preview", "scan", "identify", "grade",
            // NBA cities & teams
            "los", "angeles", "lakers", "celtics", "boston", "warriors", "golden",
            "state", "nets", "brooklyn", "knicks", "new", "york", "bulls", "chicago",
            "heat", "miami", "spurs", "san", "antonio", "mavericks", "dallas",
            "suns", "phoenix", "bucks", "milwaukee", "sixers", "philadelphia",
            "nuggets", "denver", "clippers", "kings", "sacramento", "hawks", "atlanta",
            "grizzlies", "memphis", "cavaliers", "cleveland", "pacers", "indiana",
            "thunder", "oklahoma", "city", "raptors", "toronto", "jazz", "utah",
            "wizards", "washington", "magic", "orlando", "pelicans", "orleans",
            "timberwolves", "minnesota", "blazers", "portland", "trail", "hornets",
            "charlotte", "pistons", "detroit", "rockets", "houston",
            // MLB teams
            "angels", "astros", "athletics", "blue", "jays", "braves", "brewers",
            "cardinals", "cubs", "diamondbacks", "dodgers", "giants", "guardians",
            "mariners", "marlins", "mets", "nationals", "orioles", "padres",
            "phillies", "pirates", "rangers", "rays", "red", "sox", "reds",
            "rockies", "royals", "tigers", "twins", "white", "yankees",
            // NFL teams
            "chiefs", "kansas", "eagles", "bills", "buffalo", "bengals", "cincinnati",
            "ravens", "baltimore", "cowboys", "packers", "green", "bay",
            "49ers", "francisco", "seahawks", "seattle", "steelers", "pittsburgh",
            "dolphins", "patriots", "england", "chargers", "raiders",
            "broncos", "colts", "indianapolis", "jaguars", "jacksonville",
            "titans", "tennessee", "texans", "commanders", "saints",
            "falcons", "panthers", "carolina", "lions", "bears", "vikings",
            "buccaneers", "tampa", "cardinals", "arizona", "rams",
            // Soccer clubs
            "real", "madrid", "barcelona", "manchester", "united", "liverpool",
            "chelsea", "arsenal", "tottenham", "hotspur", "inter", "milan",
            "juventus", "bayern", "munich", "paris", "germain", "psg",
            "dortmund", "borussia", "napoli", "roma", "atletico",
            // common short words
            "the", "and", "for", "from", "with", "this", "that",
        ]
        return s
    }()

    private static let ocrCorrections: [(pattern: String, replacement: String)] = [
        ("pr1zm", "prizm"), ("se1ect", "select"), ("d0nruss", "donruss"),
        ("t0pps", "topps"), ("pan1ni", "panini"), ("chr0me", "chrome"),
        ("m0saic", "mosaic"), ("0ptic", "optic"),
    ]

    // MARK: - Main Entry Point

    func identifyCard(from image: UIImage) async -> ScanResultPayload {
        guard let cgImage = image.cgImage else {
            return ScanResultPayload(matchedCard: nil, extractedText: "", debugInfo: "No CGImage", confidenceLevel: .none)
        }

        let rawText = await extractText(from: cgImage)
        let correctedText = applyCorrectionRules(rawText)
        let normalized = normalizedText(correctedText)

        #if DEBUG
        print("[ScanService] ── OCR Start ──")
        print("[ScanService] Raw: \(rawText)")
        print("[ScanService] Normalized: \(normalized)")
        #endif

        let tokens = parseOCRTokens(from: normalized, rawText: rawText)

        #if DEBUG
        print("[ScanService] Tokens → Players: \(tokens.playerGuesses) | Brands: \(tokens.brandGuesses) | Sets: \(tokens.setGuesses) | Years: \(tokens.yearGuesses) | Card#: \(tokens.cardNumbers)")
        #endif

        let candidates = await cardService.searchByOCRTokens(
            playerGuesses: tokens.playerGuesses,
            brandGuesses: tokens.brandGuesses,
            setGuesses: tokens.setGuesses,
            yearGuesses: tokens.yearGuesses,
            context: nil
        )

        let scored = candidates.map { card in
            (card: card, score: score(card: card, text: normalized, tokens: tokens))
        }
        .sorted { $0.score > $1.score }

        let best = scored.first
        let debugInfo = buildDebugInfo(tokens: tokens, candidateCount: candidates.count, best: best)

        #if DEBUG
        if let best {
            print("[ScanService] Best: \(best.card.playerName) score=\(best.score)")
            if scored.count > 1, let second = scored.dropFirst().first {
                print("[ScanService] 2nd: \(second.card.playerName) score=\(second.score)")
            }
        } else {
            print("[ScanService] No candidates")
        }
        print("[ScanService] ── OCR End ──")
        #endif

        if let best, best.score >= 2 {
            let confidence = min(99.0, 50.0 + Double(best.score) * 5.0)
            let level: MatchConfidenceLevel = best.score >= 8 ? .strong : best.score >= 4 ? .moderate : .weak
            let m = best.card
            let matched = SportsCard(
                id: m.id, supabaseId: m.supabaseId,
                playerName: m.playerName, team: m.team, position: m.position, sport: m.sport,
                brand: m.brand, setName: m.setName, year: m.year,
                cardNumber: m.cardNumber, parallel: m.parallel, isRookie: m.isRookie,
                rawPriceLow: m.rawPriceLow, rawPriceHigh: m.rawPriceHigh,
                psa9PriceLow: m.psa9PriceLow, psa9PriceHigh: m.psa9PriceHigh,
                psa10PriceLow: m.psa10PriceLow, psa10PriceHigh: m.psa10PriceHigh,
                currentPrice: m.currentPrice, priceChange: m.priceChange,
                confidence: confidence, grade: m.grade,
                imageURL: m.imageURL, headshotURL: m.headshotURL
            )
            return ScanResultPayload(matchedCard: matched, extractedText: rawText, debugInfo: debugInfo, confidenceLevel: level)
        }
        return ScanResultPayload(matchedCard: nil, extractedText: rawText, debugInfo: debugInfo, confidenceLevel: .none)
    }

    // MARK: - OCR Extraction (Vision)

    private func extractText(from image: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let items = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = items.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: " "))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.015
            request.recognitionLanguages = ["en-US"]

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

    // MARK: - Token Parsing

    struct OCRTokens {
        var playerGuesses: [String] = []
        var brandGuesses: [String] = []
        var setGuesses: [String] = []
        var yearGuesses: [String] = []
        var cardNumbers: [String] = []
        /// Individual significant words for server-side search fallback
        var significantWords: [String] = []
    }

    private func parseOCRTokens(from normalized: String, rawText: String) -> OCRTokens {
        var tokens = OCRTokens()

        // 1. Extract years (4-digit 1990-2026)
        let yearPattern = /\b(19[89]\d|20[0-2]\d)\b/
        for match in normalized.matches(of: yearPattern) {
            let y = String(match.1)
            if !tokens.yearGuesses.contains(y) { tokens.yearGuesses.append(y) }
        }

        // 2. Extract card numbers
        let cardNumPattern = /#\s*(\d{1,4})\b/
        for match in normalized.matches(of: cardNumPattern) {
            tokens.cardNumbers.append(String(match.1))
        }
        let standaloneNumPattern = /\b(\d{1,3})\b/
        for match in normalized.matches(of: standaloneNumPattern) {
            let num = String(match.1)
            if !tokens.yearGuesses.contains(num) && !tokens.cardNumbers.contains(num) {
                tokens.cardNumbers.append(num)
            }
        }

        // 3. Detect known brands
        for brand in Self.knownBrands {
            if normalized.contains(brand) {
                tokens.brandGuesses.append(brand.capitalized)
            }
        }

        // 4. Detect known sets
        for setName in Self.knownSets {
            if normalized.contains(setName) {
                let titleCase = setName.split(separator: " ")
                    .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                    .joined(separator: " ")
                if !tokens.setGuesses.contains(titleCase) {
                    tokens.setGuesses.append(titleCase)
                }
            }
        }

        // 5. Player name extraction — the core challenge
        //    Strategy: get all words, remove noise, find name-like sequences
        let allWords = normalized.split(separator: " ").map(String.init)

        // Filter to "significant" words: not noise, not numbers, not too short
        let significant = allWords.filter { word in
            word.count >= 3 &&
            !word.allSatisfy(\.isNumber) &&
            !Self.noiseWords.contains(word) &&
            !Self.knownBrands.contains(word) &&
            !Self.knownSets.contains(word) &&
            !tokens.yearGuesses.contains(word)
        }
        tokens.significantWords = significant

        // Try to find 2-word name combinations from significant words
        // Real player names are typically "First Last" (2 words, each 3+ chars)
        var nameGuesses: [String] = []

        // Method A: From raw text, find Title Case pairs (e.g., "LeBron James")
        //           Split on known noise words first
        let rawWords = rawText.components(separatedBy: .whitespaces)
        var cleanSegments: [[String]] = [[]]
        for word in rawWords {
            let lower = word.lowercased()
                .replacingOccurrences(of: "[^a-z]", with: "", options: .regularExpression)
            if Self.noiseWords.contains(lower) || Self.knownBrands.contains(lower) || Self.knownSets.contains(lower) {
                if !cleanSegments.last!.isEmpty {
                    cleanSegments.append([])
                }
            } else if word.count >= 2 && !word.allSatisfy(\.isNumber) {
                cleanSegments[cleanSegments.count - 1].append(word)
            }
        }

        for segment in cleanSegments {
            // Each segment is consecutive non-noise words
            guard segment.count >= 2 else { continue }
            // Take pairs
            for i in 0 ..< segment.count - 1 {
                let first = segment[i]
                let second = segment[i + 1]
                // Both should start with uppercase or be ALL CAPS
                let firstIsName = first.first?.isUppercase == true && first.count >= 2
                let secondIsName = second.first?.isUppercase == true && second.count >= 2
                if firstIsName && secondIsName {
                    let name = titleCase(first) + " " + titleCase(second)
                    if !nameGuesses.contains(name) {
                        nameGuesses.append(name)
                    }
                }
            }
            // Also try 3-word names (e.g., "Shohei Ohtani Jr")
            if segment.count >= 3 {
                let name3 = segment.prefix(3).map { titleCase($0) }.joined(separator: " ")
                if !nameGuesses.contains(name3) {
                    nameGuesses.append(name3)
                }
            }
        }

        // Method B: From significant words, generate 2-word sliding windows
        if nameGuesses.isEmpty && significant.count >= 2 {
            for i in 0 ..< min(significant.count - 1, 4) {
                let name = titleCase(significant[i]) + " " + titleCase(significant[i + 1])
                if !nameGuesses.contains(name) {
                    nameGuesses.append(name)
                }
            }
        }

        // Method C: Single significant words as last resort (for searching)
        if nameGuesses.isEmpty {
            for word in significant.prefix(3) where word.count >= 4 {
                nameGuesses.append(titleCase(word))
            }
        }

        tokens.playerGuesses = nameGuesses

        return tokens
    }

    private func titleCase(_ word: String) -> String {
        guard !word.isEmpty else { return word }
        if word == word.uppercased() && word.count > 1 {
            // ALL CAPS → Title Case
            return word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }
        return word
    }

    // MARK: - OCR Error Correction

    private func applyCorrectionRules(_ text: String) -> String {
        var result = text
        for rule in Self.ocrCorrections {
            result = result.replacingOccurrences(of: rule.pattern, with: rule.replacement, options: .caseInsensitive)
        }
        return result
    }

    // MARK: - Scoring

    private func score(card: SportsCard, text: String, tokens: OCRTokens) -> Int {
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
        if !cardNumber.isEmpty && text.contains(cardNumber) { points += 2 }
        if text.contains(year) { points += 1 }
        if !parallel.isEmpty && parallel != "base" && text.contains(parallel) { points += 1 }

        // Token overlap for player name
        let textTokens = Set(normalizedTokens(text))
        let playerTokens = normalizedTokens(card.playerName)
        let overlap = playerTokens.filter { token in
            textTokens.contains(token) ||
            textTokens.contains(where: { $0.hasPrefix(String(token.prefix(4))) && token.count >= 4 })
        }.count
        if overlap > 0 && !text.contains(player) {
            points += min(overlap, 2)
        }

        // Bonus: card number in parsed list
        if !card.cardNumber.isEmpty && tokens.cardNumbers.contains(card.cardNumber.trimmingCharacters(in: .whitespaces)) {
            points += 1
        }

        // Bonus: year in parsed list
        if tokens.yearGuesses.contains(card.year) {
            points += 1
        }

        return points
    }

    // MARK: - Debug

    private func buildDebugInfo(tokens: OCRTokens, candidateCount: Int, best: (card: SportsCard, score: Int)?) -> String {
        var lines: [String] = []
        lines.append("Players: \(tokens.playerGuesses.joined(separator: ", "))")
        lines.append("Brands: \(tokens.brandGuesses.joined(separator: ", "))")
        lines.append("Sets: \(tokens.setGuesses.joined(separator: ", "))")
        lines.append("Years: \(tokens.yearGuesses.joined(separator: ", "))")
        lines.append("Card#: \(tokens.cardNumbers.joined(separator: ", "))")
        lines.append("Candidates: \(candidateCount)")
        if let best {
            lines.append("Best: \(best.card.playerName) (score \(best.score))")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Normalization

    private func normalizedText(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedTokens(_ value: String) -> [String] {
        normalizedText(value).split(separator: " ").map(String.init).filter { $0.count >= 2 }
    }
}
