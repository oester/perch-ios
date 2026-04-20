import SwiftUI

struct ConnectView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var token     = ""
    @State private var stationId = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !token.trimmingCharacters(in: .whitespaces).isEmpty &&
        !stationId.trimmingCharacters(in: .whitespaces).isEmpty &&
        stationId.trimmingCharacters(in: .whitespaces).allSatisfy(\.isNumber) &&
        !isLoading
    }

    var body: some View {
        Form {
            Section {
                SecureField("BirdWeather API token", text: $token)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("Station ID (e.g. 12345)", text: $stationId)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
            } footer: {
                Text("Find your token and station ID on your BirdWeather station's settings page.")
            }

            if let msg = errorMessage {
                Section {
                    Label(msg, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }

            Section {
                Button {
                    Task { await connect() }
                } label: {
                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Connect").frame(maxWidth: .infinity)
                    }
                }
                .disabled(!canSubmit)
            }
        }
        .navigationTitle("Connect station")
    }

    private func connect() async {
        let t = token.trimmingCharacters(in: .whitespaces)
        let s = stationId.trimmingCharacters(in: .whitespaces)
        isLoading    = true
        errorMessage = nil
        do {
            let station = try await BirdWeatherClient.shared.fetchStation(s, token: t)
            appState.connect(token: t, stationId: s, stationName: station.name)
        } catch APIError.httpError(401, _), APIError.httpError(403, _) {
            errorMessage = "Invalid token — check your BirdWeather API token and try again."
        } catch APIError.httpError(404, _) {
            errorMessage = "Station not found — check your station ID and try again."
        } catch APIError.httpError(let code, _) {
            errorMessage = "The station returned an error (\(code)). Please try again later."
        } catch is DecodingError {
            errorMessage = "Could not read station data — the server response was unexpected. Check the Xcode console for details."
        } catch {
            errorMessage = "Network error — check your internet connection and try again. (\(error.localizedDescription))"
        }
        isLoading = false
    }
}
