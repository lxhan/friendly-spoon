import SwiftUI
import CoreBluetooth
import AppKit

private let friendlySpoonTroubleshootingURL = URL(string: "https://github.com/lxhan/friendly-spoon#troubleshooting")!

@main
struct FriendlySpoonApp: App {
    @StateObject private var reader = BatteryReader()
    @AppStorage("menuBarStyle") private var styleRaw: String = MenuBarStyle.bars.rawValue
    @AppStorage("halfGlyphs") private var glyphsRaw: String = HalfGlyphs.blocks.rawValue
    @AppStorage("colorize") private var colorize: Bool = true
    @AppStorage("worstOnly") private var worstOnly: Bool = false

    private var style: MenuBarStyle {
        MenuBarStyle(rawValue: styleRaw) ?? .bars
    }

    private var glyphs: HalfGlyphs {
        HalfGlyphs(rawValue: glyphsRaw) ?? .blocks
    }

    var body: some Scene {
        MenuBarExtra {
            Text(reader.status)
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            if reader.availablePeripherals.isEmpty {
                Text("No keyboards found")
                    .foregroundStyle(.secondary)
                Text("Pair the keyboard in macOS Bluetooth first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(reader.availablePeripherals, id: \.identifier) { p in
                    Button {
                        reader.select(p)
                    } label: {
                        if p.identifier == reader.selectedPeripheralID {
                            Label(p.name ?? "Unknown", systemImage: "checkmark")
                        } else {
                            Text(p.name ?? "Unknown")
                        }
                    }
                }
            }
            Divider()
            Button("Read battery now") { reader.readBattery() }
            Button("Refresh devices") { reader.refresh() }
            Divider()
            SettingsLink { Text("Settings…") }
            Button("Troubleshooting…") {
                NSWorkspace.shared.open(friendlySpoonTroubleshootingURL)
            }
            Button("Quit") { NSApplication.shared.terminate(nil) }
        } label: {
            if reader.isConnected && (reader.leftPercent > 0 || reader.rightPercent > 0) {
                MenuBarBitmapLabel(
                    text: menuBarContent(
                        left: reader.leftPercent,
                        right: reader.rightPercent,
                        style: style,
                        glyphs: glyphs,
                        colorize: colorize,
                        worstOnly: worstOnly
                    )
                )
            } else {
                Image(systemName: "keyboard")
            }
        }

        Settings { SettingsView() }
    }
}

/// Renders a (potentially multi-color) Text into an NSImage so the menu bar
/// preserves per-segment foreground colors. NSStatusBarButton's attributedTitle
/// rendering otherwise strips/normalizes colors.
private struct MenuBarBitmapLabel: View {
    let text: Text

    var body: some View {
        if let img = renderImage() {
            Image(nsImage: img)
        } else {
            text
        }
    }

    @MainActor
    private func renderImage() -> NSImage? {
        let renderer = ImageRenderer(content: text.font(.system(size: 14)))
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        guard let image = renderer.nsImage else { return nil }
        image.isTemplate = false  // keep the colors instead of letting macOS tint as template
        return image
    }
}
