import Foundation

public enum HTTPMethod: String, Sendable { case get = "GET", post = "POST", put = "PUT", delete = "DELETE" }

public struct HTTPRequest: Sendable, Equatable {
    public var method: HTTPMethod
    public var url: URL
    public var headers: [String: String]
    public var body: Data?
    public init(method: HTTPMethod = .get, url: URL, headers: [String: String] = [:], body: Data? = nil) {
        self.method = method; self.url = url; self.headers = headers; self.body = body
    }
}

public struct HTTPResponse: Sendable, Equatable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data
    public init(statusCode: Int, headers: [String: String] = [:], body: Data = Data()) {
        self.statusCode = statusCode; self.headers = headers; self.body = body
    }
}

public protocol HTTPTransport: Sendable { func send(_ request: HTTPRequest) async throws -> HTTPResponse }

public enum IntegrationTransportError: Error, Sendable, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)
    case rateLimited(retryAfterSeconds: TimeInterval?)
}

public struct RetryPolicy: Sendable, Equatable {
    public var maxAttempts: Int
    public var baseDelaySeconds: TimeInterval
    public var maxDelaySeconds: TimeInterval
    public init(maxAttempts: Int = 4, baseDelaySeconds: TimeInterval = 1, maxDelaySeconds: TimeInterval = 30) {
        self.maxAttempts = max(1, maxAttempts); self.baseDelaySeconds = max(0, baseDelaySeconds); self.maxDelaySeconds = max(baseDelaySeconds, maxDelaySeconds)
    }
    public func delay(forAttempt attempt: Int) -> TimeInterval { min(maxDelaySeconds, baseDelaySeconds * pow(2, Double(max(0, attempt - 1)))) }
}

public struct BackgroundSyncCheckpoint: Codable, Sendable, Equatable {
    public var provider: String
    public var cursor: String?
    public var lastSuccessfulSync: Date?
    public var consecutiveFailures: Int
    public var nextEligibleSyncAt: Date?
    public var lastError: String?
    public init(provider: String, cursor: String? = nil, lastSuccessfulSync: Date? = nil, consecutiveFailures: Int = 0, nextEligibleSyncAt: Date? = nil, lastError: String? = nil) {
        self.provider = provider; self.cursor = cursor; self.lastSuccessfulSync = lastSuccessfulSync; self.consecutiveFailures = consecutiveFailures; self.nextEligibleSyncAt = nextEligibleSyncAt; self.lastError = lastError
    }
}
