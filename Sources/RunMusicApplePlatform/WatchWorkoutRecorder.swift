import Foundation
import RunMusicCore

#if os(watchOS) && canImport(HealthKit)
import HealthKit

@MainActor
public final class WatchWorkoutRecorder: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    @Published public private(set) var isRunning = false
    @Published public private(set) var latestDistanceMeters: Double = 0
    @Published public private(set) var latestHeartRateBPM: Double?
    @Published public private(set) var latestPowerWatts: Double?

    private let store: HKHealthStore
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    public init(store: HKHealthStore = HKHealthStore()) { self.store = store }

    public func start(at date: Date = Date()) throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
        session.delegate = self
        builder.delegate = self
        self.session = session
        self.builder = builder
        session.startActivity(with: date)
        builder.beginCollection(withStart: date) { [weak self] success, _ in self?.isRunning = success }
    }

    public func finish(at date: Date = Date()) {
        session?.end()
        builder?.endCollection(withEnd: date) { [weak self] _, _ in
            self?.builder?.finishWorkout { _, _ in self?.isRunning = false }
        }
    }

    public func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    public func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { isRunning = false }

    public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType, let statistics = workoutBuilder.statistics(for: quantityType) else { continue }
            switch quantityType.identifier {
            case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                latestDistanceMeters = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? latestDistanceMeters
            case HKQuantityTypeIdentifier.heartRate.rawValue:
                latestHeartRateBPM = statistics.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            case HKQuantityTypeIdentifier.runningPower.rawValue:
                latestPowerWatts = statistics.mostRecentQuantity()?.doubleValue(for: .watt())
            default: break
            }
        }
    }
}

#else

public actor WatchWorkoutRecorder {
    public init() {}
    public func start(at date: Date = Date()) throws { throw ProviderRuntimeError.unavailable("Live watch workout recording requires watchOS") }
    public func finish(at date: Date = Date()) {}
}

#endif
