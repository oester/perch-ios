import SwiftUI

// MARK: - Loader

@MainActor
@Observable
final class FeedLoader {
    private(set) var records: [Detection] = []
    private(set) var isLoading    = false
    private(set) var isLoadingMore = false
    private(set) var error: Error?
    private var cursor: String?
    private var hasMore = true

    let stationId: String
    let token: String

    init(stationId: String, token: String) {
        self.stationId = stationId
        self.token     = token
    }

    func refresh() async {
        isLoading = true
        error     = nil
        cursor    = nil
        hasMore   = true
        do {
            let page = try await BirdWeatherClient.shared.fetchRecentRecords(
                stationId: stationId, token: token)
            records = page.records
            cursor  = page.cursor
            hasMore = page.cursor != nil
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, let c = cursor else { return }
        isLoadingMore = true
        do {
            let page = try await BirdWeatherClient.shared.fetchRecentRecords(
                stationId: stationId, token: token, cursor: c)
            records.append(contentsOf: page.records)
            cursor  = page.cursor
            hasMore = page.cursor != nil
        } catch { /* silently ignore pagination errors */ }
        isLoadingMore = false
    }
}

// MARK: - View

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @State private var loader: FeedLoader?

    var body: some View {
        NavigationStack {
            Group {
                if let loader {
                    FeedContentView(loader: loader)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Feed")
            .task(id: appState.stationId) {
                guard let sid = appState.stationId, let tok = appState.token else { return }
                let l = FeedLoader(stationId: sid, token: tok)
                loader = l
                await l.refresh()
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(60))
                    await l.refresh()
                }
            }
        }
    }
}

// MARK: - Content

struct FeedContentView: View {
    @Environment(AppState.self) private var appState
    var loader: FeedLoader

    var body: some View {
        List {
            ForEach(loader.records) { record in
                NavigationLink {
                    RecordDetailView(detection: record)
                } label: {
                    RecordCard(record: record)
                }
                .listRowInsets(EdgeInsets())
                .onAppear {
                    if record.id == loader.records.last?.id {
                        Task { await loader.loadMore() }
                    }
                    if appState.isFavorite(record.speciesId) {
                        NotificationManager.shared.scheduleIfNeeded(for: record)
                    }
                }
            }
            if loader.isLoadingMore {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable { await loader.refresh() }
        .overlay {
            if loader.isLoading && loader.records.isEmpty {
                ProgressView()
            }
            if loader.error != nil && loader.records.isEmpty {
                ContentUnavailableView {
                    Label("Could not load sightings", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("Check your connection and station settings.")
                } actions: {
                    Button("Retry") { Task { await loader.refresh() } }
                }
            }
        }
    }
}
