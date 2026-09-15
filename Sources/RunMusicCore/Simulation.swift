import Foundation

public enum DemoFactory {
    public static func runner() -> RunnerProfile { RunnerProfile(preferredUnitsMiles: true, easyPaceSecondsPerKilometer: 345, thresholdPaceSecondsPerKilometer: 315, typicalCadenceSPM: 174, typicalPowerWatts: 238, maxHeartRateBPM: 190, dataConfidence: 0.82, historyActivityCount: 42) }
    public static func preference() -> MusicPreference { MusicPreference(favoriteArtists: ["Pulse Drive", "Northbound", "City Static"], preferredGenres: ["Pop", "Hip-Hop", "Alternative"], explicitContentAllowed: true, preferenceConfidence: 0.75) }
    public static func tracks() -> [MusicTrack] {
        let durations: [Double] = [212,238,197,224,205,252,186,231,219,243,201,226,214,247,193,235,221,208]
        return durations.enumerated().map { index, duration in
            let bpm = [86,170,174,88,176,168,180,172,90,178,166,174,182,169,176,88,171,179][index]
            let energy = [0.52,0.63,0.70,0.58,0.77,0.62,0.86,0.69,0.72,0.88,0.60,0.73,0.91,0.67,0.84,0.74,0.68,0.90][index]
            return MusicTrack(id: "track-\(index + 1)", isrc: "DEMO\(String(format: "%08d", index + 1))", title: "Demo Track \(index + 1)", artist: ["Pulse Drive", "Northbound", "City Static", "Late Apex"][index % 4], durationSeconds: duration, bpm: Double(bpm), energy: energy, familiarity: 0.55 + Double(index % 5) * 0.08, preferenceScore: 0.58 + Double(index % 6) * 0.065, explicit: false)
        }
    }
}
