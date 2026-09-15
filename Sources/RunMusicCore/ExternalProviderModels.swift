import Foundation

public struct ExternalActivity: Codable, Sendable, Equatable {
    public let providerID: String
    public let source: DataSource
    public let startedAt: Date
    public let durationSeconds: TimeInterval
    public let distanceMeters: Double
    public let averageHeartRateBPM: Double?
    public let averageCadenceSPM: Double?
    public let averagePowerWatts: Double?
    public let samples: [ActivitySample]
    public init(providerID: String, source: DataSource, startedAt: Date, durationSeconds: TimeInterval, distanceMeters: Double, averageHeartRateBPM: Double? = nil, averageCadenceSPM: Double? = nil, averagePowerWatts: Double? = nil, samples: [ActivitySample] = []) {
        self.providerID = providerID; self.source = source; self.startedAt = startedAt; self.durationSeconds = durationSeconds; self.distanceMeters = distanceMeters; self.averageHeartRateBPM = averageHeartRateBPM; self.averageCadenceSPM = averageCadenceSPM; self.averagePowerWatts = averagePowerWatts; self.samples = samples
    }
}

public enum ExternalActivityMapper {
    public static func canonicalize(_ activity: ExternalActivity, confidence: Double = 0.9) -> CanonicalActivity {
        let pace = activity.distanceMeters > 0 ? activity.durationSeconds / (activity.distanceMeters / 1000) : nil
        return CanonicalActivity(startedAt: activity.startedAt, durationSeconds: activity.durationSeconds, distanceMeters: activity.distanceMeters, primarySource: activity.source, sourceActivityIDs: [activity.source: activity.providerID], averagePaceSecondsPerKilometer: pace.map { .init(value: $0, source: activity.source, confidence: confidence) }, averageHeartRateBPM: activity.averageHeartRateBPM.map { .init(value: $0, source: activity.source, confidence: confidence) }, averageCadenceSPM: activity.averageCadenceSPM.map { .init(value: $0, source: activity.source, confidence: confidence) }, averagePowerWatts: activity.averagePowerWatts.map { .init(value: $0, source: activity.source, confidence: confidence) }, samples: activity.samples)
    }
}

public struct PlaylistExportPayload: Codable, Sendable, Equatable {
    public let name: String
    public let orderedProviderTrackIDs: [String]
    public let missingTrackIDs: [String]
    public init(plan: PlaylistPlan, provider: MusicProvider, name: String) {
        self.name = name
        var ordered: [String] = []; var missing: [String] = []
        for entry in plan.entries {
            if let id = entry.track.providerIDs[provider] { ordered.append(id) } else { missing.append(entry.track.id) }
        }
        self.orderedProviderTrackIDs = ordered; self.missingTrackIDs = missing
    }
    public var isComplete: Bool { missingTrackIDs.isEmpty }
}
