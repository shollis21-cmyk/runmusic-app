# Next Steps

## Completed foundation

- Shared Swift package compiles on Swift 6.2.
- Canonical activity model with provenance/confidence.
- Manual fallback for running metrics and music preferences.
- Provider contracts for activity ingestion, runner modeling, music intelligence, playlist optimization, and playback/export.
- Activity deduplication and per-metric source resolution.
- Offline event/sync state abstraction.
- Synthetic runner/music fixtures.
- Milestone-aware beam-search playlist optimizer.
- Automated tests and executable demo.

## Next build slice

1. Create an iOS/watchOS Xcode shell and wire this package into it.
2. Implement durable local persistence using SwiftData/Core Data-compatible adapters rather than in-memory storage.
3. Implement HealthKit authorization and activity ingestion first.
4. Build the first three polished SwiftUI flows: Connect Data, Build My Run, Playlist Plan.
5. Add Apple Music authorization/catalog adapter.
6. Add Strava OAuth adapter when credentials are created.
7. Add Spotify OAuth/export adapter when credentials are created.
8. Add race/course model and official-source lookup service.

## Credentials

No external credentials are required for the code in this package. When the first provider integration is ready, setup should be done one provider at a time with step-by-step instructions.
