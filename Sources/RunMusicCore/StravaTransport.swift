import Foundation

public struct StravaActivityDTO: Codable, Sendable, Equatable {
    public let id: Int64
    public let startDate: Date
    public let elapsedTime: Int
    public let distance: Double
    public let averageHeartrate: Double?
    public let averageCadence: Double?
    public let averageWatts: Double?

    enum CodingKeys: String, CodingKey {
        case id, distance
        case startDate = "start_date"
        case elapsedTime = "elapsed_time"
        case averageHeartrate = "average_heartrate"
        case averageCadence = "average_cadence"
        case averageWatts = "average_watts"
    }
}

public struct StravaActivityPageDecoder: Sendable {
    public init() {}
    public func decode(_ data: Data) throws -> [ExternalActivity] {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([StravaActivityDTO].self, from: data).map { dto in
                ExternalActivity(providerID: String(dto.id), source: .strava, startedAt: dto.startDate, durationSeconds: TimeInterval(dto.elapsedTime), distanceMeters: dto.distance, averageHeartRateBPM: dto.averageHeartrate, averageCadenceSPM: dto.averageCadence.map { $0 * 2 }, averagePowerWatts: dto.averageWatts)
            }
        } catch { throw IntegrationTransportError.decoding(String(describing: error)) }
    }
}

public struct StravaRequestBuilder: Sendable {
    public let baseURL: URL
    public init(baseURL: URL = URL(string: "https://www.strava.com/api/v3")!) { self.baseURL = baseURL }
    public func activities(after: Date?, page: Int = 1, perPage: Int = 100, accessToken: String) -> HTTPRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent("athlete/activities"), resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "per_page", value: String(min(max(perPage, 1), 200)))]
        if let after { items.append(URLQueryItem(name: "after", value: String(Int(after.timeIntervalSince1970)))) }
        components.queryItems = items
        return HTTPRequest(url: components.url!, headers: ["Authorization": "Bearer \(accessToken)"])
    }
    public func activity(id: String, accessToken: String) -> HTTPRequest {
        HTTPRequest(url: baseURL.appendingPathComponent("activities/\(id)"), headers: ["Authorization": "Bearer \(accessToken)"])
    }
    public func streams(
        activityID: String,
        keys: [String] = ["time", "distance", "velocity_smooth", "heartrate", "cadence", "watts", "altitude"],
        accessToken: String
    ) -> HTTPRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("activities/\(activityID)/streams"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "keys", value: keys.joined(separator: ",")),
            URLQueryItem(name: "key_by_type", value: "true")
        ]
        return HTTPRequest(url: components.url!, headers: ["Authorization": "Bearer \(accessToken)"])
    }
}

public struct StravaNumericStreamDTO: Codable, Sendable, Equatable {
    public let data: [Double]
}

public struct StravaStreamSetDTO: Codable, Sendable, Equatable {
    public let time: StravaNumericStreamDTO?
    public let distance: StravaNumericStreamDTO?
    public let velocitySmooth: StravaNumericStreamDTO?
    public let heartrate: StravaNumericStreamDTO?
    public let cadence: StravaNumericStreamDTO?
    public let watts: StravaNumericStreamDTO?
    public let altitude: StravaNumericStreamDTO?

    enum CodingKeys: String, CodingKey {
        case time, distance, heartrate, cadence, watts, altitude
        case velocitySmooth = "velocity_smooth"
    }
}

public struct StravaStreamDecoder: Sendable {
    public init() {}

    public func decode(_ data: Data) throws -> [ActivitySample] {
        let streams: StravaStreamSetDTO
        do { streams = try JSONDecoder().decode(StravaStreamSetDTO.self, from: data) }
        catch { throw IntegrationTransportError.decoding(String(describing: error)) }

        let count = [
            streams.time?.data.count,
            streams.distance?.data.count,
            streams.velocitySmooth?.data.count,
            streams.heartrate?.data.count,
            streams.cadence?.data.count,
            streams.watts?.data.count,
            streams.altitude?.data.count
        ].compactMap { $0 }.max() ?? 0

        return (0..<count).map { index in
            let velocity = streams.velocitySmooth?.data[safe: index]
            return ActivitySample(
                elapsedSeconds: streams.time?.data[safe: index] ?? 0,
                distanceMeters: streams.distance?.data[safe: index] ?? 0,
                paceSecondsPerKilometer: velocity.flatMap { $0 > 0 ? 1000 / $0 : nil },
                heartRateBPM: streams.heartrate?.data[safe: index],
                cadenceSPM: streams.cadence?.data[safe: index].map { $0 * 2 },
                powerWatts: streams.watts?.data[safe: index],
                elevationMeters: streams.altitude?.data[safe: index]
            )
        }
    }
}

public struct StravaHistoryClient: Sendable {
    private let transport: any HTTPTransport
    private let requestBuilder: StravaRequestBuilder
    private let decoder: StravaActivityPageDecoder
    private let pageSize: Int

    public init(
        transport: any HTTPTransport,
        requestBuilder: StravaRequestBuilder = StravaRequestBuilder(),
        decoder: StravaActivityPageDecoder = StravaActivityPageDecoder(),
        pageSize: Int = 100
    ) {
        self.transport = transport
        self.requestBuilder = requestBuilder
        self.decoder = decoder
        self.pageSize = min(max(pageSize, 1), 200)
    }

    /// Fetches every page newer than `after`, preserving Strava's newest-first ordering.
    public func fetchActivities(after: Date?, accessToken: String) async throws -> [ExternalActivity] {
        var page = 1
        var activities: [ExternalActivity] = []

        while true {
            let request = requestBuilder.activities(after: after, page: page, perPage: pageSize, accessToken: accessToken)
            let response = try await transport.send(request)
            try validate(response)
            let decoded = try decoder.decode(response.body)
            activities.append(contentsOf: decoded)
            if decoded.count < pageSize { return activities }
            page += 1
        }
    }

    public func fetchEnrichedActivities(
        after: Date?,
        accessToken: String,
        maximumEnrichedActivities: Int = 20
    ) async throws -> [ExternalActivity] {
        let activities = try await fetchActivities(after: after, accessToken: accessToken)
        let enrichmentCount = min(max(0, maximumEnrichedActivities), activities.count)
        var enriched = activities
        for index in 0..<enrichmentCount {
            let request = requestBuilder.streams(activityID: activities[index].providerID, accessToken: accessToken)
            let response = try await transport.send(request)
            try validate(response)
            let samples = try StravaStreamDecoder().decode(response.body)
            let activity = activities[index]
            enriched[index] = ExternalActivity(
                providerID: activity.providerID,
                source: activity.source,
                startedAt: activity.startedAt,
                durationSeconds: activity.durationSeconds,
                distanceMeters: activity.distanceMeters,
                averageHeartRateBPM: activity.averageHeartRateBPM,
                averageCadenceSPM: activity.averageCadenceSPM,
                averagePowerWatts: activity.averagePowerWatts,
                samples: samples
            )
        }
        return enriched
    }

    private func validate(_ response: HTTPResponse) throws {
        if response.statusCode == 429 {
            throw IntegrationTransportError.rateLimited(
                retryAfterSeconds: response.headers.firstValue(caseInsensitive: "Retry-After").flatMap(TimeInterval.init)
            )
        }
        guard (200..<300).contains(response.statusCode) else {
            throw IntegrationTransportError.httpStatus(response.statusCode)
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}

private extension Dictionary where Key == String, Value == String {
    func firstValue(caseInsensitive key: String) -> String? {
        first { $0.key.caseInsensitiveCompare(key) == .orderedSame }?.value
    }
}
