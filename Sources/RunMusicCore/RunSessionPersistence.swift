import Foundation

public protocol RunSessionSnapshotStoring: Sendable { func load() async throws -> RunSessionSnapshot?; func save(_ snapshot: RunSessionSnapshot) async throws; func clear() async throws }

public actor InMemoryRunSessionSnapshotStore: RunSessionSnapshotStoring {
    private var snapshot: RunSessionSnapshot?
    public init(snapshot: RunSessionSnapshot? = nil) { self.snapshot = snapshot }
    public func load() -> RunSessionSnapshot? { snapshot }
    public func save(_ snapshot: RunSessionSnapshot) { self.snapshot = snapshot }
    public func clear() { snapshot = nil }
}

public actor FileRunSessionSnapshotStore: RunSessionSnapshotStoring {
    private let fileURL: URL
    public init(fileURL: URL) throws { self.fileURL = fileURL; try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true) }
    public func load() throws -> RunSessionSnapshot? { guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }; let data = try Data(contentsOf: fileURL); guard !data.isEmpty else { return nil }; let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601; return try decoder.decode(RunSessionSnapshot.self, from: data) }
    public func save(_ snapshot: RunSessionSnapshot) throws { let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting = [.sortedKeys]; let data = try encoder.encode(snapshot); try data.write(to: fileURL, options: [.atomic]) }
    public func clear() throws { guard FileManager.default.fileExists(atPath: fileURL.path) else { return }; try FileManager.default.removeItem(at: fileURL) }
}

public actor RecoverableRunSession {
    private let machine: RunSessionMachine
    private let store: any RunSessionSnapshotStoring
    public init(milestoneMeters: Double = 1609.344, store: any RunSessionSnapshotStoring) async throws { self.store = store; if let saved = try await store.load(), saved.phase != .finished, saved.phase != .failed { self.machine = RunSessionMachine(milestoneMeters: milestoneMeters, restoring: saved) } else { self.machine = RunSessionMachine(milestoneMeters: milestoneMeters) } }
    public func current() async -> RunSessionSnapshot { await machine.current() }
    public func prepare() async throws { try await machine.prepare(); try await persist() }
    public func markReady() async throws { try await machine.markReady(); try await persist() }
    public func start(at date: Date = Date()) async throws { try await machine.start(at: date); try await persist() }
    public func pause() async throws { try await machine.pause(); try await persist() }
    public func resume() async throws { try await machine.resume(); try await persist() }
    @discardableResult public func ingest(_ sample: RunTelemetrySample) async throws -> [Int] { let reached = try await machine.ingest(sample); try await persist(); return reached }
    public func finish(at date: Date = Date()) async throws { try await machine.finish(at: date); try await store.clear() }
    private func persist() async throws { try await store.save(await machine.current()) }
}
