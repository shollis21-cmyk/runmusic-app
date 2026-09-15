import Foundation

public enum ActivityMetric: String, Codable, Sendable, CaseIterable {
    case distance, pace, heartRate, cadence, power, strideLength, groundContactTime, verticalOscillation, elevation
}

public struct MetricObservation: Sendable, Equatable {
    public let metric: ActivityMetric
    public let value: Double
    public let source: DataSource
    public let confidence: Double
    public let sampleCount: Int?

    public init(metric: ActivityMetric, value: Double, source: DataSource, confidence: Double, sampleCount: Int? = nil) {
        self.metric = metric
        self.value = value
        self.source = source
        self.confidence = min(max(confidence, 0), 1)
        self.sampleCount = sampleCount
    }
}

public struct MetricSourceSelector: Sendable {
    private let policy: MetricSourcePolicy

    public init(policy: MetricSourcePolicy = MetricSourcePolicy()) {
        self.policy = policy
    }

    public func best(_ observations: [MetricObservation]) -> MetricObservation? {
        observations.max { lhs, rhs in
            score(lhs) < score(rhs)
        }
    }

    public func score(_ observation: MetricObservation) -> Double {
        let sourceQuality = Double(policy.priority(for: observation.source, metric: observation.metric.rawValue)) / 100
        let densityBonus: Double
        if let count = observation.sampleCount {
            densityBonus = min(log10(Double(max(count, 1))) / 20, 0.12)
        } else {
            densityBonus = 0
        }
        return 0.65 * sourceQuality + 0.35 * observation.confidence + densityBonus
    }
}
