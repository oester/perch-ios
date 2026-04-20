import SwiftUI

struct SpeciesListView: View {
    @Environment(AppState.self) private var appState
    @State private var species: [Species] = []
    @State private var isLoading = false
    @State private var error: Error?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && species.isEmpty {
                    ProgressView()
                } else if error != nil && species.isEmpty {
                    ContentUnavailableView(
                        "Could not load species",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Check your connection and try again.")
                    )
                } else {
                    List(species) { sp in
                        NavigationLink {
                            SpeciesDetailView(speciesId: sp.id)
                        } label: {
                            SpeciesRow(species: sp)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Species")
            .task(id: appState.stationId) { await load() }
        }
    }

    private func load() async {
        guard let sid = appState.stationId, let tok = appState.token else { return }
        isLoading = true
        do {
            species = try await BirdWeatherClient.shared.fetchTopSpecies(stationId: sid, token: tok)
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
