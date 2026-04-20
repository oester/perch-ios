import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Feed", systemImage: "bird") }
            SpeciesListView()
                .tabItem { Label("Species", systemImage: "list.bullet") }
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "star") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(.green)
    }
}
