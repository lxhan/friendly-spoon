import SwiftUI
import Combine

private let friendlySpoonRepositoryURL = URL(string: "https://github.com/lxhan/friendly-spoon")!
private let friendlySpoonSettingsTroubleshootingURL = URL(string: "https://github.com/lxhan/friendly-spoon#troubleshooting")!

@MainActor
final class LaunchAtLogin: ObservableObject {
    @Published var isEnabled: Bool
    @Published var errorMessage: String?

    init() {
        LaunchAtLoginService.repairExistingRegistration()
        self.isEnabled = LaunchAtLoginService.isEnabled
    }

    func apply() {
        do {
            try LaunchAtLoginService.setEnabled(isEnabled)
            errorMessage = nil
            isEnabled = LaunchAtLoginService.isEnabled
        } catch {
            NSLog("[LaunchAtLogin] toggle failed: \(error)")
            errorMessage = error.localizedDescription
            isEnabled = LaunchAtLoginService.isEnabled
        }
    }
}

struct SettingsView: View {
    @StateObject private var launch = LaunchAtLogin()
    @AppStorage("menuBarStyle") private var styleRaw: String = MenuBarStyle.bars.rawValue
    @AppStorage("halfGlyphs") private var glyphsRaw: String = HalfGlyphs.blocks.rawValue
    @AppStorage("colorize") private var colorize: Bool = true
    @AppStorage("worstOnly") private var worstOnly: Bool = false

    private var styleBinding: Binding<MenuBarStyle> {
        Binding(
            get: { MenuBarStyle(rawValue: styleRaw) ?? .bars },
            set: { styleRaw = $0.rawValue }
        )
    }

    private var glyphsBinding: Binding<HalfGlyphs> {
        Binding(
            get: { HalfGlyphs(rawValue: glyphsRaw) ?? .blocks },
            set: { glyphsRaw = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Menu bar style", selection: styleBinding) {
                    ForEach(MenuBarStyle.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }

                let currentStyle = MenuBarStyle(rawValue: styleRaw) ?? .bars
                if currentStyle == .halves {
                    Picker("Halves glyph", selection: glyphsBinding) {
                        ForEach(HalfGlyphs.allCases) { g in
                            Text(g.label).tag(g)
                        }
                    }
                }

                Toggle("Color by level (red < 20%, orange < 50%)", isOn: $colorize)
                Toggle("Show only the half with lower battery", isOn: $worstOnly)

                let currentGlyphs = HalfGlyphs(rawValue: glyphsRaw) ?? .blocks
                HStack {
                    Text("Preview").foregroundStyle(.secondary)
                    Spacer()
                    menuBarContent(left: 78, right: 18,
                                   style: currentStyle,
                                   glyphs: currentGlyphs,
                                   colorize: colorize,
                                   worstOnly: worstOnly)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
                }
            }

            Section("System") {
                Toggle("Launch at login", isOn: Binding(
                    get: { launch.isEnabled },
                    set: { newValue in
                        launch.isEnabled = newValue
                        launch.apply()
                    }
                ))

                if let errorMessage = launch.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Help") {
                Text("friendly-spoon is open source and stores settings locally on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("Read troubleshooting", destination: friendlySpoonSettingsTroubleshootingURL)
                Link("View source on GitHub", destination: friendlySpoonRepositoryURL)
            }

            Text("Battery is polled every 60 seconds and on system wake.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 430)
    }
}
