import SwiftUI
import UIKit

enum CatalogoIlustraciones {
    struct Recurso: Decodable {
        let file: String
        let width: Int
        let height: Int
        let bookPlate: Bool
        var nombre: String { URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent }
        var proporcion: CGFloat { CGFloat(width) / CGFloat(height) }
    }

    private struct Manifiesto: Decodable {
        let assets: [String: Recurso]
        let sections: [String: String]
    }

    private static let manifiesto: Manifiesto = {
        let url = Bundle.main.url(forResource: "art-manifest", withExtension: "json", subdirectory: "Resources")
            ?? Bundle.main.url(forResource: "art-manifest", withExtension: "json")
        guard let url,
              let datos = try? Data(contentsOf: url),
              let valor = try? JSONDecoder().decode(Manifiesto.self, from: datos) else {
            return Manifiesto(assets: [:], sections: [:])
        }
        return valor
    }()

    static func recurso(para seccion: Int) -> Recurso? {
        guard let clave = manifiesto.sections[String(seccion)] else { return nil }
        return manifiesto.assets[clave]
    }

    static func imagen(para seccion: Int) -> UIImage? {
        guard let recurso = recurso(para: seccion) else { return nil }
        let url = Bundle.main.url(forResource: recurso.nombre, withExtension: "png", subdirectory: "Illustrations")
            ?? Bundle.main.url(forResource: recurso.nombre, withExtension: "png")
        guard let url else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func disponible(en seccion: Int) -> Bool { recurso(para: seccion) != nil }
}

struct LaminaReal: View {
    let seccion: Int
    let pie: String
    var altura: CGFloat = 260
    @State private var ampliada = false

    var body: some View {
        if let imagen = CatalogoIlustraciones.imagen(para: seccion),
           let recurso = CatalogoIlustraciones.recurso(para: seccion) {
            Button { ampliada = true } label: {
                VStack(spacing: 0) {
                    if altura <= 180 {
                        Image(uiImage: imagen)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: altura)
                            .clipped()
                    } else {
                        Image(uiImage: imagen)
                            .resizable()
                            .scaledToFit()
                            .aspectRatio(recurso.proporcion, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .background(Color.cyNoche)
                    }
                    Text(pie)
                        .font(.cyBody(11).italic())
                        .foregroundStyle(Color.cyTintaSuave)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.cyPergaminoCla)
                }
                .marcoOrnamental(opacidadLinea: 0.72)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ampliar ilustración: \(pie)")
            .fullScreenCover(isPresented: $ampliada) {
                VisorDeLamina(imagen: imagen, pie: pie)
            }
        }
    }
}

private struct VisorDeLamina: View {
    let imagen: UIImage
    let pie: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(uiImage: imagen)
                .resizable()
                .scaledToFit()
                .padding(.vertical, 54)
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(18)
                    }
                }
                Spacer()
                Text(pie)
                    .font(.cyBody(13).italic())
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
    }
}
