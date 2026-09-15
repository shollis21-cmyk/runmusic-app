import Foundation

public struct AppConfiguration: Codable, Sendable, Equatable {
    public var runnerProfile: RunnerProfile?
    public var musicProfile: MusicPreference?
    public var preferredDistanceUnit: DistanceUnit
    public var explicitContentAllowed: Bool

    public init(runnerProfile: RunnerProfile? = nil, musicProfile: MusicPreference? = nil, preferredDistanceUnit: DistanceUnit = .miles, explicitContentAllowed: Bool = false) {
        self.runnerProfile = runnerProfile
        self.musicProfile = musicProfile
        self.preferredDistanceUnit = preferredDistanceUnit
        self.explicitContentAllowed = explicitContentAllowed
    }
}

public protocol AppConfigurationStore: Sendable {
    func load() async throws -> AppConfiguration
    func save(_ configuration: AppConfiguration) async throws
}

public actor FileAppConfigurationStore: AppConfigurationStore {
    private let url: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(url: URL) { self.url = url }

    public func load() async throws -> AppConfiguration {
        guard FileManager.default.fileExists(atPath: url.path) else { return AppConfiguration() }
        return try decoder.decode(AppConfiguration.self, from: Data(contentsOf: url))
    }

    public func save(_ configuration: AppConfiguration) async throws {
        let data = try encoder.encode(configuration)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let temporary = directory.appendingPathComponent(".\(url.lastPathComponent).tmp")
        try data.write(to: temporary, options: .atomic)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary, backupItemName: nil, options: .usingNewMetadataOnly)
        } else {
            try FileManager.default.moveItem(at: temporary, to: url)
        }
    }
}

public enum DistanceUnit: String, Codable, Sendable, CaseIterable { case miles, kilometers }
