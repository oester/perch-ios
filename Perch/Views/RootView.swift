import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.stationId != nil {
            MainTabView()
        } else {
            NavigationStack {
                WelcomeView()
            }
        }
    }
}
