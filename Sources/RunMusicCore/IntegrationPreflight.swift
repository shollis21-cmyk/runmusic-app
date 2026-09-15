import Foundation

public enum IntegrationPreflightState: String, Codable, Sendable, Equatable { case ready, needsAuthorization, unavailable, degraded }

public struct IntegrationPreflightResult: Codable, Sendable, Equatable {
    public let provider: String
    public let state: IntegrationPreflightState
    public let detail: String?
    public init(provider: String, state: IntegrationPreflightState, detail: String? = nil) { self.provider = provider; self.state = state; self.detail = detail }
}

public struct IntegrationPreflight: Sendable {
    public init() {}
    public func evaluate(_ status: ProviderAuthorizationStatus) -> IntegrationPreflightResult {
        switch status.state {
        case .authorized: return .init(provider: status.providerName, state: .ready, detail: status.detail)
        case .unknown, .requesting: return .init(provider: status.providerName, state: .needsAuthorization, detail: status.detail)
        case .denied, .restricted: return .init(provider: status.providerName, state: .needsAuthorization, detail: status.detail)
        case .unavailable: return .init(provider: status.providerName, state: .unavailable, detail: status.detail)
        }
    }
}
