# Xcode handoff

RunMusic contains iPhone and Apple Watch application targets generated from `project.yml` using XcodeGen.

## Open locally

1. Install Xcode and XcodeGen.
2. Run `xcodegen generate` from the repository root.
3. Open `RunMusic.xcodeproj`.
4. Select your Apple Developer team for both targets.
5. Build the `RunMusic` scheme on an iPhone simulator or signed device.

## Distribution

The repository intentionally does not store signing certificates, provisioning profiles, API keys, OAuth secrets, or App Store Connect credentials. Those belong in Apple/GitHub secret storage when TestFlight automation is enabled.
