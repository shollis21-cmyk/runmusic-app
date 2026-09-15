import Foundation

public enum ProviderAdapterError: Error, Sendable, Equatable {
    case notConfigured(String)
    case authorizationRequired
    case unsupported(String)
}

/// Stable shells for platform-specific implementations. Production iOS/watchOS targets will
/// implement these contracts with HealthKit, Strava OAuth, Garmin APIs, MusicKit, and Spotify.
public struct UnconfiguredActivityProvider: ActivityIngestionProvider {
    public let source: DataSource
    public let configurationHint: String
    public init(source: DataSource, configurationHint: String) {
        self.source = source
        self.configurationHint = configurationHint
    }
    public func fetchActivities(since: Date?) async throws -> [CanonicalActivity] {
        throw ProviderAdapterError.notConfigured(configurationHint)
    }
}

public struct UnconfiguredPlaybackExporter: PlaybackExporting {
    public let provider: MusicProvider
    public let configurationHint: String
    public init(provider: MusicProvider, configurationHint: String) {
        self.provider = provider
        self.configurationHint = configurationHint
    }
    public func export(plan: PlaylistPlan, name: String) async throws -> URL? {
        throw ProviderAdapterError.notConfigured(configurationHint)
    }
    public func readiness(plan: PlaylistPlan) async throws -> PlaybackReadiness {
        throw ProviderAdapterError.notConfigured(configurationHint)
    }
}

public struct StaticMusicIntelligenceProvider: MusicIntelligenceProviding {
    private let tracks: [MusicTrack]
    public init(tracks: [MusicTrack]) { self.tracks = tracks }
    public func candidateTracks(preference: MusicPreference, limit: Int) async throws -> [MusicTrack] {
        Array(tracks.sorted { $0.preferenceScore > $1.preferenceScore }.prefix(max(1, limit)))
    }
}
