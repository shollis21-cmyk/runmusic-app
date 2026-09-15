import Foundation
import RunMusicCore

#if canImport(WatchConnectivity)
import WatchConnectivity

public actor WatchConnectivityCompanionTransport: CompanionTransport {
    private let session: WCSession
    private let encoder = JSONEncoder()

    public init(session: WCSession = .default) {
        self.session = session
        if WCSession.isSupported() { session.activate() }
    }

    public func publishLatestState(_ state: CompanionRunState) async throws {
        let data = try encoder.encode(state)
        try session.updateApplicationContext(["runmusic.latestState": data])
    }

    public func enqueueDurableEvent(_ event: OfflineEvent) async throws {
        let data = try encoder.encode(event)
        session.transferUserInfo(["runmusic.event": data])
    }
}

#else

public struct WatchConnectivityCompanionTransport: CompanionTransport {
    public init() {}
    public func publishLatestState(_ state: CompanionRunState) async throws {}
    public func enqueueDurableEvent(_ event: OfflineEvent) async throws {}
}

#endif
