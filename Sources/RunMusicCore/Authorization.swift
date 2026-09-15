import Foundation

public enum AuthorizationState: String, Codable, Sendable, Equatable {
    case unknown
    case requesting
    case authorized
    case denied
    case restricted
    case unavailable
}

public struct ProviderAuthorizationStatus: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let providerName: String
    public let state: AuthorizationState
    public let lastUpdatedAt: Date
    public let detail: String?

    public init(providerName: String, state: AuthorizationState, lastUpdatedAt: Date = Date(), detail: String? = nil) {
        self.id = providerName.lowercased().replacingOccurrences(of: " ", with: "-")
        self.providerName = providerName
        self.state = state
        self.lastUpdatedAt = lastUpdatedAt
        self.detail = detail
    }
}

public protocol ProviderAuthorizing: Sendable {
    var providerName: String { get }
    func currentStatus() async -> ProviderAuthorizationStatus
    func requestAuthorization() async -> ProviderAuthorizationStatus
}

public actor AuthorizationRegistry {
    private var statuses: [String: ProviderAuthorizationStatus] = [:]

    public init() {}

    public func update(_ status: ProviderAuthorizationStatus) {
        statuses[status.id] = status
    }

    public func status(for providerName: String) -> ProviderAuthorizationStatus? {
        statuses[providerName.lowercased().replacingOccurrences(of: " ", with: "-")]
    }

    public func all() -> [ProviderAuthorizationStatus] {
        statuses.values.sorted { $0.providerName < $1.providerName }
    }
}
