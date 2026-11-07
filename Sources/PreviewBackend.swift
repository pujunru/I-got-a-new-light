#if PREVIEW
import AppKit

/// Stands in for the admin backend in `./build.sh --preview`, so the interface can be
/// exercised without a password and without touching the real setting.
///
/// `LOGO_LIGHT_START` = on | off | unknown; `LOGO_LIGHT_FAIL` = cancel | error;
/// `LOGO_LIGHT_ACT` = 1 clicks the logo on launch;
/// `LOGO_LIGHT_SNAPSHOT` = a path for a PNG of the window, taken once it has settled.
final class PreviewBackend: LightBackend, @unchecked Sendable {
    private let lock = NSLock()
    private var current: LightState
    private let failure = ProcessInfo.processInfo.environment["LOGO_LIGHT_FAIL"]

    init() {
        let start = ProcessInfo.processInfo.environment["LOGO_LIGHT_START"] ?? "unknown"
        current = LightState(rawValue: start) ?? .on
        if start == "unknown" {
            UserDefaults.standard.removeObject(forKey: "lastConfirmedState")
        } else {
            UserDefaults.standard.set(start, forKey: "lastConfirmedState")
        }
    }

    func read() async throws -> LightState {
        try await Self.delay()
        try check()
        return locked { current }
    }

    func set(_ state: LightState) async throws -> LightState {
        try await Self.delay()
        try check()
        return locked { current = state; return state }
    }

    private static func delay() async throws { try await Task.sleep(for: .milliseconds(400)) }

    private func check() throws {
        switch failure {
        case "cancel": throw LightError.cancelled
        case "error": throw LightError.failed("The administrator password was not accepted.")
        default: break
        }
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}

enum PreviewHooks {
    @MainActor
    static func run(model: LogoLightModel) {
        let environment = ProcessInfo.processInfo.environment
        if environment["LOGO_LIGHT_ACT"] == "1" { model.primaryAction() }
        guard let path = environment["LOGO_LIGHT_SNAPSHOT"] else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            guard let view = NSApp.windows.first?.contentView,
                  let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
            view.cacheDisplay(in: view.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
            print("window", view.window?.frame.size ?? .zero, "content", view.bounds.size)
        }
    }
}
#endif
