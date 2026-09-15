import Foundation

public enum RunSessionPhase: String, Codable, Sendable, Equatable { case idle, preparing, ready, running, paused, finished, failed }
public enum RunSessionError: Error, Equatable { case invalidTransition(from: RunSessionPhase, to: RunSessionPhase); case regressiveSample }

public struct RunSessionSnapshot: Codable, Sendable, Equatable {
    public let phase: RunSessionPhase
    public let startedAt: Date?
    public let endedAt: Date?
    public let elapsedSeconds: TimeInterval
    public let distanceMeters: Double
    public let lastSample: RunTelemetrySample?
    public let reachedMilestones: [Int]
    public init(phase: RunSessionPhase = .idle, startedAt: Date? = nil, endedAt: Date? = nil, elapsedSeconds: TimeInterval = 0, distanceMeters: Double = 0, lastSample: RunTelemetrySample? = nil, reachedMilestones: [Int] = []) {
        self.phase = phase; self.startedAt = startedAt; self.endedAt = endedAt; self.elapsedSeconds = max(0, elapsedSeconds); self.distanceMeters = max(0, distanceMeters); self.lastSample = lastSample; self.reachedMilestones = reachedMilestones
    }
}

public actor RunSessionMachine {
    private var snapshot: RunSessionSnapshot
    private let milestoneMeters: Double
    public init(milestoneMeters: Double = 1609.344, restoring snapshot: RunSessionSnapshot? = nil) { self.snapshot = snapshot ?? RunSessionSnapshot(); self.milestoneMeters = max(100, milestoneMeters) }
    public func current() -> RunSessionSnapshot { snapshot }
    public func prepare() throws { try transition(to: .preparing) }
    public func markReady() throws { try transition(to: .ready) }
    public func start(at date: Date = Date()) throws { guard snapshot.phase == .ready else { throw RunSessionError.invalidTransition(from: snapshot.phase, to: .running) }; snapshot = RunSessionSnapshot(phase: .running, startedAt: date) }
    public func pause() throws { try transition(to: .paused) }
    public func resume() throws { try transition(to: .running) }
    public func ingest(_ sample: RunTelemetrySample) throws -> [Int] {
        guard snapshot.phase == .running else { return [] }
        if let last = snapshot.lastSample, sample.elapsedSeconds < last.elapsedSeconds || sample.distanceMeters < last.distanceMeters { throw RunSessionError.regressiveSample }
        let previousMilestone = Int(snapshot.distanceMeters / milestoneMeters)
        let currentMilestone = Int(sample.distanceMeters / milestoneMeters)
        let newMilestones = currentMilestone > previousMilestone ? Array((previousMilestone + 1)...currentMilestone) : []
        snapshot = RunSessionSnapshot(phase: .running, startedAt: snapshot.startedAt, elapsedSeconds: sample.elapsedSeconds, distanceMeters: sample.distanceMeters, lastSample: sample, reachedMilestones: snapshot.reachedMilestones + newMilestones)
        return newMilestones
    }
    public func finish(at date: Date = Date()) throws { guard snapshot.phase == .running || snapshot.phase == .paused else { throw RunSessionError.invalidTransition(from: snapshot.phase, to: .finished) }; snapshot = RunSessionSnapshot(phase: .finished, startedAt: snapshot.startedAt, endedAt: date, elapsedSeconds: snapshot.elapsedSeconds, distanceMeters: snapshot.distanceMeters, lastSample: snapshot.lastSample, reachedMilestones: snapshot.reachedMilestones) }
    private func transition(to next: RunSessionPhase) throws {
        let allowed: [RunSessionPhase: Set<RunSessionPhase>] = [.idle:[.preparing],.preparing:[.ready,.failed],.ready:[.running,.failed],.running:[.paused,.finished,.failed],.paused:[.running,.finished,.failed],.finished:[],.failed:[]]
        guard allowed[snapshot.phase, default: []].contains(next) else { throw RunSessionError.invalidTransition(from: snapshot.phase, to: next) }
        snapshot = RunSessionSnapshot(phase: next, startedAt: snapshot.startedAt, endedAt: snapshot.endedAt, elapsedSeconds: snapshot.elapsedSeconds, distanceMeters: snapshot.distanceMeters, lastSample: snapshot.lastSample, reachedMilestones: snapshot.reachedMilestones)
    }
}
