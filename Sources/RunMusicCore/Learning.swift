import Foundation

public struct SongRunObservation: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let trackID: String
    public let observedAt: Date
    public let terrainGradePercent: Double?
    public let cadenceSPM: Double?
    public let powerWatts: Double?
    public let paceSecondsPerKilometer: Double?
    public let completed: Bool
    public let userFeedback: Double?
    public init(id: UUID = UUID(), trackID: String, observedAt: Date = Date(), terrainGradePercent: Double? = nil, cadenceSPM: Double? = nil, powerWatts: Double? = nil, paceSecondsPerKilometer: Double? = nil, completed: Bool = true, userFeedback: Double? = nil) {
        self.id=id; self.trackID=trackID; self.observedAt=observedAt; self.terrainGradePercent=terrainGradePercent; self.cadenceSPM=cadenceSPM; self.powerWatts=powerWatts; self.paceSecondsPerKilometer=paceSecondsPerKilometer; self.completed=completed; self.userFeedback=userFeedback.map { min(max($0,-1),1) }
    }
}

public struct TrackResponseProfile: Codable, Sendable, Equatable {
    public let trackID: String
    public let observationCount: Int
    public let meanCadenceSPM: Double?
    public let meanPowerWatts: Double?
    public let meanFeedback: Double?
    public let confidence: Double
}

public enum FirstPartyLearningEngine {
    public static func profile(trackID: String, observations: [SongRunObservation]) -> TrackResponseProfile {
        let rows = observations.filter { $0.trackID == trackID }
        func avg(_ values: [Double]) -> Double? { values.isEmpty ? nil : values.reduce(0,+) / Double(values.count) }
        let count = rows.count
        return TrackResponseProfile(trackID: trackID, observationCount: count, meanCadenceSPM: avg(rows.compactMap(\.cadenceSPM)), meanPowerWatts: avg(rows.compactMap(\.powerWatts)), meanFeedback: avg(rows.compactMap(\.userFeedback)), confidence: min(1, Double(count) / 12.0))
    }
}
