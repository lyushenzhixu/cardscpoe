import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case httpError(Int, String)
    case decodeError(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case let .httpError(statusCode, body):
            return "HTTP \(statusCode): \(body)"
        case let .decodeError(message):
            return "Failed to decode response: \(message)"
        case .emptyResponse:
            return "Server returned an empty response."
        }
    }
}

struct NetworkRequest {
    let url: URL
    var method: String = "GET"
    var headers: [String: String] = [:]
    var body: Data? = nil
    var timeout: TimeInterval = 30
}

final class NetworkManager {
    static let shared = NetworkManager()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    func request<T: Decodable>(
        _ request: NetworkRequest,
        decode type: T.Type = T.self
    ) async throws -> T {
        let (data, _) = try await execute(request)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodeError(error.localizedDescription)
        }
    }

    func requestWithoutBody(_ request: NetworkRequest) async throws {
        _ = try await execute(request)
    }

    func requestRaw(_ request: NetworkRequest) async throws -> Data {
        let (data, _) = try await execute(request)
        return data
    }

    func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }

    private func execute(_ request: NetworkRequest) async throws -> (Data, HTTPURLResponse) {
        var urlRequest = URLRequest(url: request.url, timeoutInterval: request.timeout)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.emptyResponse
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw NetworkError.httpError(httpResponse.statusCode, body)
        }
        return (data, httpResponse)
    }
}
