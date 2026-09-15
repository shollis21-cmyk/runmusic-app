import Foundation

public enum HealthMetricKind: String, Codable, Sendable, CaseIterable {
    case distance
    case heartRate
    case runningSpeed
    case runningPower
    case strideLength
    case groundContactTime
    case verticalOscillation
    case stepCount
}

public struct HealthMetricSample: Codable, Sendable, Equatable {
    public let kind: HealthMetricKind
    public let startDate: Date
    public let endDate: Date
    public let value: Double

    public init(kind: HealthMetricKind, startDate: Date, endDate: Date, value: Double) {
        self.kind = kind
        self.startDate = startDate
        self.endDate = endDate
        self.value = value
    }
}

public struct HealthWorkoutRecord: Codable, Sendable, Equatable {
    public let id: String
    public let startedAt: Date
    public let endedAt: Date
    public let distanceMeters: Double
    public let metrics: [HealthMetricSample]

    public init(id: String, startedAt: Date, endedAt: Date, distanceMeters: Double, metrics: [HealthMetricSample]) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.distanceMeters = distanceMeters
        self.metrics = metrics
    }
}

public struct HealthKitCanonicalMapper: Sendable {
    public init() {}

    public func map(_ workout: HealthWorkoutRecord) -> CanonicalActivity {
        let duration = max(workout.endedAt.timeIntervalSince(workout.startedAt), 1)
        let pace = workout.distanceMeters > 0 ? duration / (workout.distanceMeters / 1000) : nil

        return CanonicalActivity(
            startedAt: workout.startedAt,
            durationSeconds: duration,
            distanceMeters: workout.distanceMeters,
            primarySource: .appleHealth,
            sourceActivityIDs: [.appleHealth: workout.id],
            averagePaceSecondsPerKilometer: pace.map { ProvenancedValue(value: $0, source: .appleHealth, confidence: 0.94, capturedAt: workout.endedAt) },
            averageHeartRateBPM: aggregate(.heartRate, from: workout.metrics).map { ProvenancedValue(value: $0, source: .appleHealth, confidence: 0.96, capturedAt: workout.endedAt) },
            averageCadenceSPM: derivedCadence(from: workout.metrics, durationSeconds: duration).map { ProvenancedValue(value: $0, source: .appleHealth, confidence: 0.72, capturedAt: workout.endedAt) },
            averagePowerWatts: aggregate(.runningPower, from: workout.metrics).map { ProvenancedValue(value: $0, source: .appleHealth, confidence: 0.94, capturedAt: workout.endedAt) },
            strideLengthMeters: aggregate(.strideLength, from: workout.metrics).map { ProvenancedValue(value: $0, source: .appleHealth, confidence: 0.92, capturedAt: workout.endedAt) },
            groundContactTimeMilliseconds: aggregate(.groundContactTime, from: workout.metrics).map { ProvenancedValue(value: $0, source: .appleHealth, confidence: 0.92, capturedAt: workout.endedAt) },
            verticalOscillationCentimeters: aggregate(.verticalOscillation, from: workout.metrics).map { ProvenancedValue(value: $0, source: .appleHealth, confidence: 0.92, capturedAt: workout.endedAt) },
            samples: timeline(from: workout)
        )
    }

    private func aggregate(_ kind: HealthMetricKind, from metrics: [HealthMetricSample]) -> Double? {
        let values = metrics.filter { $0.kind == kind }.map(\.value)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func derivedCadence(from metrics: [HealthMetricSample], durationSeconds: TimeInterval) -> Double? {
        let steps = metrics.filter { $0.kind == .stepCount }.reduce(0) { $0 + $1.value }
        guard steps > 0, durationSeconds > 0 else { return nil }
        return steps / (durationSeconds / 60)
    }

    private func timeline(from workout: HealthWorkoutRecord) -> [ActivitySample] {
        let grouped = Dictionary(grouping: workout.metrics) { sample in
            Int(max(0, sample.startDate.timeIntervalSince(workout.startedAt)) / 5)
        }
        return grouped.keys.sorted().map { bucket in
            let samples = grouped[bucket] ?? []
            let elapsed = min(TimeInterval(bucket * 5), workout.endedAt.timeIntervalSince(workout.startedAt))
            let speed = averageValue(.runningSpeed, in: samples)
            let distance = workout.distanceMeters * (elapsed / max(workout.endedAt.timeIntervalSince(workout.startedAt), 1))
            return ActivitySample(
                elapsedSeconds: elapsed,
                distanceMeters: max(0, distance),
                paceSecondsPerKilometer: speed.flatMap { $0 > 0 ? 1000 / $0 : nil },
                heartRateBPM: averageValue(.heartRate, in: samples),
                cadenceSPM: nil,
                powerWatts: averageValue(.runningPower, in: samples),
                elevationMeters: nil
            )
        }
    }

    private func averageValue(_ kind: HealthMetricKind, in samples: [HealthMetricSample]) -> Double? {
        let values = samples.filter { $0.kind == kind }.map(\.value)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
