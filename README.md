# RunMusic Core

Portable Swift domain engine for a running + music product that builds playlists around runner mechanics, music preference, course shape, and recognizable distance milestones.

## Current capabilities

- Provider-neutral activity ingestion contracts
- Canonical activity model with source provenance
- Best-source-per-metric selection and activity deduplication
- Manual runner/music fallback
- Offline event journal, retry-safe sync, and connection health
- Crash-restorable run sessions
- Race course model and grade segmentation
- Course-aware music energy strategy
- Playlist optimization for duration, cadence/BPM relationship, energy, preference, familiarity, artist repetition, and mile/km marker timing
- Music readiness + fallback substitution
- Unified pre-run readiness gate
- Provider capability registry and unconfigured adapter shells
- App-facing `RunBuilderService`

## Run locally

```bash
swift test
swift run RunMusicDemo
```

The demo builds a 5-mile, 9:00/mi course-aware run plan from synthetic music data and prints the generated sequence and mile-marker timing errors.

## Apple-platform CI

The `Apple CI` GitHub Actions workflow runs the portable Swift tests and performs unsigned simulator builds for both the iPhone and Apple Watch targets on a hosted macOS/Xcode runner. It generates `RunMusic.xcodeproj` from `project.yml` with XcodeGen before compiling.

No Apple credentials or signing secrets are used by this validation workflow. Signed archives and TestFlight uploads remain a separate, explicitly approved release step.

## Architecture rule

The portable core does not import HealthKit, MusicKit, Strava SDKs, Garmin SDKs, or Spotify SDKs. Platform/provider implementations sit behind stable contracts so external API changes do not rewrite the recommendation engine.
