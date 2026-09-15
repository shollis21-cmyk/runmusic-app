import Foundation

public struct ProviderRunQuery: Sendable, Equatable {
    public var start: Date
    public var end: Date
    public var limit: Int
    public init(start: Date, end: Date, limit: Int = 100) { self.start = start; self.end = end; self.limit = limit }
}

public protocol ActivityHistoryProvider: Sendable {
    var providerName: String { get }
    func fetchRuns(_ query: ProviderRunQuery) async throws -> [CanonicalActivity]
}

public struct MusicCatalogQuery: Sendable, Equatable {
    public var searchTerm: String
    public var limit: Int
    public init(searchTerm: String, limit: Int = 25) { self.searchTerm = searchTerm; self.limit = limit }
}

public protocol MusicCatalogProvider: Sendable {
    var providerName: String { get }
    func search(_ query: MusicCatalogQuery) async throws -> [MusicTrack]
    func resolve(trackIDs: [String]) async throws -> [MusicTrack]
}

public protocol MusicQueueProvider: Sendable {
    var providerName: String { get }
    func prepare(plan: PlaylistPlan) async throws
    func play() async throws
    func pause() async throws
}

public enum ProviderRuntimeError: Error, Sendable, Equatable {
    case authorizationRequired(String)
    case unavailable(String)
    case unsupported(String)
}
