import SwiftUI
import Observation

@Observable
final class AppState {
    var stationId: String?
    var stationName: String?
    var token: String?
    var favorites: Set<String> = []
    var theme: ColorScheme?   // nil = system

    init() { hydrate() }

    // MARK: - Hydration

    private func hydrate() {
        token     = Keychain.get(Keychain.tokenKey)
        stationId = Keychain.get(Keychain.stationIdKey)

        if let raw = Keychain.get(Keychain.favoritesKey),
           let ids = try? JSONDecoder().decode([String].self, from: Data(raw.utf8)) {
            favorites = Set(ids)
        }

        switch Keychain.get(Keychain.themeKey) {
        case "light": theme = .light
        case "dark":  theme = .dark
        default:      theme = nil
        }
    }

    // MARK: - Station

    func connect(token: String, stationId: String, stationName: String) {
        Keychain.set(token,     forKey: Keychain.tokenKey)
        Keychain.set(stationId, forKey: Keychain.stationIdKey)
        self.token       = token
        self.stationId   = stationId
        self.stationName = stationName
    }

    func disconnect() {
        Keychain.delete(Keychain.tokenKey)
        Keychain.delete(Keychain.stationIdKey)
        token       = nil
        stationId   = nil
        stationName = nil
    }

    // MARK: - Favorites

    func toggleFavorite(_ id: String) {
        if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) }
        persistFavorites()
    }

    func isFavorite(_ id: String) -> Bool { favorites.contains(id) }

    private func persistFavorites() {
        if let data = try? JSONEncoder().encode(Array(favorites)),
           let str  = String(data: data, encoding: .utf8) {
            Keychain.set(str, forKey: Keychain.favoritesKey)
        }
    }

    // MARK: - Theme

    func setTheme(_ scheme: ColorScheme?) {
        theme = scheme
        let key: String
        switch scheme {
        case .light: key = "light"
        case .dark:  key = "dark"
        default:     key = "system"
        }
        Keychain.set(key, forKey: Keychain.themeKey)
    }
}
