import Foundation
import RunMusicCore

#if canImport(MusicKit)
import MusicKit

public actor AppleMusicAuthorizationAdapter: ProviderAuthorizing {
    public let providerName = "Apple Music"
    public init() {}

    public func currentStatus() async -> ProviderAuthorizationStatus {
        map(MusicAuthorization.currentStatus)
    }

    public func requestAuthorization() async -> ProviderAuthorizationStatus {
        let status = await MusicAuthorization.request()
        return map(status)
    }

    private func map(_ status: MusicAuthorization.Status) -> ProviderAuthorizationStatus {
        switch status {
        case .authorized:
            return ProviderAuthorizationStatus(providerName: providerName, state: .authorized)
        case .denied:
            return ProviderAuthorizationStatus(providerName: providerName, state: .denied)
        case .restricted:
            return ProviderAuthorizationStatus(providerName: providerName, state: .restricted)
        case .notDetermined:
            return ProviderAuthorizationStatus(providerName: providerName, state: .unknown)
        @unknown default:
            return ProviderAuthorizationStatus(providerName: providerName, state: .unknown)
        }
    }
}

#else

public struct AppleMusicAuthorizationAdapter: ProviderAuthorizing {
    public let providerName = "Apple Music"
    public init() {}
    public func currentStatus() async -> ProviderAuthorizationStatus {
        ProviderAuthorizationStatus(providerName: providerName, state: .unavailable, detail: "MusicKit is only available on supported Apple platforms.")
    }
    public func requestAuthorization() async -> ProviderAuthorizationStatus { await currentStatus() }
}

#endif
