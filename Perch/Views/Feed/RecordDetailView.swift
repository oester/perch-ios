import SwiftUI
import AVFoundation

// MARK: - Audio

@Observable
final class AudioPlayer: @unchecked Sendable {
    private var player: AVPlayer?
    var isPlaying = false
    var isLoading = false

    func toggle(url: URL) async {
        if let p = player {
            if isPlaying { p.pause(); isPlaying = false }
            else         { p.play();  isPlaying = true  }
            return
        }
        isLoading = true
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        let p = AVPlayer(url: url)
        player    = p
        isLoading = false
        p.play()
        isPlaying = true

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: p.currentItem, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.isPlaying = false }
        }
    }

    func stop() {
        player?.pause()
        player    = nil
        isPlaying = false
    }
}

// MARK: - View

struct RecordDetailView: View {
    let detection: Detection
    @Environment(AppState.self) private var appState
    @State private var audio        = AudioPlayer()
    @State private var shareImage: UIImage?
    @State private var isSharing    = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage

                VStack(alignment: .leading, spacing: 8) {
                    Text(detection.commonName).font(.title.bold())
                    Text(detection.scientificName).italic().foregroundStyle(.secondary)

                    confidenceBadge.padding(.vertical, 2)

                    if let date = detection.parsedDate {
                        Text(date, style: .date) + Text("  ") + Text(date, style: .time)
                    }
                    if let name = appState.stationName {
                        Text(name).foregroundStyle(.secondary).font(.callout)
                    }
                }
                .padding()

                Divider()

                VStack(spacing: 12) {
                    if let urlStr = detection.soundscapeUrl, let url = URL(string: urlStr) {
                        Button {
                            Task { await audio.toggle(url: url) }
                        } label: {
                            HStack {
                                if audio.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                    Text(audio.isPlaying ? "Pause" : "Play recording")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(audio.isLoading)
                    }

                    Button {
                        shareDetection()
                    } label: {
                        Label("Share sighting", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .navigationTitle(detection.commonName)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { audio.stop() }
        .sheet(isPresented: $isSharing) {
            if let img = shareImage {
                ShareSheet(items: [img])
            }
        }
    }

    private var heroImage: some View {
        AsyncImage(url: URL(string: detection.imageUrl ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.secondary.opacity(0.15)
        }
        .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240)
        .clipped()
    }

    private var confidenceBadge: some View {
        let pct   = Int(detection.confidence * 100)
        let color: Color = detection.confidence >= 0.8 ? .green
                         : detection.confidence >= 0.5 ? .yellow : .red
        return Text("\(pct)% confidence")
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
    }

    private func shareDetection() {
        let renderer = ImageRenderer(content: DetectionShareCard(detection: detection))
        renderer.scale = UIScreen.main.scale
        shareImage = renderer.uiImage
        isSharing  = true
    }
}

// MARK: - Share card

struct DetectionShareCard: View {
    let detection: Detection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: detection.imageUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.15)
            }
            .frame(width: 320, height: 180)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(detection.commonName).font(.headline.bold())
                Text(detection.scientificName).italic().foregroundStyle(.secondary).font(.callout)
            }
            .padding(12)
        }
        .frame(width: 320)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
