import CoreGraphics
import Foundation

/// Procedural textures, drawn once so that no artwork ships with the app.
enum Texture {
    /// Rumpled cloth, shaded as if lit from the lid's side (the top of the image).
    static let fabric: CGImage = {
        let width = 1040, height = 340
        var pixels = [UInt8](repeating: 0, count: width * height)
        // A wide sampling step softens the folds, like cloth just out of focus.
        let step = 4.0
        for y in 0..<height {
            for x in 0..<width {
                let (px, py) = (Double(x), Double(y))
                let slope = (surface(px, py - step) - surface(px, py + step)) / (2 * step)
                let shade = 0.5 + slope * 0.62
                pixels[y * width + x] = UInt8(max(0, min(1, shade)) * 205)
            }
        }
        return image(&pixels, width: width, height: height)
    }()

    static let grain: CGImage = {
        let side = 256
        var generator = SeededGenerator(state: 0x5EED)
        var pixels = (0..<side * side).map { _ in UInt8.random(in: 0...255, using: &generator) }
        return image(&pixels, width: side, height: side)
    }()

    /// Folds run mostly sideways, bent by a slow warp so that no two look alike.
    private static func surface(_ x: Double, _ y: Double) -> Double {
        let warp = fractal(x * 0.0045 + 3.1, y * 0.0065 + 7.7, octaves: 2) * 75
        let folds = fractal((x + warp) * 0.0042, (y - warp * 0.5) * 0.0165, octaves: 3)
        let creases = 1 - abs(2 * fractal(x * 0.008 + 11, (y + warp) * 0.03 + 5, octaves: 2) - 1)
        return folds * 30 + creases * creases * 6
    }

    private static func fractal(_ x: Double, _ y: Double, octaves: Int) -> Double {
        var total = 0.0, amplitude = 0.5, frequency = 1.0, range = 0.0
        for _ in 0..<octaves {
            total += noise(x * frequency, y * frequency) * amplitude
            range += amplitude
            amplitude *= 0.5
            frequency *= 2.03
        }
        return total / range
    }

    private static func noise(_ x: Double, _ y: Double) -> Double {
        let (x0, y0) = (floor(x), floor(y))
        let (u, v) = (smooth(x - x0), smooth(y - y0))
        let top = mix(lattice(x0, y0), lattice(x0 + 1, y0), u)
        let bottom = mix(lattice(x0, y0 + 1), lattice(x0 + 1, y0 + 1), u)
        return mix(top, bottom, v)
    }

    private static func lattice(_ x: Double, _ y: Double) -> Double {
        let value = sin(x * 127.1 + y * 311.7) * 43758.5453
        return value - floor(value)
    }

    private static func smooth(_ t: Double) -> Double { t * t * t * (t * (t * 6 - 15) + 10) }
    private static func mix(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

    private static func image(_ pixels: inout [UInt8], width: Int, height: Int) -> CGImage {
        pixels.withUnsafeMutableBytes { buffer in
            CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            )!.makeImage()!
        }
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
