import Foundation

public struct BackgroundRefreshPolicy: Sendable, Equatable {
    public let normalInterval: TimeInterval
    public let minimumInterval: TimeInterval

    public init(normalInterval: TimeInterval = 60 * 60, minimumInterval: TimeInterval = 15 * 60) {
        self.normalInterval = max(60, normalInterval)
        self.minimumInterval = max(60, minimumInterval)
    }

    public func nextRefreshDate(after result: BackgroundSyncResult, now: Date = Date()) -> Date {
        let candidate: Date
        switch result.disposition {
        case .completed:
            candidate = now.addingTimeInterval(normalInterval)
        case let .deferred(until), let .failed(retryAt: until):
            candidate = until
        }
        return max(candidate, now.addingTimeInterval(minimumInterval))
    }
}

public struct ProviderIntegrationDescriptor: Sendable, Equatable {
    public let providerID: String
    public let displayName: String
    public let authorization: AuthorizationState
    public let pendingItemCount: Int

    public init(providerID: String, displayName: String, authorization: AuthorizationState, pendingItemCount: Int = 0) {
        self.providerID = providerID
        self.displayName = displayName
        self.authorization = authorization
        self.pendingItemCount = max(0, pendingItemCount)
    }
}

public actor IntegrationHealthService {
    private let checkpointStore: any BackgroundSyncCheckpointStoring
    private let engine: IntegrationHealthEngine

    public init(checkpointStore: any BackgroundSyncCheckpointStoring, engine: IntegrationHealthEngine = IntegrationHealthEngine()) {
        self.checkpointStore = checkpointStore
        self.engine = engine
    }

    public func snapshot(_ providers: [ProviderIntegrationDescriptor], now: Date = Date()) async throws -> [ProviderConnectionHealth] {
        var health: [ProviderConnectionHealth] = []
        for provider in providers {
            let checkpoint = try await checkpointStore.load(provider: provider.providerID)
            health.append(engine.evaluate(IntegrationHealthInput(
                providerID: provider.providerID,
                displayName: provider.displayName,
                authorization: provider.authorization,
                checkpoint: checkpoint,
                pendingItemCount: provider.pendingItemCount
            ), now: now))
        }
        return health.sorted { $0.displayName < $1.displayName }
    }
}
