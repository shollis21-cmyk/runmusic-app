import UIKit
import RunMusicCore
import RunMusicApplePlatform

final class RunMusicAppDelegate: NSObject, UIApplicationDelegate {
    static let refreshIdentifier = "com.runmusic.provider-refresh"
    private let scheduler = IOSBackgroundRefreshScheduler()
    private let runtime = ProviderRefreshRuntime()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        scheduler.register(identifier: Self.refreshIdentifier) { [runtime] in
            try await runtime.run()
        }
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Task { [scheduler, runtime] in
            guard let date = await runtime.nextRequestedRefreshDate() else { return }
            try? scheduler.schedule(identifier: Self.refreshIdentifier, earliestBeginDate: date)
        }
    }
}

actor ProviderRefreshRuntime {
    typealias Operation = @Sendable () async throws -> BackgroundSyncResult
    private var operation: Operation?
    private var nextRefreshDate: Date?

    func install(operation: @escaping Operation, firstRefreshDate: Date = Date().addingTimeInterval(15 * 60)) {
        self.operation = operation
        nextRefreshDate = firstRefreshDate
    }

    func run() async throws -> BackgroundSyncResult {
        guard let operation else {
            throw ProviderAdapterError.notConfigured("Provider credentials have not been installed.")
        }
        let result = try await operation()
        nextRefreshDate = BackgroundRefreshPolicy().nextRefreshDate(after: result)
        return result
    }

    func nextRequestedRefreshDate() -> Date? { nextRefreshDate }
}
