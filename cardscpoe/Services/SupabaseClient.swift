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

    static func inValues(_ key: String, _ values: [String]) -> SupabaseQueryFilter {
        let joined = values.joined(separator: ",")
        return .init(key: key, value: "(\(joined))", op: "in")
    }

    static func gt(_ key: String, _ value: String) -> SupabaseQueryFilter {
        .init(key: key, value: value, op: "gt")
    }

    /// PostgREST OR filter: combines multiple conditions with OR logic.
    /// Usage: `.or("player_name.ilike.*LeBron*,brand.ilike.*Panini*")`
    static func or(_ expression: String) -> SupabaseQueryFilter {
        .init(key: "or", value: "(\(expression))", op: "")
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
        order: String? = nil,
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
            if filter.op.isEmpty {
                // Special filters like OR that use raw value
                items.append(URLQueryItem(name: filter.key, value: filter.value))
            } else {
                items.append(URLQueryItem(name: filter.key, value: "\(filter.op).\(filter.value)"))
            }
        }
        if let order, !order.isEmpty {
            items.append(URLQueryItem(name: "order", value: order))
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

    /// 同 select 的 URL，但返回原始 Data，用于解码失败时 DEBUG 打印响应内容
    func selectRaw(
        table: String,
        columns: String = "*",
        limit: Int? = nil
    ) async throws -> Data {
        guard var components = URLComponents(
            url: restURL(path: "rest/v1/\(table)"),
            resolvingAgainstBaseURL: false
        ) else { throw NetworkError.invalidURL }
        var items = [URLQueryItem(name: "select", value: columns)]
        if let limit { items.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        components.queryItems = items
        guard let url = components.url else { throw NetworkError.invalidURL }
        let request = NetworkRequest(url: url, headers: defaultHeaders)
        return try await network.requestRaw(request)
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
