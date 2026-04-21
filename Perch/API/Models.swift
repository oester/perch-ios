import Foundation

// MARK: - Station
// Returned at root — no wrapper. id is Int in the API.
struct Station: Decodable {
    let id: Int
    let name: String
}

// MARK: - Detection
// The API nests species info and soundscape inside each detection record.
// Computed properties expose the flat field names the views already use.
struct Detection: Decodable, Identifiable {
    let id: Int
    let timestamp: String
    let confidence: Double
    let species: EmbeddedSpecies
    let soundscape: EmbeddedSoundscape?

    // Flat aliases used throughout the UI
    var speciesId: String      { String(species.id) }
    var commonName: String     { species.commonName }
    var scientificName: String { species.scientificName }
    var imageUrl: String?      { species.imageUrl }
    var soundscapeUrl: String? { soundscape?.url }

    var parsedDate: Date? { ISO8601DateFormatter().date(from: timestamp) }
}

struct EmbeddedSpecies: Decodable {
    let id: Int
    let commonName: String
    let scientificName: String
    let imageUrl: String?
}

struct EmbeddedSoundscape: Decodable {
    let url: String
}

// MARK: - RecordsPage
// JSON key for the array is "detections"; cursor may be absent when no more pages.
struct RecordsPage: Decodable {
    let records: [Detection]
    let cursor: String?

    enum CodingKeys: String, CodingKey {
        case records = "detections"
        case cursor
    }
}

// MARK: - Species
// id arrives as Int; stored as String to match favorites (Set<String>) and
// Detection.speciesId. Detection count lives in a nested "detections" object.
struct Species: Decodable, Identifiable {
    let id: String
    let commonName: String
    let scientificName: String
    let imageUrl: String?
    let count: Int          // sourced from detections.total

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? c.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try c.decode(String.self, forKey: .id)
        }
        commonName     = try c.decode(String.self, forKey: .commonName)
        scientificName = try c.decode(String.self, forKey: .scientificName)
        imageUrl       = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        // Total detection count is nested under "detections": {"total": N, ...}
        let detections = try c.decodeIfPresent(SpeciesDetectionCounts.self, forKey: .detections)
        count          = detections?.total ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id, commonName, scientificName, imageUrl, detections
    }
}

private struct SpeciesDetectionCounts: Decodable {
    let total: Int
}

// MARK: - Stats
// API returns at root: {"success":true,"detections":N,"species":N}
struct Stats: Decodable {
    let totalRecords: Int
    let uniqueSpecies: Int

    enum CodingKeys: String, CodingKey {
        case totalRecords = "detections"
        case uniqueSpecies = "species"
    }
}

// MARK: - DailyCount
struct DailyCount: Decodable, Identifiable {
    let date: String
    let count: Int
    var id: String { date }
}
