import Foundation
import RunMusicCore
import RunMusicApplePlatform

public enum AppScreen: String, Sendable, Equatable {
    case onboarding, home, buildRun, plan, ready, liveRun, postRun
}

#if canImport(Combine)
import Combine

@MainActor
public final class RunMusicAppViewModel: ObservableObject {
    @Published public private(set) var screen: AppScreen
    @Published public private(set) var runnerProfile: RunnerProfile
    @Published public private(set) var musicPreference: MusicPreference
    @Published public private(set) var currentPlan: PlaylistPlan?
    @Published public private(set) var authorizationStatuses: [ProviderAuthorizationStatus] = []
    @Published public private(set) var connectionHealth: [ProviderConnectionHealth] = []
    @Published public private(set) var errorMessage: String?

    private let builder: RunBuilderService
    private let registry: AuthorizationRegistry

    public init(
        screen: AppScreen = .onboarding,
        runnerProfile: RunnerProfile = RunnerProfile(),
        musicPreference: MusicPreference = MusicPreference(),
        builder: RunBuilderService = RunBuilderService(music: StaticMusicIntelligenceProvider(tracks: DemoFactory.tracks())),
        registry: AuthorizationRegistry = AuthorizationRegistry()
    ) {
        self.screen = screen
        self.runnerProfile = runnerProfile
        self.musicPreference = musicPreference
        self.builder = builder
        self.registry = registry
    }

    public func useManualRunnerProfile(_ profile: RunnerProfile) { runnerProfile = profile; screen = .home }
    public func useManualMusicPreference(_ preference: MusicPreference) { musicPreference = preference }

    public func recordAuthorization(_ status: ProviderAuthorizationStatus) async {
        await registry.update(status)
        authorizationStatuses = await registry.all()
    }

    public func updateConnectionHealth(_ health: [ProviderConnectionHealth]) {
        connectionHealth = health.sorted { $0.displayName < $1.displayName }
    }

    public func refreshConnectionHealth(_ providers: [ProviderIntegrationDescriptor], using service: IntegrationHealthService) async {
        do { connectionHealth = try await service.snapshot(providers) }
        catch { errorMessage = error.localizedDescription }
    }

    public func showBuildRun() { screen = .buildRun }
    public func showHome() { screen = .home }
    public func showPlan() { if currentPlan != nil { screen = .plan } }

    public func buildRun(_ request: RunRequest, course: RaceCourse? = nil, provider: MusicProvider = .appleMusic) async {
        errorMessage = nil
        do {
            let input = BuildRunInput(request: request, manualRunnerProfile: runnerProfile, musicPreference: musicPreference, course: course, provider: provider)
            let output = try await builder.build(input: input, activities: [])
            runnerProfile = output.runnerProfile
            currentPlan = output.playlist
            screen = .plan
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#else

@MainActor
public final class RunMusicAppViewModel {
    public private(set) var screen: AppScreen
    public private(set) var runnerProfile: RunnerProfile
    public private(set) var musicPreference: MusicPreference
    public private(set) var currentPlan: PlaylistPlan?
    public private(set) var authorizationStatuses: [ProviderAuthorizationStatus] = []
    public private(set) var connectionHealth: [ProviderConnectionHealth] = []
    public private(set) var errorMessage: String?

    private let builder: RunBuilderService
    private let registry: AuthorizationRegistry

    public init(
        screen: AppScreen = .onboarding,
        runnerProfile: RunnerProfile = RunnerProfile(),
        musicPreference: MusicPreference = MusicPreference(),
        builder: RunBuilderService = RunBuilderService(music: StaticMusicIntelligenceProvider(tracks: DemoFactory.tracks())),
        registry: AuthorizationRegistry = AuthorizationRegistry()
    ) {
        self.screen = screen
        self.runnerProfile = runnerProfile
        self.musicPreference = musicPreference
        self.builder = builder
        self.registry = registry
    }

    public func useManualRunnerProfile(_ profile: RunnerProfile) { runnerProfile = profile; screen = .home }
    public func useManualMusicPreference(_ preference: MusicPreference) { musicPreference = preference }
    public func recordAuthorization(_ status: ProviderAuthorizationStatus) async { await registry.update(status); authorizationStatuses = await registry.all() }
    public func updateConnectionHealth(_ health: [ProviderConnectionHealth]) { connectionHealth = health.sorted { $0.displayName < $1.displayName } }
    public func refreshConnectionHealth(_ providers: [ProviderIntegrationDescriptor], using service: IntegrationHealthService) async {
        do { connectionHealth = try await service.snapshot(providers) }
        catch { errorMessage = error.localizedDescription }
    }
    public func showBuildRun() { screen = .buildRun }
    public func showHome() { screen = .home }
    public func showPlan() { if currentPlan != nil { screen = .plan } }
    public func buildRun(_ request: RunRequest, course: RaceCourse? = nil, provider: MusicProvider = .appleMusic) async {
        errorMessage = nil
        do {
            let input = BuildRunInput(request: request, manualRunnerProfile: runnerProfile, musicPreference: musicPreference, course: course, provider: provider)
            let output = try await builder.build(input: input, activities: [])
            runnerProfile = output.runnerProfile
            currentPlan = output.playlist
            screen = .plan
        } catch { errorMessage = error.localizedDescription }
    }
}
#endif
