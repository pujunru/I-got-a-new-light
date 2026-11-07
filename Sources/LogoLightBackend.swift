import Foundation

enum LightState: String, Sendable {
    case on, off
}

enum LightError: Error, Equatable {
    case cancelled
    case failed(String)
}

protocol LightBackend: Sendable {
    func read() async throws -> LightState
    func set(_ state: LightState) async throws -> LightState
}

/// Runs the commands from https://support.apple.com/en-us/149248 as root.
///
/// The setting lives in root's preferences, so an unprivileged process can neither read
/// nor change it. Every call goes through the standard macOS administrator prompt; macOS
/// reuses the authorization for a few minutes.
struct AdminLightBackend: LightBackend {
    /// `NSAppleScript` must not run concurrently, and running it on the main thread would
    /// freeze the window for as long as the password prompt is open.
    private static let queue = DispatchQueue(label: "local.LogoLight.applescript")

    func read() async throws -> LightState {
        try await run(LightScript.source(for: nil))
    }

    func set(_ state: LightState) async throws -> LightState {
        try await run(LightScript.source(for: state))
    }

    private func run(_ source: String) async throws -> LightState {
        try await withCheckedThrowingContinuation { continuation in
            Self.queue.async {
                continuation.resume(with: Result { try LightScript.execute(source) })
            }
        }
    }
}

enum LightScript {
    static let domain = "com.apple.CoreBrightness"
    static let key = "LEBacklightMode"

    /// The value Apple documents for "logo off". Deleting the key restores the default, lit.
    static let offValue = "0"

    private static let sudo = "/usr/bin/sudo -n"
    private static let defaults = "/usr/bin/defaults"

    /// The AppleScript for one operation; `nil` only reads. It always ends by reading the
    /// value back, so the app reports what macOS stored, not what it asked for.
    ///
    /// `sudo` matches Apple's commands exactly: it guarantees the preferences of the root
    /// user, whatever environment the admin shell starts with. It is tested first because
    /// a failed `defaults read` is otherwise indistinguishable from an unset key.
    static func source(for target: LightState?) -> String {
        var commands = ["\(sudo) /usr/bin/true || exit 1"]
        switch target {
        case .off:
            commands.append("\(sudo) \(defaults) write \(domain) \(key) -int \(offValue) || exit 1")
        case .on:
            // Deleting a key that is already gone fails harmlessly; the read below decides.
            commands.append("\(sudo) \(defaults) delete \(domain) \(key) 2>/dev/null")
        case nil:
            break
        }
        commands.append(#"if [ "$(\#(sudo) \#(defaults) read \#(domain) \#(key) 2>/dev/null)" = \#(offValue) ]; then echo off; else echo on; fi"#)

        let escaped = commands.joined(separator: "; ")
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let prompt = target == nil
            ? "Logo Light needs your password to check the logo light."
            : "Logo Light needs your password to change the logo light."
        return #"do shell script "\#(escaped)" with prompt "\#(prompt)" with administrator privileges"#
    }

    static func execute(_ source: String) throws -> LightState {
        guard let script = NSAppleScript(source: source) else {
            throw LightError.failed("The command could not be prepared.")
        }
        var info: NSDictionary?
        let result = script.executeAndReturnError(&info)
        if let info {
            if info[NSAppleScript.errorNumber] as? Int == -128 { throw LightError.cancelled }
            throw LightError.failed(info[NSAppleScript.errorMessage] as? String ?? "macOS refused the request.")
        }
        return try parse(result.stringValue ?? "")
    }

    static func parse(_ output: String) throws -> LightState {
        guard let state = LightState(rawValue: output.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw LightError.failed("Unexpected response: \(output)")
        }
        return state
    }
}
