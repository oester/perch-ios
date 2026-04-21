import SwiftUI
import Charts

struct StatsView: View {
    @Environment(AppState.self) private var appState
    @State private var stats: Stats?
    @State private var daily: [DailyCount] = []
    @State private var topSpecies: [Species] = []
    @State private var isLoading = true
    @State private var loadFailed = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if loadFailed && stats == nil {
                    ContentUnavailableView {
                        Label("Could not load stats", systemImage: "exclamationmark.triangle")
                    } actions: {
                        Button("Retry") { Task { await load() } }
                    }
                } else if let stats {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            summaryCards(stats)
                            if !daily.isEmpty { chartSection }
                            if !topSpecies.isEmpty { topSpeciesSection }
                        }
                        .padding()
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Stats")
            .task(id: appState.stationId) { await load() }
        }
    }

    private func summaryCards(_ stats: Stats) -> some View {
        HStack(spacing: 12) {
            StatCard(label: "Total records",  value: stats.totalRecords.formatted())
            StatCard(label: "Unique species", value: "\(stats.uniqueSpecies)")
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 14 days").font(.headline)
            Chart(daily) { point in
                BarMark(
                    x: .value("Date",       String(point.date.suffix(5))),
                    y: .value("Detections", point.count)
                )
                .foregroundStyle(.green)
                .cornerRadius(3)
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: 4)) { _ in
                    AxisValueLabel().font(.caption)
                    AxisGridLine()
                }
            }
        }
    }

    private var topSpeciesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top species").font(.headline)
            ForEach(Array(topSpecies.enumerated()), id: \.element.id) { i, sp in
                HStack {
                    Text("\(i + 1).")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .leading)
                    Text(sp.commonName).font(.callout.weight(.medium))
                    Spacer()
                    Text(sp.count.formatted()).font(.callout).foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                Divider()
            }
        }
    }

    private func load() async {
        guard let sid = appState.stationId, let tok = appState.token else { return }
        isLoading  = true
        loadFailed = false
        async let s = BirdWeatherClient.shared.fetchStats(stationId: sid, token: tok)
        async let d = BirdWeatherClient.shared.fetchDailyCounts(stationId: sid, token: tok)
        async let t = BirdWeatherClient.shared.fetchTopSpecies(stationId: sid, token: tok, limit: 10)
        stats      = try? await s
        daily      = (try? await d) ?? []
        topSpecies = (try? await t) ?? []
        loadFailed = (stats == nil)
        isLoading  = false
    }
}

struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(.green)
            Text(label).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}
