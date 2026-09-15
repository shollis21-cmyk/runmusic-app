import Foundation
import RunMusicCore

#if canImport(MusicKit)
import MusicKit

public actor AppleMusicRuntimeAdapter: MusicCatalogProvider, MusicQueueProvider {
    public let providerName = "Apple Music"
    private let player = ApplicationMusicPlayer.shared

    public init() {}

    public func search(_ query: MusicCatalogQuery) async throws -> [MusicTrack] {
        guard MusicAuthorization.currentStatus == .authorized else { throw ProviderRuntimeError.authorizationRequired(providerName) }
        var request = MusicCatalogSearchRequest(term: query.searchTerm, types: [Song.self])
        request.limit = query.limit
        let response = try await request.response()
        return response.songs.map(Self.map)
    }

    public func resolve(trackIDs: [String]) async throws -> [MusicTrack] {
        guard MusicAuthorization.currentStatus == .authorized else { throw ProviderRuntimeError.authorizationRequired(providerName) }
        let ids = trackIDs.map(MusicItemID.init)
        var request = MusicCatalogResourceRequest<Song>(matching: \Song.id, memberOf: ids)
        request.limit = max(ids.count, 1)
        return try await request.response().items.map(Self.map)
    }

    public func prepare(plan: PlaylistPlan) async throws {
        guard MusicAuthorization.currentStatus == .authorized else { throw ProviderRuntimeError.authorizationRequired(providerName) }
        let ids = plan.entries.compactMap { $0.track.providerIDs[.appleMusic] }.map(MusicItemID.init)
        guard !ids.isEmpty else { throw ProviderRuntimeError.unavailable("No Apple Music IDs are present in the plan") }
        var request = MusicCatalogResourceRequest<Song>(matching: \Song.id, memberOf: ids)
        request.limit = ids.count
        let songsByID = Dictionary(uniqueKeysWithValues: try await request.response().items.map { ($0.id.rawValue, $0) })
        let ordered = ids.compactMap { songsByID[$0.rawValue] }
        player.queue = ApplicationMusicPlayer.Queue(for: ordered)
    }

    public func play() async throws { try await player.play() }
    public func pause() async throws { player.pause() }

    private static func map(_ song: Song) -> MusicTrack {
        MusicTrack(
            id: "apple:\(song.id.rawValue)",
            isrc: song.isrc,
            title: song.title,
            artist: song.artistName,
            durationSeconds: song.duration ?? 0,
            bpm: nil,
            energy: nil,
            familiarity: 0.5,
            preferenceScore: 0.5,
            explicit: song.contentRating == .explicit,
            providerIDs: [.appleMusic: song.id.rawValue]
        )
    }
}

#else

public struct AppleMusicRuntimeAdapter: MusicCatalogProvider, MusicQueueProvider {
    public let providerName = "Apple Music"
    public init() {}
    public func search(_ query: MusicCatalogQuery) async throws -> [MusicTrack] { throw ProviderRuntimeError.unavailable("MusicKit is unavailable on this platform") }
    public func resolve(trackIDs: [String]) async throws -> [MusicTrack] { throw ProviderRuntimeError.unavailable("MusicKit is unavailable on this platform") }
    public func prepare(plan: PlaylistPlan) async throws { throw ProviderRuntimeError.unavailable("MusicKit is unavailable on this platform") }
    public func play() async throws { throw ProviderRuntimeError.unavailable("MusicKit is unavailable on this platform") }
    public func pause() async throws { throw ProviderRuntimeError.unavailable("MusicKit is unavailable on this platform") }
}

#endif
