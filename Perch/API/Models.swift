import Foundation

// API returns the station object at root (no wrapper key).
// id is an Int in the JSON; other fields (coords, timezone) are unused by the app.
struct Station: Decodable {
    let id: Int
    let name: String
}

struct Detection: Codable, Identifiable {
    let id: String
    let speciesId: String
    let commonName: String
    let scientificName: String
    let timestamp: String
    let confidence: Double
    let soundscapeUrl: String?
    let imageUrl: String?

    var parsedDate: Date? {
        ISO8601DateFormatter().date(from: timestamp)
    }
}

struct RecordsPage: Codable {
    let records: [Detection]
    let cursor: String?
}

struct Stats: Codable {
    let totalRecords: Int
    let uniqueSpecies: Int
    let recordsToday: Int
}

struct Species: Codable, Identifiable {
    let id: String
    let commonName: String
    let scientificName: String
    let imageUrl: String?
    let count: Int
}

struct DailyCount: Codable, Identifiable {
    let date: String
    let count: Int
    var id: String { date }
}
