import Foundation
import RunMusicCore

#if canImport(BackgroundTasks) && os(iOS)
import BackgroundTasks

public enum IOSBackgroundRefreshError: Error, Sendable {
    case unexpectedTaskType
}

public final class IOSBackgroundRefreshScheduler: @unchecked Sendable {
    public typealias Handler = @Sendable () async throws -> BackgroundSyncResult

    private let scheduler: BGTaskScheduler
    private let policy: BackgroundRefreshPolicy

    public init(scheduler: BGTaskScheduler = .shared, policy: BackgroundRefreshPolicy = BackgroundRefreshPolicy()) {
        self.scheduler = scheduler
        self.policy = policy
    }

    /// Register during app launch. The identifier must also appear in
    /// BGTaskSchedulerPermittedIdentifiers in the iOS target's Info.plist.
    @discardableResult
    public func register(identifier: String, handler: @escaping Handler) -> Bool {
        scheduler.register(forTaskWithIdentifier: identifier, using: nil) { [weak self] task in
            guard let self, let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            let work = Task {
                do {
                    let result = try await handler()
                    try self.schedule(identifier: identifier, earliestBeginDate: self.policy.nextRefreshDate(after: result))
                    refreshTask.setTaskCompleted(success: true)
                } catch is CancellationError {
                    refreshTask.setTaskCompleted(success: false)
                } catch {
                    refreshTask.setTaskCompleted(success: false)
                }
            }
            refreshTask.expirationHandler = { work.cancel() }
        }
    }

    public func schedule(identifier: String, earliestBeginDate: Date) throws {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = earliestBeginDate
        try scheduler.submit(request)
    }

    public func cancel(identifier: String) {
        scheduler.cancel(taskRequestWithIdentifier: identifier)
    }
}
#endif
