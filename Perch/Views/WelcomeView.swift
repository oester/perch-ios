import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bird.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Perch")
                .font(.system(size: 40, weight: .bold))
            Text("A companion for your backyard bird station.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            NavigationLink {
                ConnectView()
            } label: {
                Text("Connect your station")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}
