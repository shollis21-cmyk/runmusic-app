import Foundation

public struct IntegrationHealthInput: Sendable, Equatable {
    public let providerID: String
    public let displayName: String
    public let authorization: AuthorizationState
    public let checkpoint: BackgroundSyncCheckpoint?
    public let pendingItemCount: Int

    public init(providerID: String, displayName: String, authorization: AuthorizationState, checkpoint: BackgroundSyncCheckpoint? = nil, pendingItemCount: Int = 0) {
        self.providerID = providerID
        self.displayName = displayName
        self.authorization = authorization
        self.checkpoint = checkpoint
        self.pendingItemCount = max(0, pendingItemCount)
    }
}

public struct IntegrationHealthEngine: Sendable {
    private let policy: ConnectionHealthPolicy
    public init(policy: ConnectionHealthPolicy = ConnectionHealthPolicy()) { self.policy = policy }

    public func evaluate(_ input: IntegrationHealthInput, now: Date = Date()) -> ProviderConnectionHealth {
        guard input.authorization == .authorized else {
            let attention: Bool = input.authorization == .denied || input.authorization == .restricted
            return ProviderConnectionHealth(
                id: input.providerID,
                displayName: input.displayName,
                status: attention ? .needsAttention : .notConnected,
                pendingItemCount: input.pendingItemCount,
                message: attention ? "Reconnect to continue syncing." : "Not connected"
            )
        }

        let blocked = input.checkpoint?.lastError != nil
        let status = policy.status(
            lastSuccessfulSyncAt: input.checkpoint?.lastSuccessfulSync,
            pendingCount: input.pendingItemCount,
            hasBlockingError: blocked,
            now: now
        )
        let message: String?
        if let retryAt = input.checkpoint?.nextEligibleSyncAt, retryAt > now {
            message = "Sync paused until \(retryAt.formatted(date: .omitted, time: .shortened))."
        } else if blocked {
            message = "Sync needs attention. Your local data is safe."
        } else if input.pendingItemCount > 0 {
            message = "\(input.pendingItemCount) item\(input.pendingItemCount == 1 ? "" : "s") waiting to sync."
        } else {
            message = nil
        }
        return ProviderConnectionHealth(
            id: input.providerID,
            displayName: input.displayName,
            status: status,
            lastSuccessfulSyncAt: input.checkpoint?.lastSuccessfulSync,
            pendingItemCount: input.pendingItemCount,
            message: message
        )
    }
}
