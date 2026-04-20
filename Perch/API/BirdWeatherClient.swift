import Foundation

enum APIError: Error, LocalizedError {
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .httpError(let code, _): return "API error \(code)"
        }
    }
}

actor BirdWeatherClient {
    static let shared = BirdWeatherClient()
    private let base = URL(string: "https://app.birdweather.com/api/v1")!

    private func fetch<T: Decodable>(_ path: String, token: String) async throws -> T {
        var components = URLComponents(url: base.appendingPathComponent(path),
                                       resolvingAgainstBaseURL: true)!
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "token", value: token))
        components.queryItems = items

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            throw APIError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func fetchStation(_ stationId: String, token: String) async throws -> Station {
        let r: Envelope<Station> = try await fetch("stations/\(stationId)", token: token)
        return r.station!
    }

    func fetchRecentRecords(stationId: String, token: String, cursor: String? = nil) async throws -> RecordsPage {
        var path = "stations/\(stationId)/detections?limit=50"
        if let c = cursor { path += "&cursor=\(c)" }
        return try await fetch(path, token: token)
    }

    func fetchRecord(id: String, token: String) async throws -> Detection {
        let r: Envelope<Detection> = try await fetch("detections/\(id)", token: token)
        return r.detection!
    }

    func fetchRecordsForSpecies(stationId: String, speciesId: String, token: String, limit: Int = 10) async throws -> [Detection] {
        let path = "stations/\(stationId)/detections?limit=\(limit)&speciesId=\(speciesId)"
        let page: RecordsPage = try await fetch(path, token: token)
        return page.records
    }

    func fetchTopSpecies(stationId: String, token: String, limit: Int = 200) async throws -> [Species] {
        let r: Envelope<[Species]> = try await fetch("stations/\(stationId)/species?limit=\(limit)", token: token)
        return r.species!
    }

    func fetchSpecies(id: String, token: String) async throws -> Species {
        let r: Envelope<Species> = try await fetch("species/\(id)", token: token)
        return r.species!
    }

    func fetchStats(stationId: String, token: String) async throws -> Stats {
        let r: Envelope<Stats> = try await fetch("stations/\(stationId)/stats", token: token)
        return r.stats!
    }

    func fetchDailyCounts(stationId: String, token: String, days: Int = 14) async throws -> [DailyCount] {
        let r: Envelope<[DailyCount]> = try await fetch("stations/\(stationId)/daily?days=\(days)", token: token)
        return r.daily!
    }
}

// Single flexible envelope that covers all API response shapes.
private struct Envelope<T: Decodable>: Decodable {
    var station: T?
    var detection: T?
    var species: T?
    var stats: T?
    var daily: T?
}
