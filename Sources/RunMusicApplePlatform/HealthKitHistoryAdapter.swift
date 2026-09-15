import Foundation
import RunMusicCore

#if canImport(HealthKit)
import HealthKit

public actor HealthKitActivityHistoryAdapter: ActivityHistoryProvider {
    public let providerName = "Apple Health"
    private let store: HKHealthStore
    private let mapper = HealthKitActivityMapper()

    public init(store: HKHealthStore = HKHealthStore()) { self.store = store }

    public func fetchRuns(_ query: ProviderRunQuery) async throws -> [CanonicalActivity] {
        let predicate = HKQuery.predicateForSamples(withStart: query.start, end: query.end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(HKSamplePredicate.workouts(predicate))],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: query.limit
        )
        let workouts = try await descriptor.result(for: store)
        var result: [CanonicalActivity] = []
        for workout in workouts where workout.workoutActivityType == .running {
            result.append(try await map(workout))
        }
        return result
    }

    private func map(_ workout: HKWorkout) async throws -> CanonicalActivity {
        var metrics: [HealthKitMetricSample] = []
        let metricTypes: [(HKQuantityTypeIdentifier, HealthKitMetricKind, HKUnit)] = [
            (.distanceWalkingRunning, .distanceMeters, .meter()),
            (.heartRate, .heartRateBPM, HKUnit.count().unitDivided(by: .minute())),
            (.runningSpeed, .runningSpeedMetersPerSecond, HKUnit.meter().unitDivided(by: .second())),
            (.runningPower, .runningPowerWatts, .watt()),
            (.runningStrideLength, .strideLengthMeters, .meter()),
            (.runningGroundContactTime, .groundContactTimeMilliseconds, .secondUnit(with: .milli)),
            (.runningVerticalOscillation, .verticalOscillationCentimeters, .meterUnit(with: .centi)),
            (.stepCount, .stepCount, .count())
        ]
        for (identifier, kind, unit) in metricTypes {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            let predicate = HKQuery.predicateForObjects(from: workout)
            let descriptor = HKSampleQueryDescriptor(predicates: [.quantitySample(type: type, predicate: predicate)], sortDescriptors: [SortDescriptor(\.startDate)])
            for sample in try await descriptor.result(for: store) {
                metrics.append(HealthKitMetricSample(kind: kind, value: sample.quantity.doubleValue(for: unit), date: sample.startDate))
            }
        }
        return mapper.map(
            HealthKitWorkoutPayload(
                workoutID: workout.uuid.uuidString,
                startDate: workout.startDate,
                endDate: workout.endDate,
                metrics: metrics
            )
        )
    }
}

#else

public struct HealthKitActivityHistoryAdapter: ActivityHistoryProvider {
    public let providerName = "Apple Health"
    public init() {}
    public func fetchRuns(_ query: ProviderRunQuery) async throws -> [CanonicalActivity] {
        throw ProviderRuntimeError.unavailable("HealthKit is unavailable on this platform")
    }
}

#endif
