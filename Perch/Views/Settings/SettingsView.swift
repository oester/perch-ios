import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var notificationsEnabled = false
    @State private var showDisconnectConfirm = false

    private var themeBinding: Binding<String> {
        Binding(
            get: {
                switch appState.theme {
                case .light: return "light"
                case .dark:  return "dark"
                default:     return "system"
                }
            },
            set: { v in
                switch v {
                case "light": appState.setTheme(.light)
                case "dark":  appState.setTheme(.dark)
                default:      appState.setTheme(nil)
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: themeBinding) {
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                        Text("System").tag("system")
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Notifications") {
                    Toggle("Favorite species alerts", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    let granted = await NotificationManager.shared.requestPermission()
                                    if !granted { notificationsEnabled = false }
                                }
                            }
                        }
                }

                if let stationId = appState.stationId {
                    Section("Station") {
                        LabeledContent("Name", value: appState.stationName ?? stationId)
                        LabeledContent("ID",   value: stationId)
                        Button("Disconnect station", role: .destructive) {
                            showDisconnectConfirm = true
                        }
                    }
                }

                Section {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Disconnect station?",
                isPresented: $showDisconnectConfirm,
                titleVisibility: .visible
            ) {
                Button("Disconnect", role: .destructive) { appState.disconnect() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need your token and station ID to reconnect.")
            }
        }
    }
}
