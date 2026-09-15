import Foundation

public enum CompanionDeviceRole: String, Codable, Sendable { case phone, watch }
public struct CompanionRunState: Codable, Sendable, Equatable {
    public let sessionID: UUID; public let phase: RunSessionPhase; public let elapsedSeconds: TimeInterval; public let distanceMeters: Double; public let reachedMilestones: [Int]; public let lastUpdatedAt: Date
    public init(sessionID: UUID, phase: RunSessionPhase, elapsedSeconds: TimeInterval, distanceMeters: Double, reachedMilestones: [Int], lastUpdatedAt: Date = Date()) { self.sessionID=sessionID; self.phase=phase; self.elapsedSeconds=elapsedSeconds; self.distanceMeters=distanceMeters; self.reachedMilestones=reachedMilestones; self.lastUpdatedAt=lastUpdatedAt }
}
public enum CompanionMessage: Codable, Sendable, Equatable { case latestState(CompanionRunState); case durableEvent(OfflineEvent); case requestState(sessionID: UUID) }
public protocol CompanionTransport: Sendable { func publishLatestState(_ state: CompanionRunState) async throws; func enqueueDurableEvent(_ event: OfflineEvent) async throws }
public actor InMemoryCompanionTransport: CompanionTransport {
    public private(set) var latestState: CompanionRunState?
    public private(set) var events: [OfflineEvent] = []
    public init() {}
    public func publishLatestState(_ state: CompanionRunState) async throws { latestState = state }
    public func enqueueDurableEvent(_ event: OfflineEvent) async throws { events.append(event) }
}
