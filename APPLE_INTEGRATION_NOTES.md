# Apple Integration Notes

## HealthKit
RunMusic requests only metrics required for the product: workouts, running/walking distance, heart rate, running speed, running power, running stride length, running ground contact time, running vertical oscillation, and step count.

HealthKit has no dedicated running-cadence quantity in the public data-type set. Cadence is therefore sourced from higher-fidelity providers when available; if step-count samples are sufficiently granular, RunMusic may derive a lower-confidence estimate and preserves that provenance/confidence.

The Watch is designed as an independent recorder. An active workout session provides the background execution model. The app will request workout write permission only because it records a RunMusic workout; historical read-only integrations remain separate.

## WatchConnectivity
- `updateApplicationContext` semantics: current replaceable snapshot such as latest run state.
- background/durable transfer semantics: append-only run events that must not be lost.
- The authoritative workout event journal stays local until acknowledged by the destination/backend.

## Apple Music
The intended deep Apple Music experience uses MusicKit authorization plus `ApplicationMusicPlayer`, keeping RunMusic playback isolated from the user's Music app state. Background audio capability is part of the production capability plan.

## Device validation gate
The Apple-only adapters are structurally present but cannot be fully exercised in this Linux build environment. Before beta, validate on physical iPhone + Apple Watch:
- permission prompts and partial-denial behavior
- background workout execution
- phone disconnect/reconnect
- Watch-only run recording
- queued connectivity transfers
- background Apple Music playback
- interruption handling (calls/Siri/headphones)
- crash/relaunch restoration
