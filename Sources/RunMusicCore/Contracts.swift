import Foundation

public protocol ActivityIngestionProvider: Sendable {
    var source: DataSource { get }
    func fetchActivities(since: Date?) async throws -> [CanonicalActivity]
}

public protocol RunnerModeling: Sendable {
    func buildProfile(from activities: [CanonicalActivity], manualFallback: RunnerProfile?) -> RunnerProfile
}

public protocol MusicIntelligenceProviding: Sendable {
    func candidateTracks(preference: MusicPreference, limit: Int) async throws -> [MusicTrack]
}

public protocol PlaylistOptimizing: Sendable {
    func optimize(request: RunRequest, runner: RunnerProfile, preference: MusicPreference, candidates: [MusicTrack]) throws -> PlaylistPlan
}

public protocol PlaybackExporting: Sendable {
    var provider: MusicProvider { get }
    func export(plan: PlaylistPlan, name: String) async throws -> URL?
    func readiness(plan: PlaylistPlan) async throws -> PlaybackReadiness
}

public struct PlaybackReadiness: Sendable, Equatable {
    public let availableTrackIDs: Set<String>
    public let unavailableTrackIDs: Set<String>
    public let offlineGuaranteed: Bool
    public let warnings: [String]

    public init(availableTrackIDs: Set<String>, unavailableTrackIDs: Set<String>, offlineGuaranteed: Bool, warnings: [String] = []) {
        self.availableTrackIDs = availableTrackIDs
        self.unavailableTrackIDs = unavailableTrackIDs
        self.offlineGuaranteed = offlineGuaranteed
        self.warnings = warnings
    }
}
