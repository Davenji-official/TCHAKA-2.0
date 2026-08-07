#!/usr/bin/env bash
set -euo pipefail

flutter --version
flutter pub get
flutter analyze
flutter test

# Build targets available on the current runner.
flutter build web --release
flutter build apk --release

# iOS artifacts require macOS/Xcode. Keep this check explicit so CI does not
# falsely claim iOS release readiness on Linux.
if [[ "$(uname -s)" == "Darwin" ]]; then
  flutter build ios --release --no-codesign
else
  echo "iOS build skipped: requires macOS/Xcode runner."
fi
