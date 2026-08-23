import SwiftUI
import CoreGraphics

/// Grano de papel: una textura de ruido de 96×96 generada una sola vez
/// y repetida en mosaico.
struct Grano: View {
    static let textura: Image = {
        let lado = 96
        let bytesPorFila = lado * 4
        var bytes = Data(count: bytesPorFila * lado)
        bytes.withUnsafeMutableBytes { raw in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return }
            var semilla: UInt64 = 147
            for i in stride(from: 0, to: bytesPorFila * lado, by: 4) {
                semilla = semilla &* 6364136223846793005 &+ 1442695040888963407
                let v = UInt8(118 + ((semilla >> 33) % 138))
                base[i] = v
                base[i + 1] = v
                base[i + 2] = v
                base[i + 3] = 255
            }
        }
        guard let provider = CGDataProvider(data: bytes as CFData),
              let cg = CGImage(width: lado, height: lado,
                               bitsPerComponent: 8, bitsPerPixel: 32,
                               bytesPerRow: bytesPorFila,
                               space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                               provider: provider, decode: nil,
                               shouldInterpolate: false, intent: .defaultIntent)
        else {
            return Image(systemName: "square")
        }
        return Image(decorative: cg, scale: 1)
    }()

    var body: some View {
        Grano.textura
            .resizable(resizingMode: .tile)
            .allowsHitTesting(false)
    }
}

/// El fondo de pergamino envejecido de todas las pantallas claras.
struct Pergamino: View {
    var body: some View {
        ZStack {
            Color.cyPergamino
            RadialGradient(colors: [Color.white.opacity(0.48), .clear],
                           center: UnitPoint(x: 0.14, y: 0.03),
                           startRadius: 0, endRadius: 620)
            RadialGradient(colors: [Color(red: 0.47, green: 0.34, blue: 0.17).opacity(0.24), .clear],
                           center: UnitPoint(x: 0.9, y: 0.97),
                           startRadius: 0, endRadius: 560)
            Grano().blendMode(.multiply).opacity(0.055)
        }
        .ignoresSafeArea()
    }
}

/// El fondo chamuscado de los finales.
struct Ceniza: View {
    var body: some View {
        ZStack {
            Color.cyNoche
            RadialGradient(colors: [Color.cyGranate.opacity(0.46), .clear],
                           center: UnitPoint(x: 0.5, y: 0.10),
                           startRadius: 0, endRadius: 620)
            RadialGradient(colors: [Color.cyOro.opacity(0.13), .clear],
                           center: UnitPoint(x: 0.08, y: 0.98),
                           startRadius: 0, endRadius: 460)
            RadialGradient(colors: [.clear, Color.black.opacity(0.85)],
                           center: .center, startRadius: 240, endRadius: 720)
            Grano().blendMode(.overlay).opacity(0.16)
        }
        .ignoresSafeArea()
    }
}
