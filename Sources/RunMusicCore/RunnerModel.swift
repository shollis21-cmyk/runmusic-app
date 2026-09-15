import Foundation

public struct BasicRunnerModel: RunnerModeling {
    public init() {}
    public func buildProfile(from activities: [CanonicalActivity], manualFallback: RunnerProfile? = nil) -> RunnerProfile {
        guard !activities.isEmpty else { return manualFallback ?? RunnerProfile() }
        func weightedMean(_ values: [(Double, Double)]) -> Double? { let valid = values.filter { $0.0.isFinite && $0.1 > 0 }; guard !valid.isEmpty else { return nil }; let totalWeight = valid.reduce(0) { $0 + $1.1 }; return valid.reduce(0) { $0 + $1.0 * $1.1 } / totalWeight }
        let pace = weightedMean(activities.compactMap { activity in activity.averagePaceSecondsPerKilometer.map { ($0.value, $0.confidence) } }) ?? manualFallback?.easyPaceSecondsPerKilometer
        let cadence = weightedMean(activities.compactMap { activity in activity.averageCadenceSPM.map { ($0.value, $0.confidence) } }) ?? manualFallback?.typicalCadenceSPM
        let power = weightedMean(activities.compactMap { activity in activity.averagePowerWatts.map { ($0.value, $0.confidence) } }) ?? manualFallback?.typicalPowerWatts
        let count = activities.count
        let confidence = min(1, 0.15 + log10(Double(count) + 1) * 0.45)
        return RunnerProfile(preferredUnitsMiles: manualFallback?.preferredUnitsMiles ?? true, easyPaceSecondsPerKilometer: pace, thresholdPaceSecondsPerKilometer: manualFallback?.thresholdPaceSecondsPerKilometer, typicalCadenceSPM: cadence, typicalPowerWatts: power, maxHeartRateBPM: manualFallback?.maxHeartRateBPM, dataConfidence: max(confidence, manualFallback?.dataConfidence ?? 0), historyActivityCount: count)
    }
}
