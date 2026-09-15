import Foundation

public enum CourseSurface: String, Codable, Sendable, CaseIterable {
    case road, track, trail, mixed, unknown
}

public struct CoursePoint: Codable, Sendable, Equatable {
    public let distanceMeters: Double
    public let elevationMeters: Double?
    public let latitude: Double?
    public let longitude: Double?

    public init(distanceMeters: Double, elevationMeters: Double? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.distanceMeters = max(0, distanceMeters)
        self.elevationMeters = elevationMeters
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct RaceCourse: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let raceDate: Date?
    public let distanceMeters: Double
    public let surface: CourseSurface
    public let sourceURL: URL?
    public let sourceLabel: String?
    public let verifiedEdition: String?
    public let points: [CoursePoint]

    public init(id: UUID = UUID(), name: String, raceDate: Date? = nil, distanceMeters: Double, surface: CourseSurface = .unknown, sourceURL: URL? = nil, sourceLabel: String? = nil, verifiedEdition: String? = nil, points: [CoursePoint] = []) {
        self.id = id; self.name = name; self.raceDate = raceDate; self.distanceMeters = max(1, distanceMeters); self.surface = surface; self.sourceURL = sourceURL; self.sourceLabel = sourceLabel; self.verifiedEdition = verifiedEdition; self.points = points.sorted { $0.distanceMeters < $1.distanceMeters }
    }
}

public struct CourseSegment: Codable, Sendable, Equatable {
    public let startMeters: Double
    public let endMeters: Double
    public let elevationGainMeters: Double
    public let gradePercent: Double?
    public init(startMeters: Double, endMeters: Double, elevationGainMeters: Double, gradePercent: Double?) { self.startMeters = max(0, startMeters); self.endMeters = max(startMeters, endMeters); self.elevationGainMeters = elevationGainMeters; self.gradePercent = gradePercent }
}

public struct CourseAnalyzer: Sendable {
    public init() {}
    public func segments(for course: RaceCourse, targetSegmentMeters: Double = 1000) -> [CourseSegment] {
        guard course.points.count >= 2 else { return [] }
        let width = max(250, targetSegmentMeters)
        var result: [CourseSegment] = []
        var start = 0.0
        while start < course.distanceMeters {
            let end = min(course.distanceMeters, start + width)
            let startPoint = nearestPoint(in: course.points, to: start)
            let endPoint = nearestPoint(in: course.points, to: end)
            let delta = (endPoint.elevationMeters ?? 0) - (startPoint.elevationMeters ?? 0)
            let grade = end > start ? (delta / (end - start)) * 100 : nil
            result.append(CourseSegment(startMeters: start, endMeters: end, elevationGainMeters: delta, gradePercent: grade))
            start = end
        }
        return result
    }
    private func nearestPoint(in points: [CoursePoint], to distance: Double) -> CoursePoint { points.min { abs($0.distanceMeters - distance) < abs($1.distanceMeters - distance) } ?? points[0] }
}
