import Foundation

public enum ConnectionStatus: String, Codable, Sendable {
    case notConnected, healthy, stale, needsAttention, unavailable
}

public struct ProviderConnectionHealth: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let status: ConnectionStatus
    public let lastSuccessfulSyncAt: Date?
    public let pendingItemCount: Int
    public let message: String?

    public init(
        id: String,
        displayName: String,
        status: ConnectionStatus,
        lastSuccessfulSyncAt: Date? = nil,
        pendingItemCount: Int = 0,
        message: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.status = status
        self.lastSuccessfulSyncAt = lastSuccessfulSyncAt
        self.pendingItemCount = max(0, pendingItemCount)
        self.message = message
    }
}

public struct ConnectionHealthPolicy: Sendable {
    public let staleAfter: TimeInterval

    public init(staleAfter: TimeInterval = 24 * 60 * 60) {
        self.staleAfter = max(60, staleAfter)
    }

    public func status(lastSuccessfulSyncAt: Date?, pendingCount: Int, hasBlockingError: Bool, now: Date = Date()) -> ConnectionStatus {
        if hasBlockingError { return .needsAttention }
        guard let lastSuccessfulSyncAt else { return .notConnected }
        if pendingCount > 0 { return .stale }
        return now.timeIntervalSince(lastSuccessfulSyncAt) > staleAfter ? .stale : .healthy
    }
}
