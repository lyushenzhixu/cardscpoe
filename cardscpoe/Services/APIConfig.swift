import Foundation

enum APIConfig {
    static var supabaseURL: URL? {
        urlValue(for: "SUPABASE_URL")
    }

    static var supabaseAnonKey: String {
        stringValue(for: "SUPABASE_ANON_KEY")
    }

    static var supabaseServiceRoleKey: String {
        stringValue(for: "SUPABASE_SERVICE_ROLE_KEY")
    }

    static var priceChartingKey: String {
        stringValue(for: "PRICECHARTING_API_KEY")
    }

    static var sportsDBKey: String {
        let configured = stringValue(for: "SPORTSDB_API_KEY")
        return configured.isEmpty ? "1" : configured
    }

    static var balldontlieKey: String {
        stringValue(for: "BALLDONTLIE_API_KEY")
    }

    static var appEnvironment: String {
        stringValue(for: "APP_ENV")
    }

    private static func stringValue(for key: String) -> String {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            return value
        }
        return ""
    }

    private static func urlValue(for key: String) -> URL? {
        let raw = stringValue(for: key)
        guard !raw.isEmpty else { return nil }
        return URL(string: raw)
    }
}
