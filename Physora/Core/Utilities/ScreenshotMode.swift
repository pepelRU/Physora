import Foundation

/// Launch-argument switches used by the CI simulator capture step. They are
/// inert in normal launches and in Release builds.
enum ScreenshotMode {
    enum Screen: String {
        case solution
        case history
        case tools
    }

    static var isActive: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-physoraScreenshots")
        #else
        false
        #endif
    }

    static var tab: AppTab? {
        guard isActive, let value = value(after: "-physoraTab") else { return nil }
        return AppTab(rawValue: value)
    }

    static var screen: Screen? {
        guard isActive, let value = value(after: "-physoraScreen") else { return nil }
        return Screen(rawValue: value)
    }

    private static func value(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }
}
