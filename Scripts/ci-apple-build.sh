#!/bin/bash
set -euo pipefail

xcodebuild \
  -project RunMusic.xcodeproj \
  -scheme RunMusic \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  clean build

xcodebuild \
  -project RunMusic.xcodeproj \
  -target RunMusicWatch \
  -configuration Debug \
  -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath DerivedData-Watch \
  CODE_SIGNING_ALLOWED=NO \
  build

