import Foundation
import ServiceManagement

private enum LaunchAtLoginServiceError: LocalizedError {
    case missingExecutableURL

    var errorDescription: String? {
        switch self {
        case .missingExecutableURL:
            "Could not find friendly-spoon executable path."
        }
    }
}

enum LaunchAtLoginService {
    private static let label = "dev.lxhan.friendly-spoon.launch-at-login"

    private static var launchAgentsDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LaunchAgents", isDirectory: true)
    }

    static var plistURL: URL {
        launchAgentsDirectory.appendingPathComponent("\(label).plist", isDirectory: false)
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
        || SMAppService.mainApp.status == .enabled
    }

    /// Keep old SMAppService registrations working by migrating them to a
    /// LaunchAgent. SMAppService can silently fail for ad-hoc / unsigned builds
    /// after reboot; a user LaunchAgent is more reliable for this small menu app.
    static func repairExistingRegistration() {
        do {
            if FileManager.default.fileExists(atPath: plistURL.path) {
                try writeLaunchAgentPlist()
            }

            if SMAppService.mainApp.status == .enabled {
                try writeLaunchAgentPlist()
                unregisterLegacyLoginItem()
            }
        } catch {
            NSLog("[LaunchAtLogin] repair failed: \(error)")
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try writeLaunchAgentPlist()
            unregisterLegacyLoginItem()
        } else {
            if FileManager.default.fileExists(atPath: plistURL.path) {
                try FileManager.default.removeItem(at: plistURL)
            }
            unregisterLegacyLoginItem()
        }
    }

    private static func writeLaunchAgentPlist() throws {
        guard let executableURL = Bundle.main.executableURL else {
            throw LaunchAtLoginServiceError.missingExecutableURL
        }

        try FileManager.default.createDirectory(
            at: launchAgentsDirectory,
            withIntermediateDirectories: true
        )

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executableURL.path],
            "RunAtLoad": true,
            "KeepAlive": false,
            "ProcessType": "Interactive",
            "LimitLoadToSessionType": "Aqua"
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(to: plistURL, options: .atomic)
    }

    private static func unregisterLegacyLoginItem() {
        guard SMAppService.mainApp.status == .enabled else { return }
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            NSLog("[LaunchAtLogin] legacy unregister failed: \(error)")
        }
    }
}
