import AppKit
import SwiftUI

@main
struct LogoLightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = LogoLightModel(backend: Self.makeBackend())

    private static func makeBackend() -> LightBackend {
        #if PREVIEW
        PreviewBackend()
        #else
        AdminLightBackend()
        #endif
    }

    var body: some Scene {
        Window("Logo Light", id: "main") {
            ContentView()
                .environmentObject(model)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Light") {
                Button(toggleTitle) { model.primaryAction() }
                    .keyboardShortcut("l")
                    .disabled(model.isBusy)
                Button("Check Status") { model.refresh() }
                    .keyboardShortcut("r")
                    .disabled(model.isBusy)
            }
        }
    }

    private var toggleTitle: String {
        switch model.state {
        case .on: "Turn Light Off"
        case .off: "Turn Light On"
        case nil: "Check Light"
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

/// The window is part of the dark scene: black behind the title bar, dragged from anywhere.
struct WindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.backgroundColor = .black
            window.isMovableByWindowBackground = true
            window.appearance = NSAppearance(named: .darkAqua)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
