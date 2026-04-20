import SwiftUI

struct FavoritesView: View {
    @Environment(AppState.self) private var appState
    @State private var loaded: [Species] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if appState.favorites.isEmpty {
                    ContentUnavailableView(
                        "No favorites yet",
                        systemImage: "star",
                        description: Text("Star a species on its detail page to see it here.")
                    )
                } else if isLoading && loaded.isEmpty {
                    ProgressView()
                } else {
                    List(loaded) { sp in
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
            .navigationTitle("Favorites")
            .task(id: appState.favorites) { await loadFavorites() }
        }
    }

    private func loadFavorites() async {
        guard let tok = appState.token else { return }
        isLoading = true
        loaded = await withTaskGroup(of: Species?.self) { group in
            for id in appState.favorites {
                group.addTask {
                    try? await BirdWeatherClient.shared.fetchSpecies(id: id, token: tok)
                }
            }
            var results: [Species] = []
            for await sp in group { if let sp { results.append(sp) } }
            return results.sorted { $0.commonName < $1.commonName }
        }
        isLoading = false
    }
}
