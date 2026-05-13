import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class LaunchAtLogin: ObservableObject {
    @Published var isEnabled: Bool

    init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }

    func apply() {
        let want = isEnabled
        let have = SMAppService.mainApp.status == .enabled
        guard want != have else { return }
        do {
            if want {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("[LaunchAtLogin] toggle failed: \(error)")
            isEnabled = SMAppService.mainApp.status == .enabled
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
            }

            Text("Battery is polled every 60 seconds and on system wake.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 360)
    }
}
