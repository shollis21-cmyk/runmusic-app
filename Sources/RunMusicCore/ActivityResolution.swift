import Foundation

public struct MetricSourcePolicy: Sendable {
    public init() {}

    public func priority(for source: DataSource, metric: String) -> Int {
        switch metric {
        case "cadence", "power", "stride", "gct", "verticalOscillation":
            switch source {
            case .garmin: return 100
            case .appleWatch: return 92
            case .appleHealth: return 88
            case .strava: return 78
            case .importedFile: return 76
            case .nikeRunClub: return 65
            case .manual: return 50
            }
        case "heartRate":
            switch source {
            case .appleWatch: return 100
            case .garmin: return 96
            case .appleHealth: return 92
            case .strava: return 80
            case .importedFile: return 78
            case .nikeRunClub: return 65
            case .manual: return 50
            }
        case "pace", "distance":
            switch source {
            case .garmin: return 98
            case .appleWatch: return 96
            case .appleHealth: return 90
            case .strava: return 88
            case .importedFile: return 86
            case .nikeRunClub: return 80
            case .manual: return 50
            }
        default:
            return 50
        }
    }
}

public struct ActivityResolver: Sendable {
    private let policy: MetricSourcePolicy

    public init(policy: MetricSourcePolicy = MetricSourcePolicy()) {
        self.policy = policy
    }

    public func isLikelyDuplicate(_ lhs: CanonicalActivity, _ rhs: CanonicalActivity) -> Bool {
        let startDelta = abs(lhs.startedAt.timeIntervalSince(rhs.startedAt))
        let durationDelta = abs(lhs.durationSeconds - rhs.durationSeconds)
        let distanceDelta = abs(lhs.distanceMeters - rhs.distanceMeters)
        let distanceTolerance = max(250, max(lhs.distanceMeters, rhs.distanceMeters) * 0.025)
        return startDelta <= 180 && durationDelta <= 240 && distanceDelta <= distanceTolerance
    }

    public func merge(_ activities: [CanonicalActivity]) -> CanonicalActivity? {
        guard let first = activities.first else { return nil }
        let ids = activities.reduce(into: [DataSource: String]()) { result, activity in
            activity.sourceActivityIDs.forEach { result[$0.key] = $0.value }
        }

        func best(_ metric: String, _ values: [(DataSource, ProvenancedValue<Double>?)]) -> ProvenancedValue<Double>? {
            values.compactMap { source, value -> (Int, Double, ProvenancedValue<Double>)? in
                guard let value else { return nil }
                return (policy.priority(for: source, metric: metric), value.confidence, value)
            }.sorted {
                if $0.0 != $1.0 { return $0.0 > $1.0 }
                return $0.1 > $1.1
            }.first?.2
        }

        let primary = activities.max {
            policy.priority(for: $0.primarySource, metric: "distance") < policy.priority(for: $1.primarySource, metric: "distance")
        } ?? first

        let samples = activities.max { $0.samples.count < $1.samples.count }?.samples ?? []

        return CanonicalActivity(
            id: first.id,
            startedAt: activities.map(\.startedAt).min() ?? first.startedAt,
            durationSeconds: primary.durationSeconds,
            distanceMeters: primary.distanceMeters,
            primarySource: primary.primarySource,
            sourceActivityIDs: ids,
            averagePaceSecondsPerKilometer: best("pace", activities.map { ($0.primarySource, $0.averagePaceSecondsPerKilometer) }),
            averageHeartRateBPM: best("heartRate", activities.map { ($0.primarySource, $0.averageHeartRateBPM) }),
            averageCadenceSPM: best("cadence", activities.map { ($0.primarySource, $0.averageCadenceSPM) }),
            averagePowerWatts: best("power", activities.map { ($0.primarySource, $0.averagePowerWatts) }),
            strideLengthMeters: best("stride", activities.map { ($0.primarySource, $0.strideLengthMeters) }),
            groundContactTimeMilliseconds: best("gct", activities.map { ($0.primarySource, $0.groundContactTimeMilliseconds) }),
            verticalOscillationCentimeters: best("verticalOscillation", activities.map { ($0.primarySource, $0.verticalOscillationCentimeters) }),
            samples: samples
        )
    }

    public func deduplicate(_ activities: [CanonicalActivity]) -> [CanonicalActivity] {
        var remaining = activities.sorted { $0.startedAt < $1.startedAt }
        var result: [CanonicalActivity] = []
        while !remaining.isEmpty {
            let seed = remaining.removeFirst()
            var group = [seed]
            remaining.removeAll { candidate in
                if isLikelyDuplicate(seed, candidate) {
                    group.append(candidate)
                    return true
                }
                return false
            }
            result.append(merge(group) ?? seed)
        }
        return result
    }
}
