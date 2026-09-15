import Foundation

public struct BuildRunInput: Sendable {
    public let request: RunRequest
    public let manualRunnerProfile: RunnerProfile?
    public let musicPreference: MusicPreference
    public let course: RaceCourse?
    public let provider: MusicProvider

    public init(request: RunRequest, manualRunnerProfile: RunnerProfile? = nil, musicPreference: MusicPreference, course: RaceCourse? = nil, provider: MusicProvider) {
        self.request = request
        self.manualRunnerProfile = manualRunnerProfile
        self.musicPreference = musicPreference
        self.course = course
        self.provider = provider
    }
}

public struct BuiltRun: Sendable, Equatable {
    public let runnerProfile: RunnerProfile
    public let request: RunRequest
    public let playlist: PlaylistPlan
    public let courseStrategy: CourseMusicStrategy?
}

public struct RunBuilderService: Sendable {
    private let runnerModel: any RunnerModeling
    private let music: any MusicIntelligenceProviding
    private let optimizer: any PlaylistOptimizing

    public init(runnerModel: any RunnerModeling = BasicRunnerModel(), music: any MusicIntelligenceProviding, optimizer: any PlaylistOptimizing = HeuristicPlaylistOptimizer()) {
        self.runnerModel = runnerModel
        self.music = music
        self.optimizer = optimizer
    }

    public func build(input: BuildRunInput, activities: [CanonicalActivity]) async throws -> BuiltRun {
        let runner = runnerModel.buildProfile(from: activities, manualFallback: input.manualRunnerProfile)
        let candidates = try await music.candidateTracks(preference: input.musicPreference, limit: 500)

        var request = input.request
        var courseStrategy: CourseMusicStrategy?
        if let course = input.course {
            let strategy = CourseMusicStrategyBuilder().build(course: course, baseProfile: input.request.energyProfile)
            courseStrategy = strategy
            request = RunRequest(
                distanceMeters: input.request.distanceMeters,
                targetPaceSecondsPerKilometer: input.request.targetPaceSecondsPerKilometer,
                intent: input.request.intent,
                energyProfile: input.request.energyProfile,
                desiredCadenceSPM: input.request.desiredCadenceSPM,
                milestoneDistanceMeters: input.request.milestoneDistanceMeters,
                musicEnergyAnchors: strategy.anchors
            )
        }
        let playlist = try optimizer.optimize(request: request, runner: runner, preference: input.musicPreference, candidates: candidates)
        return BuiltRun(runnerProfile: runner, request: request, playlist: playlist, courseStrategy: courseStrategy)
    }
}
