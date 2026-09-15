import Foundation

public enum ProviderCapability: String, Codable, Sendable, CaseIterable {
    case historicalActivities
    case liveWorkoutTelemetry
    case routeData
    case cadence
    case power
    case heartRate
    case musicTasteSignals
    case playlistExport
    case playbackControl
    case offlinePlayback
}

public struct ProviderCapabilityProfile: Codable, Sendable, Equatable {
    public let name: String
    public let capabilities: Set<ProviderCapability>
    public let requiresExternalApproval: Bool
    public let configurationNeeded: Bool
    public let notes: [String]

    public init(name: String, capabilities: Set<ProviderCapability>, requiresExternalApproval: Bool, configurationNeeded: Bool, notes: [String] = []) {
        self.name = name
        self.capabilities = capabilities
        self.requiresExternalApproval = requiresExternalApproval
        self.configurationNeeded = configurationNeeded
        self.notes = notes
    }
}

public struct ProviderCapabilityRegistry: Sendable {
    public init() {}

    public func activity(_ source: DataSource) -> ProviderCapabilityProfile {
        switch source {
        case .appleHealth, .appleWatch:
            return ProviderCapabilityProfile(
                name: source == .appleWatch ? "Apple Watch / HealthKit" : "Apple Health / HealthKit",
                capabilities: [.historicalActivities, .liveWorkoutTelemetry, .routeData, .power, .heartRate],
                requiresExternalApproval: false,
                configurationNeeded: true,
                notes: ["Cadence may require derivation or another source depending on the recorded workout data."]
            )
        case .strava:
            return ProviderCapabilityProfile(
                name: "Strava",
                capabilities: [.historicalActivities, .routeData, .cadence, .power, .heartRate],
                requiresExternalApproval: true,
                configurationNeeded: true,
                notes: ["Best treated as a broad interoperability/history source rather than the live recorder."]
            )
        case .garmin:
            return ProviderCapabilityProfile(
                name: "Garmin",
                capabilities: [.historicalActivities, .routeData, .cadence, .power, .heartRate],
                requiresExternalApproval: true,
                configurationNeeded: true,
                notes: ["Direct production access depends on Garmin developer/commercial approval."]
            )
        case .nikeRunClub:
            return ProviderCapabilityProfile(
                name: "Nike Run Club",
                capabilities: [.historicalActivities],
                requiresExternalApproval: true,
                configurationNeeded: true,
                notes: ["Initial supported path is indirect import through Strava rather than an unsupported private NRC API."]
            )
        case .manual:
            return ProviderCapabilityProfile(name: "Manual", capabilities: [.cadence, .power, .heartRate], requiresExternalApproval: false, configurationNeeded: false)
        case .importedFile:
            return ProviderCapabilityProfile(name: "FIT/GPX/TCX import", capabilities: [.historicalActivities, .routeData, .cadence, .power, .heartRate], requiresExternalApproval: false, configurationNeeded: false)
        }
    }

    public func music(_ provider: MusicProvider) -> ProviderCapabilityProfile {
        switch provider {
        case .appleMusic:
            return ProviderCapabilityProfile(
                name: "Apple Music",
                capabilities: [.musicTasteSignals, .playlistExport, .playbackControl, .offlinePlayback],
                requiresExternalApproval: false,
                configurationNeeded: true,
                notes: ["Deepest iPhone/Watch integration target."]
            )
        case .spotify:
            return ProviderCapabilityProfile(
                name: "Spotify",
                capabilities: [.musicTasteSignals, .playlistExport, .offlinePlayback],
                requiresExternalApproval: true,
                configurationNeeded: true,
                notes: ["Treat as a non-streaming playlist destination; do not make commercial embedded streaming a core dependency."]
            )
        case .amazonMusic:
            return ProviderCapabilityProfile(
                name: "Amazon Music",
                capabilities: [.musicTasteSignals, .playlistExport, .playbackControl, .offlinePlayback],
                requiresExternalApproval: true,
                configurationNeeded: true,
                notes: ["Keep behind the provider abstraction until production API access is approved."]
            )
        case .manual:
            return ProviderCapabilityProfile(name: "Manual music preferences", capabilities: [.musicTasteSignals], requiresExternalApproval: false, configurationNeeded: false)
        }
    }
}
