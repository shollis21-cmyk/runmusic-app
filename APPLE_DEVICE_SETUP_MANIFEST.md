# Apple Device Setup Manifest

## Background refresh

- Add `com.runmusic.provider-refresh` to `BGTaskSchedulerPermittedIdentifiers` in the iOS target Info.plist.
- Enable the Background fetch capability.
- Register the identifier during app launch before scheduling the first request.
- Route the registered handler to the provider ingestion service and always call task completion.
- Use the returned `BackgroundRefreshPolicy` date for the next request; do not wait inside the task.

This is the configuration the host Xcode project will require when physical-device testing begins.

- iOS deployment target: iOS 17+
- watchOS deployment target: watchOS 10+
- HealthKit capability on iPhone and Watch targets
- Background Modes: audio where Apple Music playback is owned by the app; workout processing on Watch
- MusicKit capability on the iOS target
- WatchConnectivity companion relationship
- Privacy usage strings for Health data reads/writes and music access as required by the final target configuration
- App Group/keychain access group only if a concrete cross-process storage need emerges; do not add preemptively
- No HealthKit data in iCloud-backed storage

The package intentionally keeps entitlements out of the core library. They belong to the signed host app targets.
