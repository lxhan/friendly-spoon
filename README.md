# friendly-spoon

macOS menu bar app for reading split keyboard battery levels over Bluetooth.

## Features

- Menu bar battery display for left/right keyboard halves
- Manual refresh and battery read actions
- Appearance settings for bars, split-half glyphs, numbers, color, and worst-half-only mode
- Launch-at-login toggle

## Build

```bash
xcodebuild \
  -project friendly-spoon.xcodeproj \
  -scheme FriendlySpoon \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath build \
  ONLY_ACTIVE_ARCH=NO \
  build
```

Built app appears at:

```text
build/Build/Products/Release/friendly-spoon.app
```
