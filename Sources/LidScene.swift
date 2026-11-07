import SwiftUI

/// A closed-off dark room: a laptop lid standing on rumpled bedding, lit only by its logo.
/// `glow` runs from 0 (dark) to 1 (fully lit) and every light source follows it.
struct LidScene: View {
    let glow: Double
    let isHovering: Bool

    static let size = CGSize(width: 520, height: 580)
    static let captionTop: CGFloat = 482

    /// SwiftUI adds this to the window's height, on top of the content's own frame.
    static let titleBarHeight: CGFloat = 32

    private static let lid = CGRect(x: 90, y: 118, width: 340, height: 236)
    private static let cornerRadius: CGFloat = 13
    private static let logoSize: CGFloat = 62
    private static let fabric = CGRect(x: 0, y: 310, width: 520, height: 170)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black
            wall
            bedding
            baseLight
            lid
            logo
            Image(decorative: Texture.grain, scale: 2)
                .resizable(resizingMode: .tile)
                .blendMode(.plusLighter)
                .opacity(0.035)
                .allowsHitTesting(false)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }

    /// The faint room behind the lid; the light barely reaches it.
    private var wall: some View {
        RadialGradient(
            colors: [.white.opacity(0.018 + 0.03 * glow), .clear],
            center: UnitPoint(x: 0.5, y: 0.4),
            startRadius: 0,
            endRadius: 300
        )
    }

    private var bedding: some View {
        let fabric = Image(decorative: Texture.fabric, scale: 2)
            .resizable()
            .frame(width: Self.fabric.width, height: Self.fabric.height)

        return ZStack {
            // Just enough ambient light to see the bed in the dark.
            fabric
                .opacity(0.07)
                .mask(fade(radiusFraction: 0.72))
            fabric
                .opacity(glow)
                .mask(fade(radiusFraction: 0.58))
        }
        // The bed recedes into the dark behind the lid.
        .mask(LinearGradient(colors: [.clear, .white], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.26)))
        .offset(x: Self.fabric.minX, y: Self.fabric.minY)
    }

    private func fade(radiusFraction: CGFloat) -> some View {
        EllipticalGradient(
            stops: [
                .init(color: .white, location: 0),
                .init(color: .white.opacity(0.55), location: 0.42),
                .init(color: .clear, location: 1),
            ],
            center: UnitPoint(x: 0.5, y: 0.32),
            startRadiusFraction: 0,
            endRadiusFraction: radiusFraction
        )
    }

    /// The bright seam where the lit lid meets the bed.
    private var baseLight: some View {
        EllipticalGradient(
            colors: [.white.opacity(0.62 * glow), .white.opacity(0.2 * glow), .clear],
            center: .center,
            startRadiusFraction: 0,
            endRadiusFraction: 0.5
        )
        .frame(width: Self.lid.width + 90, height: 46)
        .offset(x: Self.lid.minX - 45, y: Self.lid.maxY - 19)
    }

    private var lid: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)

        return shape
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.052), Color(white: 0.033)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                // The light pools at the bottom of the lid, below the logo.
                RadialGradient(
                    colors: [.white.opacity(0.27 * glow), .white.opacity(0.08 * glow), .clear],
                    center: UnitPoint(x: 0.5, y: 0.93),
                    startRadius: 0,
                    endRadius: 188
                )
                .clipShape(shape)
            }
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.1), .white.opacity(0.015)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
            }
            .frame(width: Self.lid.width, height: Self.lid.height)
            .offset(x: Self.lid.minX, y: Self.lid.minY)
    }

    private var logo: some View {
        let glyph = Image(systemName: "apple.logo")
            .font(.system(size: Self.logoSize, weight: .regular))
        let hoverLift = isHovering ? 0.1 : 0.0

        return ZStack {
            RadialGradient(
                colors: [.white.opacity(0.2 * glow), .white.opacity(0.06 * glow), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 112
            )
            glyph.foregroundStyle(.white).blur(radius: 14).opacity(0.8 * glow)
            glyph.foregroundStyle(.white).blur(radius: 5).opacity(0.7 * glow)
            // Unlit, the logo is a shape slightly lighter than the lid.
            glyph.foregroundStyle(.white.opacity(0.07 + hoverLift))
            glyph.foregroundStyle(.white).opacity(glow)
        }
        .frame(width: Self.lid.width, height: Self.lid.height)
        .offset(x: Self.lid.minX, y: Self.lid.minY)
    }
}
