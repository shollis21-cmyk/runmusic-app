# Swift setup

RunMusic uses Swift Package Manager for the portable core and Xcode/XcodeGen for Apple targets.

Portable validation:

```sh
swift test --jobs 1 --no-parallel -Xswiftc -disable-batch-mode
```

Apple validation on macOS:

```sh
brew install xcodegen
xcodegen generate
Scripts/ci-apple-build.sh
```

GitHub Actions runs both validations on `macos-latest`.
