import Foundation
import SwiftData

private struct BallDontLieResponse: Decodable {
    struct Team: Decodable {
        let fullName: String?
        let abbreviation: String?
    }

    struct Entry: Decodable {
        let firstName: String?
        let lastName: String?
        let position: String?
        let team: Team?
    }

    let data: [Entry]
}

private struct SportsDBResponse: Decodable {
    struct Entry: Decodable {
        let strPlayer: String?
        let strTeam: String?
        let strPosition: String?
        let strCutout: String?
        let strThumb: String?
        let strDescriptionEN: String?
    }

    let player: [Entry]?
}

@MainActor
final class PlayerService {
    static let shared = PlayerService()

    private let network = NetworkManager.shared
    private let supabase = SupabaseClient.shared
    private let cache = CacheManager.shared

    private init() {}

    func fetchTrendingPlayers(context: ModelContext?) async -> [Player] {
        let names = ["Luka Doncic", "Shohei Ohtani", "Patrick Mahomes", "Victor Wembanyama", "Jude Bellingham"]
        var players: [Player] = []
        for name in names {
            if let player = await searchPlayer(name: name, sport: nil, context: context).first {
                players.append(player)
            }
        }
        if !players.isEmpty {
            return players
        }
        return [
            Player(name: "Luka Doncic", sport: .basketball, team: "Dallas Mavericks", position: "PG"),
            Player(name: "Shohei Ohtani", sport: .baseball, team: "Los Angeles Dodgers", position: "DH"),
            Player(name: "Patrick Mahomes", sport: .football, team: "Kansas City Chiefs", position: "QB"),
        ]
    }

    func searchPlayer(name: String, sport: SportType?, context: ModelContext?) async -> [Player] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if supabase.isConfigured {
            do {
                let filters = [SupabaseQueryFilter.ilike("name", "*\(trimmed)*")]
                let remote: [Player] = try await supabase.select(table: "players", filters: filters, limit: 20)
                if !remote.isEmpty {
                    if let context {
                        try cache.upsertPlayers(remote, context: context)
                    }
                    return remote
                }
            } catch {
                // fallback below
            }
        }

        async let ball = fetchFromBallDontLie(name: trimmed)
        async let sportsDB = fetchFromSportsDB(name: trimmed, sport: sport)

        var merged = deduplicate(await ball + sportsDB)
        if merged.isEmpty, let context {
            merged = (try? cache.fetchPlayers(context: context, sport: sport))?.filter {
                $0.name.localizedCaseInsensitiveContains(trimmed)
            } ?? []
        }

        if let context, !merged.isEmpty {
            try? cache.upsertPlayers(merged, context: context)
        }
        return merged
    }

    private func fetchFromBallDontLie(name: String) async -> [Player] {
        guard var components = URLComponents(string: "https://api.balldontlie.io/v1/players") else {
            return []
        }
        components.queryItems = [URLQueryItem(name: "search", value: name)]
        guard let url = components.url else { return [] }

        var headers = ["Accept": "application/json"]
        if !APIConfig.balldontlieKey.isEmpty {
            headers["Authorization"] = APIConfig.balldontlieKey
        }
        let request = NetworkRequest(url: url, headers: headers)

        do {
            let resp: BallDontLieResponse = try await network.request(request)
            return resp.data.compactMap { entry in
                let fullName = "\(entry.firstName ?? "") \(entry.lastName ?? "")".trimmingCharacters(in: .whitespaces)
                guard !fullName.isEmpty else { return nil }
                return Player(
                    name: fullName,
                    sport: .basketball,
                    team: entry.team?.fullName ?? entry.team?.abbreviation ?? "Unknown Team",
                    position: entry.position ?? "Unknown"
                )
            }
        } catch {
            return []
        }
    }

    private func fetchFromSportsDB(name: String, sport: SportType?) async -> [Player] {
        let q = name.replacingOccurrences(of: " ", with: "_")
        guard let url = URL(string: "https://www.thesportsdb.com/api/v1/json/\(APIConfig.sportsDBKey)/searchplayers.php?p=\(q)") else {
            return []
        }
        let request = NetworkRequest(url: url, headers: ["Accept": "application/json"])

        do {
            let resp: SportsDBResponse = try await network.request(request)
            let entries = resp.player ?? []
            return entries.compactMap { entry in
                guard let playerName = entry.strPlayer, !playerName.isEmpty else { return nil }
                let inferredSport = sport ?? inferSport(from: entry.strPosition)
                let headshot = entry.strCutout ?? entry.strThumb
                return Player(
                    name: playerName,
                    sport: inferredSport,
                    team: entry.strTeam ?? "Unknown Team",
                    position: entry.strPosition ?? "Unknown",
                    headshotURL: headshot.flatMap(URL.init(string:)),
                    bio: entry.strDescriptionEN
                )
            }
        } catch {
            return []
        }
    }

    private func inferSport(from position: String?) -> SportType {
        let value = (position ?? "").lowercased()
        if value.contains("pitch") || value.contains("shortstop") || value.contains("outfield") {
            return .baseball
        }
        if value.contains("quarterback") || value.contains("linebacker") || value.contains("wide receiver") {
            return .football
        }
        if value.contains("forward") || value.contains("midfielder") || value.contains("goalkeeper") || value.contains("striker") {
            return .soccer
        }
        return .basketball
    }

    private func deduplicate(_ players: [Player]) -> [Player] {
        var seen = Set<String>()
        return players.filter {
            let key = $0.name.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }
}
