import SwiftUI

struct SpeciesDetailView: View {
    let speciesId: String
    @Environment(AppState.self) private var appState
    @State private var species: Species?
    @State private var recentRecords: [Detection] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            if isLoading && species == nil {
                ProgressView().padding(.top, 60)
            } else if let sp = species {
                VStack(alignment: .leading, spacing: 0) {
                    heroImage(for: sp)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sp.commonName).font(.title.bold())
                                Text(sp.scientificName).italic().foregroundStyle(.secondary)
                            }
                            Spacer()
                            favoriteButton
                        }
                        Text("\(sp.count.formatted()) detections at this station")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding()

                    if !recentRecords.isEmpty {
                        Divider()
                        Text("Recent sightings")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 12)

                        ForEach(recentRecords) { record in
                            NavigationLink {
                                RecordDetailView(detection: record)
                            } label: {
                                RecordCard(record: record)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 84)
                        }
                    }
                }
            }
        }
        .navigationTitle(species?.commonName ?? "Species")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: speciesId) { await load() }
    }

    @ViewBuilder
    private func heroImage(for sp: Species) -> some View {
        if let urlStr = sp.imageUrl {
            AsyncImage(url: URL(string: urlStr)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.15)
            }
            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
            .clipped()
        }
    }

    private var favoriteButton: some View {
        let isFav = appState.isFavorite(speciesId)
        return Button {
            appState.toggleFavorite(speciesId)
        } label: {
            Image(systemName: isFav ? "star.fill" : "star")
                .font(.title2)
                .foregroundStyle(isFav ? .yellow : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func load() async {
        guard let tok = appState.token, let sid = appState.stationId else { return }
        isLoading = true
        async let sp   = BirdWeatherClient.shared.fetchSpecies(id: speciesId, token: tok)
        async let recs = BirdWeatherClient.shared.fetchRecordsForSpecies(
            stationId: sid, speciesId: speciesId, token: tok)
        species       = try? await sp
        recentRecords = (try? await recs) ?? []
        isLoading = false
    }
}
