import Foundation

enum APIError: Error, LocalizedError {
    case httpError(Int, String)
    case missingData

    var errorDescription: String? {
        switch self {
        case .httpError(let code, _): return "API error \(code)"
        case .missingData:            return "Unexpected response from server"
        }
    }
}

actor BirdWeatherClient {
    static let shared = BirdWeatherClient()
    private let baseURL = "https://app.birdweather.com/api/v1"

    // Builds the URL from a path string that may already contain query params,
    // then appends the token. Using URLComponents(string:) instead of
    // appendingPathComponent avoids percent-encoding '?' and '/' in the path.
    private func fetch<T: Decodable>(_ path: String, token: String) async throws -> T {
        guard var components = URLComponents(string: "\(baseURL)/\(path)") else {
            throw URLError(.badURL)
        }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "token", value: token))
        components.queryItems = items
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            throw APIError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Endpoints

    func fetchStation(_ stationId: String, token: String) async throws -> Station {
        let r: StationResponse = try await fetch("stations/\(stationId)", token: token)
        return r.station
    }

    func fetchRecentRecords(stationId: String, token: String, cursor: String? = nil) async throws -> RecordsPage {
        var path = "stations/\(stationId)/detections?limit=50"
        if let c = cursor { path += "&cursor=\(c)" }
        return try await fetch(path, token: token)
    }

    func fetchRecord(id: String, token: String) async throws -> Detection {
        let r: DetectionResponse = try await fetch("detections/\(id)", token: token)
        return r.detection
    }

    func fetchRecordsForSpecies(stationId: String, speciesId: String, token: String, limit: Int = 10) async throws -> [Detection] {
        let path = "stations/\(stationId)/detections?limit=\(limit)&speciesId=\(speciesId)"
        let page: RecordsPage = try await fetch(path, token: token)
        return page.records
    }

    func fetchTopSpecies(stationId: String, token: String, limit: Int = 200) async throws -> [Species] {
        let r: SpeciesListResponse = try await fetch("stations/\(stationId)/species?limit=\(limit)", token: token)
        return r.species
    }

    func fetchSpecies(id: String, token: String) async throws -> Species {
        let r: SpeciesResponse = try await fetch("species/\(id)", token: token)
        return r.species
    }

    func fetchStats(stationId: String, token: String) async throws -> Stats {
        let r: StatsResponse = try await fetch("stations/\(stationId)/stats", token: token)
        return r.stats
    }

    func fetchDailyCounts(stationId: String, token: String, days: Int = 14) async throws -> [DailyCount] {
        let r: DailyResponse = try await fetch("stations/\(stationId)/daily?days=\(days)", token: token)
        return r.daily
    }
}

// MARK: - Response wrappers (one per endpoint shape)

private struct StationResponse:   Decodable { let station:   Station      }
private struct DetectionResponse: Decodable { let detection: Detection    }
private struct SpeciesListResponse:Decodable{ let species:   [Species]    }
private struct SpeciesResponse:   Decodable { let species:   Species      }
private struct StatsResponse:     Decodable { let stats:     Stats        }
private struct DailyResponse:     Decodable { let daily:     [DailyCount] }
