# friendly-spoon

Open-source macOS menu bar app for reading split-keyboard battery levels over Bluetooth.

friendly-spoon lives in your menu bar, polls your paired keyboard every 60 seconds, and shows left/right battery levels in a compact status item.

## Features

- Menu bar battery display for left/right keyboard halves
- Manual refresh and battery read actions
- Appearance settings: block bars, split-half glyphs, numbers, colors, worst-half-only mode
- Launch-at-login toggle
- Menu bar only; no Dock icon while running
- Local-only Bluetooth access; no network calls or analytics

## Install

1. Download the latest `friendly-spoon-*-macos.zip` from [Releases](https://github.com/lxhan/friendly-spoon/releases).
2. Unzip it.
3. Move `friendly-spoon.app` to `/Applications`.
4. Open it.
5. If macOS warns about the app, see [macOS says “Move to Trash”](#macos-says-move-to-trash).

## First run

1. Pair your keyboard in **System Settings → Bluetooth** first.
2. Start `friendly-spoon`.
3. Allow Bluetooth permission if macOS asks.
4. Click the menu bar keyboard icon.
5. Choose your keyboard from the list.
6. Click **Read battery now** if values do not appear immediately.

## Troubleshooting

### macOS says “Move to Trash”

Current public builds are open-source but **not Apple Developer ID notarized** yet. macOS Gatekeeper may show:

```text
Apple could not verify “friendly-spoon” is free of malware that may harm your Mac or compromise your privacy.
```

Options:

#### Safer option: build from source

```bash
git clone https://github.com/lxhan/friendly-spoon.git
cd friendly-spoon
xcodebuild \
  -project friendly-spoon.xcodeproj \
  -scheme FriendlySpoon \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath build \
  ONLY_ACTIVE_ARCH=NO \
  build
open build/Build/Products/Release/friendly-spoon.app
```

#### Quick option: remove quarantine from downloaded app

Only do this if you trust the release you downloaded.

```bash
xattr -dr com.apple.quarantine /Applications/friendly-spoon.app
open /Applications/friendly-spoon.app
```

#### UI option

Right-click `friendly-spoon.app` → **Open** → confirm. On some macOS versions you may also need **System Settings → Privacy & Security → Open Anyway**.

Long-term fix: sign and notarize releases with Apple Developer ID.

### No keyboards found

- Pair the keyboard in macOS Bluetooth first.
- Keep the keyboard awake.
- Click **Refresh devices**.
- Toggle Bluetooth off/on.
- Quit and reopen friendly-spoon.
- Check **System Settings → Privacy & Security → Bluetooth** and allow friendly-spoon.

friendly-spoon currently reads connected peripherals that expose the standard Bluetooth Battery Service (`180F`) and Battery Level characteristic (`2A19`). Some keyboards do not expose battery this way.

### Only one half updates, or left/right look swapped

Some split keyboards report the same Battery Level characteristic twice, once per half. friendly-spoon currently uses a simple left/right flip-flop for those callbacks. This works for the original target keyboard but may be wrong for other firmware.

Try:

- Click **Read battery now** twice.
- Reconnect the keyboard.
- Open an issue with keyboard model, firmware, and logs.

### Battery never changes

- Some keyboards cache battery values.
- Some firmware only updates battery after reconnect.
- friendly-spoon polls every 60 seconds and after system wake.
- Use **Read battery now** for manual polling.

### Launch at login does not work

- Toggle **Settings → Launch at login** off and on.
- Confirm friendly-spoon is in `/Applications`.
- Reopen the app after moving it.

## Privacy

friendly-spoon:

- reads Bluetooth peripheral names and battery percentages;
- stores display preferences locally via `UserDefaults`;
- stores the selected Bluetooth peripheral UUID locally;
- makes no network requests;
- has no telemetry.

## Build

Requirements:

- macOS
- Xcode

Build release app:

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

## Package a zip

```bash
cd build/Build/Products/Release
ditto -c -k --keepParent friendly-spoon.app friendly-spoon-macos.zip
shasum -a 256 friendly-spoon-macos.zip
```

## Uninstall

1. Quit friendly-spoon from the menu bar.
2. Delete `/Applications/friendly-spoon.app`.
3. Optional: remove local settings:

```bash
defaults delete dev.lxhan.friendly-spoon 2>/dev/null || true
```

## Contributing

Issues and pull requests welcome. Useful bug reports include:

- macOS version
- keyboard model and firmware
- whether macOS Bluetooth settings show a battery level
- friendly-spoon status text
- screenshots of menu/settings if relevant

## Known limitations

- Releases are currently ad-hoc signed, not notarized.
- Split-half battery mapping is heuristic.
- Keyboards without standard BLE Battery Service support may not work.
