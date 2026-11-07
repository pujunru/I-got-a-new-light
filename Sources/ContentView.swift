import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: LogoLightModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false

    /// How brightly the scene is lit. An unknown state stays dim instead of implying an answer.
    private var glow: Double {
        switch model.state {
        case .on: 1
        case .off: 0
        case nil: 0.28
        }
    }

    private var title: String {
        if model.isBusy { return "Waiting for macOS" }
        switch model.state {
        case .on: return "Logo light on"
        case .off: return "Logo light off"
        case nil: return "Logo light status unknown"
        }
    }

    private var caption: String {
        if let message = model.errorMessage { return message }
        if model.isBusy { return "Enter your password if prompted" }
        switch model.state {
        case .on: return "Click the logo to turn it off"
        case .off: return "Click the logo to turn it on"
        case nil: return "Click the logo to check. macOS will ask for your password."
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Button(action: model.primaryAction) {
                LidScene(glow: glow, isHovering: isHovering && !model.isBusy)
            }
            .buttonStyle(LidButtonStyle())
            .disabled(model.isBusy)
            .keyboardShortcut(.space, modifiers: [])
            .onHover { isHovering = $0 }
            .accessibilityLabel("Logo light")
            .accessibilityValue(title)
            .accessibilityHint(caption)

            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.86))
                Text(caption)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(model.errorMessage == nil ? 0.42 : 0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 32)
            .frame(width: LidScene.size.width)
            .offset(y: LidScene.captionTop)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .frame(width: LidScene.size.width, height: LidScene.size.height)
        .frame(width: LidScene.size.width, height: LidScene.size.height - LidScene.titleBarHeight, alignment: .top)
        .background(.black)
        .background(WindowChrome())
        .ignoresSafeArea()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.9), value: glow)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isHovering)
        .preferredColorScheme(.dark)
        #if PREVIEW
        .onAppear { PreviewHooks.run(model: model) }
        #endif
    }
}

/// The scene supplies its own hover and lit states, so pressing only needs a slight dip.
private struct LidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.82 : 1)
            .contentShape(Rectangle())
    }
}
