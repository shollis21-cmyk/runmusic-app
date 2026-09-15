import Foundation
import RunMusicCore

#if canImport(HealthKit)
import HealthKit

public actor AppleHealthAuthorizationAdapter: ProviderAuthorizing {
    public let providerName = "Apple Health"
    private let store: HKHealthStore

    public init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    public func currentStatus() async -> ProviderAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            return ProviderAuthorizationStatus(providerName: providerName, state: .unavailable)
        }
        return ProviderAuthorizationStatus(providerName: providerName, state: .unknown, detail: "Read access is determined when queries return data; HealthKit does not expose a single read authorization status.")
    }

    public func requestAuthorization() async -> ProviderAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            return ProviderAuthorizationStatus(providerName: providerName, state: .unavailable)
        }
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: Self.readTypes)
            return ProviderAuthorizationStatus(providerName: providerName, state: .authorized)
        } catch {
            return ProviderAuthorizationStatus(providerName: providerName, state: .denied, detail: error.localizedDescription)
        }
    }

    private static var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        let identifiers: [HKQuantityTypeIdentifier] = [
            .distanceWalkingRunning, .heartRate, .runningSpeed, .runningPower,
            .runningStrideLength, .runningGroundContactTime, .runningVerticalOscillation, .stepCount
        ]
        for identifier in identifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: identifier) { types.insert(type) }
        }
        return types
    }
}

#else

public struct AppleHealthAuthorizationAdapter: ProviderAuthorizing {
    public let providerName = "Apple Health"
    public init() {}
    public func currentStatus() async -> ProviderAuthorizationStatus {
        ProviderAuthorizationStatus(providerName: providerName, state: .unavailable, detail: "HealthKit is only available on supported Apple platforms.")
    }
    public func requestAuthorization() async -> ProviderAuthorizationStatus { await currentStatus() }
}

#endif
