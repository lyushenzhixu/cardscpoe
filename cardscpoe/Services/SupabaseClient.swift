import Foundation

struct SupabaseQueryFilter {
    let key: String
    let value: String
    let op: String

    static func eq(_ key: String, _ value: String) -> SupabaseQueryFilter {
        .init(key: key, value: value, op: "eq")
    }

    static func ilike(_ key: String, _ value: String) -> SupabaseQueryFilter {
        .init(key: key, value: value, op: "ilike")
    }
}

final class SupabaseClient {
    static let shared = SupabaseClient()

    private let network = NetworkManager.shared

    private var baseURL: URL? {
        APIConfig.supabaseURL
    }

    private var anonKey: String {
        APIConfig.supabaseAnonKey
    }

    private var defaultHeaders: [String: String] {
        [
            "apikey": anonKey,
            "Authorization": "Bearer \(anonKey)",
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
    }

    var isConfigured: Bool {
        baseURL != nil && !anonKey.isEmpty
    }

    func select<T: Decodable>(
        table: String,
        columns: String = "*",
        filters: [SupabaseQueryFilter] = [],
        limit: Int? = nil
    ) async throws -> [T] {
        guard var components = URLComponents(
            url: restURL(path: "rest/v1/\(table)"),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }

        var items = [URLQueryItem(name: "select", value: columns)]
        for filter in filters {
            items.append(URLQueryItem(name: filter.key, value: "\(filter.op).\(filter.value)"))
        }
        if let limit {
            items.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        components.queryItems = items

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        let request = NetworkRequest(url: url, headers: defaultHeaders)
        return try await network.request(request)
    }

    func upsert<T: Encodable>(table: String, payload: [T]) async throws {
        let url = restURL(path: "rest/v1/\(table)")
        var headers = defaultHeaders
        headers["Prefer"] = "resolution=merge-duplicates,return=minimal"

        let request = NetworkRequest(
            url: url,
            method: "POST",
            headers: headers,
            body: try network.encode(payload)
        )
        try await network.requestWithoutBody(request)
    }

    func insert<T: Encodable>(table: String, payload: T) async throws {
        let url = restURL(path: "rest/v1/\(table)")
        var headers = defaultHeaders
        headers["Prefer"] = "return=minimal"
        let body = try network.encode([payload])
        let request = NetworkRequest(url: url, method: "POST", headers: headers, body: body)
        try await network.requestWithoutBody(request)
    }

    func invokeFunction<T: Decodable, Body: Encodable>(
        _ functionName: String,
        body: Body
    ) async throws -> T {
        let url = restURL(path: "functions/v1/\(functionName)")
        let request = NetworkRequest(
            url: url,
            method: "POST",
            headers: defaultHeaders,
            body: try network.encode(body)
        )
        return try await network.request(request)
    }

    private func restURL(path: String) -> URL {
        guard let baseURL else {
            fatalError("Supabase is not configured. Please set SUPABASE_URL and SUPABASE_ANON_KEY in Info.plist build settings.")
        }
        return baseURL.appendingPathComponent(path)
    }
}
