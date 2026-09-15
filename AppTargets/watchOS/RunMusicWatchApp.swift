import SwiftUI

@main
struct RunMusicWatchApp: App {
    var body: some Scene {
        WindowGroup { WatchHomeView() }
    }
}

private struct WatchHomeView: View {
    @State private var isReady = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(.blue)
            Text("RunMusic").font(.headline)
            Text(isReady ? "Run plan ready" : "Open RunMusic on iPhone to build a run")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if isReady {
                Button("Start Run") { }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
