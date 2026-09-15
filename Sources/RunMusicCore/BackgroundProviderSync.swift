import Foundation

public protocol BackgroundSyncCheckpointStoring: Sendable {
    func load(provider: String) async throws -> BackgroundSyncCheckpoint?
    func save(_ checkpoint: BackgroundSyncCheckpoint) async throws
}

public actor InMemoryBackgroundSyncCheckpointStore: BackgroundSyncCheckpointStoring {
    private var values: [String: BackgroundSyncCheckpoint] = [:]
    public init() {}
    public func load(provider: String) -> BackgroundSyncCheckpoint? { values[provider] }
    public func save(_ checkpoint: BackgroundSyncCheckpoint) { values[checkpoint.provider] = checkpoint }
}

public actor FileBackgroundSyncCheckpointStore: BackgroundSyncCheckpointStoring {
    private let fileURL: URL
    private var values: [String: BackgroundSyncCheckpoint]

    public init(fileURL: URL) throws {
        self.fileURL = fileURL
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            if data.isEmpty {
                values = [:]
            } else {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                values = try decoder.decode([String: BackgroundSyncCheckpoint].self, from: data)
            }
        } else {
            values = [:]
        }
    }

    public func load(provider: String) -> BackgroundSyncCheckpoint? { values[provider] }

    public func save(_ checkpoint: BackgroundSyncCheckpoint) throws {
        values[checkpoint.provider] = checkpoint
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(values).write(to: fileURL, options: [.atomic])
    }
}

public struct ProviderSyncPage: Sendable, Equatable {
    public let nextCursor: String?
    public let importedItemCount: Int
    public init(nextCursor: String?, importedItemCount: Int) {
        self.nextCursor = nextCursor
        self.importedItemCount = max(0, importedItemCount)
    }
}

public enum BackgroundSyncDisposition: Sendable, Equatable {
    case completed(importedItemCount: Int)
    case deferred(until: Date)
    case failed(retryAt: Date)
}

public struct BackgroundSyncResult: Sendable, Equatable {
    public let checkpoint: BackgroundSyncCheckpoint
    public let disposition: BackgroundSyncDisposition
}

public actor RateLimitAwareBackgroundSyncCoordinator {
    public typealias Operation = @Sendable (_ cursor: String?) async throws -> ProviderSyncPage

    private let store: any BackgroundSyncCheckpointStoring
    private let retryPolicy: RetryPolicy

    public init(store: any BackgroundSyncCheckpointStoring, retryPolicy: RetryPolicy = RetryPolicy()) {
        self.store = store
        self.retryPolicy = retryPolicy
    }

    public func sync(provider: String, now: Date = Date(), operation: Operation) async throws -> BackgroundSyncResult {
        var checkpoint = try await store.load(provider: provider) ?? BackgroundSyncCheckpoint(provider: provider)
        if let eligible = checkpoint.nextEligibleSyncAt, eligible > now {
            return BackgroundSyncResult(checkpoint: checkpoint, disposition: .deferred(until: eligible))
        }

        do {
            let page = try await operation(checkpoint.cursor)
            checkpoint.cursor = page.nextCursor
            checkpoint.lastSuccessfulSync = now
            checkpoint.consecutiveFailures = 0
            checkpoint.nextEligibleSyncAt = nil
            checkpoint.lastError = nil
            try await store.save(checkpoint)
            return BackgroundSyncResult(checkpoint: checkpoint, disposition: .completed(importedItemCount: page.importedItemCount))
        } catch let error as IntegrationTransportError {
            checkpoint.consecutiveFailures += 1
            checkpoint.lastError = String(describing: error)
            let retryAt: Date
            if case let .rateLimited(retryAfterSeconds) = error, let retryAfterSeconds {
                retryAt = now.addingTimeInterval(max(1, retryAfterSeconds))
            } else {
                retryAt = now.addingTimeInterval(retryPolicy.delay(forAttempt: checkpoint.consecutiveFailures))
            }
            checkpoint.nextEligibleSyncAt = retryAt
            try await store.save(checkpoint)
            return BackgroundSyncResult(checkpoint: checkpoint, disposition: .failed(retryAt: retryAt))
        } catch {
            checkpoint.consecutiveFailures += 1
            checkpoint.lastError = String(describing: error)
            let retryAt = now.addingTimeInterval(retryPolicy.delay(forAttempt: checkpoint.consecutiveFailures))
            checkpoint.nextEligibleSyncAt = retryAt
            try await store.save(checkpoint)
            return BackgroundSyncResult(checkpoint: checkpoint, disposition: .failed(retryAt: retryAt))
        }
    }
}
