import Foundation
import SwiftUI

@MainActor
final class LogoLightModel: ObservableObject {
    /// Last state confirmed by macOS; `nil` until the first check.
    @Published private(set) var state: LightState?
    @Published private(set) var isBusy = false
    @Published private(set) var errorMessage: String?

    private let backend: LightBackend
    private let store: UserDefaults
    private static let storeKey = "lastConfirmedState"

    init(backend: LightBackend, store: UserDefaults = .standard) {
        self.backend = backend
        self.store = store
        state = store.string(forKey: Self.storeKey).flatMap(LightState.init(rawValue:))
    }

    /// Clicking the logo flips the light, or checks it when the state isn't known yet.
    func primaryAction() {
        switch state {
        case .on: apply(.off)
        case .off: apply(.on)
        case nil: refresh()
        }
    }

    func refresh() {
        perform { [backend] in try await backend.read() }
    }

    private func apply(_ target: LightState) {
        perform(expecting: target) { [backend] in try await backend.set(target) }
    }

    private func perform(expecting target: LightState? = nil, _ operation: @escaping () async throws -> LightState) {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        Task {
            defer { isBusy = false }
            do {
                let confirmed = try await operation()
                state = confirmed
                store.set(confirmed.rawValue, forKey: Self.storeKey)
                if let target, target != confirmed {
                    errorMessage = "macOS kept the light \(confirmed.rawValue)."
                }
            } catch LightError.cancelled {
                // Dismissing the password prompt changes nothing and needs no message.
            } catch LightError.failed(let message) {
                errorMessage = message
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
