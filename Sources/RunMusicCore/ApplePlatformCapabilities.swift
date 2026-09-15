import Foundation

public struct ApplePlatformCapabilityPlan: Sendable, Equatable {
    public let healthKitReadMetrics: Set<HealthMetricKind>
    public let writesWorkouts: Bool
    public let usesBackgroundWorkoutProcessing: Bool
    public let usesBackgroundAudio: Bool
    public let watchIsIndependentRecorder: Bool

    public init(
        healthKitReadMetrics: Set<HealthMetricKind>,
        writesWorkouts: Bool,
        usesBackgroundWorkoutProcessing: Bool,
        usesBackgroundAudio: Bool,
        watchIsIndependentRecorder: Bool
    ) {
        self.healthKitReadMetrics = healthKitReadMetrics
        self.writesWorkouts = writesWorkouts
        self.usesBackgroundWorkoutProcessing = usesBackgroundWorkoutProcessing
        self.usesBackgroundAudio = usesBackgroundAudio
        self.watchIsIndependentRecorder = watchIsIndependentRecorder
    }

    public static let production = ApplePlatformCapabilityPlan(
        healthKitReadMetrics: [.distance, .heartRate, .runningSpeed, .runningPower, .strideLength, .groundContactTime, .verticalOscillation, .stepCount],
        writesWorkouts: true,
        usesBackgroundWorkoutProcessing: true,
        usesBackgroundAudio: true,
        watchIsIndependentRecorder: true
    )
}
