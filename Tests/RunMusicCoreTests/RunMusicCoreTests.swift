import XCTest
@testable import RunMusicCore

final class RunMusicCoreTests: XCTestCase {
    func testRunRequestDuration() {
        let request = RunRequest(distanceMeters: 5000, targetPaceSecondsPerKilometer: 360)
        XCTAssertEqual(request.targetDurationSeconds, 1800, accuracy: 0.001)
    }

    func testDemoTracksExist() {
        XCTAssertFalse(DemoFactory.tracks().isEmpty)
    }

    func testRunnerProfileConfidenceIsClamped() {
        let profile = RunnerProfile(dataConfidence: 2)
        XCTAssertEqual(profile.dataConfidence, 1)
    }
}
