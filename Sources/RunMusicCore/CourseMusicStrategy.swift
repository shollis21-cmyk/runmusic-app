import Foundation

public struct EnergyAnchor: Codable, Sendable, Equatable {
    public let distanceMeters: Double
    public let targetEnergy: Double

    public init(distanceMeters: Double, targetEnergy: Double) {
        self.distanceMeters = max(0, distanceMeters)
        self.targetEnergy = min(max(targetEnergy, 0), 1)
    }
}

public struct CourseMusicSegment: Codable, Sendable, Equatable {
    public let startMeters: Double
    public let endMeters: Double
    public let gradePercent: Double?
    public let targetEnergy: Double
    public let rationale: String
}

public struct CourseMusicStrategy: Codable, Sendable, Equatable {
    public let segments: [CourseMusicSegment]
    public let anchors: [EnergyAnchor]
}

public struct CourseMusicStrategyBuilder: Sendable {
    public init() {}

    /// Produces a music-energy plan from course shape. It does not prescribe physiological effort;
    /// the connected running/coaching app remains authoritative for pacing or safety guidance.
    public func build(course: RaceCourse, baseProfile: EnergyProfile = .progressive) -> CourseMusicStrategy {
        let courseSegments = CourseAnalyzer().segments(for: course, targetSegmentMeters: 1000)
        guard !courseSegments.isEmpty else { return CourseMusicStrategy(segments: [], anchors: []) }
        var output: [CourseMusicSegment] = []
        var anchors: [EnergyAnchor] = []

        for segment in courseSegments {
            let midpoint = (segment.startMeters + segment.endMeters) / 2
            let progress = min(max(midpoint / course.distanceMeters, 0), 1)
            var energy = baseline(baseProfile, progress: progress)
            let grade = segment.gradePercent ?? 0

            if grade >= 2.5 {
                energy += min(0.12, grade / 60)
            } else if grade <= -2.5 {
                energy += 0.03
            }
            if progress >= 0.80 { energy += 0.05 }
            energy = min(max(energy, 0.35), 0.96)

            let rationale: String
            if grade >= 2.5 { rationale = "higher musical drive for sustained climb" }
            else if grade <= -2.5 { rationale = "crisp turnover support on descent" }
            else if progress >= 0.80 { rationale = "late-run energy progression" }
            else { rationale = "steady course segment" }

            output.append(CourseMusicSegment(
                startMeters: segment.startMeters,
                endMeters: segment.endMeters,
                gradePercent: segment.gradePercent,
                targetEnergy: energy,
                rationale: rationale
            ))
            anchors.append(EnergyAnchor(distanceMeters: segment.startMeters, targetEnergy: energy))
        }
        if let last = output.last {
            anchors.append(EnergyAnchor(distanceMeters: course.distanceMeters, targetEnergy: min(0.98, last.targetEnergy + 0.04)))
        }
        return CourseMusicStrategy(segments: output, anchors: anchors)
    }

    private func baseline(_ profile: EnergyProfile, progress: Double) -> Double {
        switch profile {
        case .steady: return 0.68
        case .progressive: return 0.52 + 0.38 * progress
        case .negativeSplit: return progress < 0.5 ? 0.58 : 0.68 + 0.25 * ((progress - 0.5) / 0.5)
        case .conservativeStartStrongFinish:
            if progress < 0.25 { return 0.48 }
            if progress < 0.75 { return 0.66 }
            return 0.82 + 0.12 * ((progress - 0.75) / 0.25)
        }
    }
}
