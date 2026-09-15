#if canImport(SwiftUI)
import SwiftUI
import RunMusicCore

public struct RunMusicRootView: View {
    @StateObject private var model: RunMusicAppViewModel

    public init(model: RunMusicAppViewModel = RunMusicAppViewModel()) {
        _model = StateObject(wrappedValue: model)
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch model.screen {
                case .onboarding:
                    OnboardingView(model: model)
                case .home:
                    HomeView(model: model)
                case .buildRun:
                    BuildRunView(model: model)
                case .plan:
                    PlanView(model: model)
                case .ready:
                    Text("Ready")
                case .liveRun:
                    Text("Run in progress")
                case .postRun:
                    Text("Run complete")
                }
            }
            .animation(.snappy, value: model.screen)
        }
    }
}

private struct OnboardingView: View {
    @ObservedObject var model: RunMusicAppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("Music that learns how you run.")
                .font(.largeTitle.bold())
            Text("Connect your running and music services, or start manually. We will build around the data you have.")
                .font(.title3)
                .foregroundStyle(.secondary)
            VStack(spacing: 12) {
                connectionRow(title: "Running data", subtitle: "Apple Health, Strava, Garmin")
                connectionRow(title: "Music", subtitle: "Apple Music, Spotify")
            }
            Button("Continue with manual setup") {
                model.useManualRunnerProfile(RunnerProfile(preferredUnitsMiles: true, typicalCadenceSPM: 170, dataConfidence: 0.25))
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(24)
    }

    private func connectionRow(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title).fontWeight(.semibold)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct HomeView: View {
    @ObservedObject var model: RunMusicAppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("RunMusic")
                    .font(.largeTitle.bold())
                Text("Build a run around how you actually move.")
                    .foregroundStyle(.secondary)
                Button("Build My Run") { model.showBuildRun() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                if !model.connectionHealth.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Connection health").font(.headline)
                        ForEach(model.connectionHealth.indices, id: \.self) { idx in
                            let health = model.connectionHealth[idx]
                            HStack {
                                Circle().fill(health.requiresAttention ? Color.orange : Color.green).frame(width: 8, height: 8)
                                Text(health.displayName)
                                Spacer()
                                Text(health.message).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                Spacer(minLength: 80)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
}

private struct BuildRunView: View {
    @ObservedObject var model: RunMusicAppViewModel
    @State private var miles = 5.0
    @State private var paceMinutes = 9
    @State private var paceSeconds = 0

    var body: some View {
        Form {
            Section("Run") {
                HStack { Text("Distance"); Spacer(); Text(String(format: "%.1f mi", miles)).foregroundStyle(.secondary) }
                Slider(value: $miles, in: 1...26.2, step: 0.5)
                Stepper("Pace: \(paceMinutes):\(String(format: "%02d", paceSeconds))/mi", value: $paceMinutes, in: 5...15)
            }
            Section("Runner") {
                Text("Cadence: \(model.runnerProfile.typicalCadenceSPM.map(String.init) ?? "Not set") spm")
                Text("Confidence: \(Int(model.runnerProfile.dataConfidence * 100))%")
            }
            if let error = model.errorMessage { Text(error).foregroundStyle(.red) }
            Button("Generate Run Plan") {
                let pace = TimeInterval(paceMinutes * 60 + paceSeconds)
                let request = RunRequest(distanceMeters: miles * 1609.344, targetDurationSeconds: miles * pace, workoutType: .easy)
                Task { await model.buildRun(request) }
            }
        }
        .navigationTitle("Build My Run")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Home") { model.showHome() } } }
    }
}

private struct PlanView: View {
    @ObservedObject var model: RunMusicAppViewModel

    var body: some View {
        List {
            if let plan = model.currentPlan {
                Section("Plan") {
                    HStack {
                        Image(systemName: "music.note.list")
                        VStack(alignment: .leading) {
                            Text("Run playlist").font(.headline)
                            Text("\(plan.entries.count) songs · \(plan.markers.count) markers")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Mile markers") {
                    ForEach(plan.markers.indices, id: \.self) { index in
                        let marker = plan.markers[index]
                        HStack {
                            Text("Mile \(marker.milestoneNumber)")
                            Spacer()
                            Text(formatTime(marker.targetTimeSeconds)).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Playlist") {
                    ForEach(plan.entries.indices, id: \.self) { index in
                        let entry = plan.entries[index]
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.track.title).fontWeight(.semibold)
                            Text("\(entry.track.artist) · starts \(formatTime(entry.startsAtSeconds))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Run Plan")
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let value = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", value / 60, value % 60)
    }
}

#else
import Foundation

@MainActor
public struct RunMusicRootView {
    public init(model: RunMusicAppViewModel) {}
}
#endif
