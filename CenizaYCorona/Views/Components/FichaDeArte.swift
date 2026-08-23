import SwiftUI

/// El glifo de lámina: marco, horizonte y sol. Marca "aquí va una ilustración"
/// sin caer en el icono de imagen rota.
struct GlifoLamina: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRect(CGRect(x: rect.minX + w * 0.13, y: rect.minY + h * 0.19,
                         width: w * 0.74, height: h * 0.62))
        p.move(to: CGPoint(x: rect.minX + w * 0.13, y: rect.minY + h * 0.67))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.35, y: rect.minY + h * 0.44))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.51, y: rect.minY + h * 0.59))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.63, y: rect.minY + h * 0.48))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.87, y: rect.minY + h * 0.70))
        p.addEllipse(in: CGRect(x: rect.minX + w * 0.60, y: rect.minY + h * 0.27,
                                width: w * 0.13, height: h * 0.13))
        return p
    }
}

/// Las ilustraciones todavía no existen: esto presenta el brief como lámina
/// enmarcada, nunca como hueco vacío.
struct FichaDeArte: View {
    let sectionID: Int
    let illustration: Illustration
    var horizontal: Bool = false

    var body: some View {
        Group {
            if CatalogoIlustraciones.disponible(en: sectionID) {
                LaminaReal(seccion: sectionID, pie: illustration.caption,
                           altura: horizontal ? 320 : 260)
            } else if horizontal {
                HStack(alignment: .center, spacing: 16) {
                    glifo(lado: 76)
                        .frame(width: 76, height: 76)
                        .background(Color.cyPergaminoCla.opacity(0.35))
                        .overlay(Rectangle().stroke(Color.cyOro.opacity(0.5), lineWidth: 1))
                    VStack(alignment: .leading, spacing: 5) {
                        Versal(texto: "Ficha de arte", tamano: 8)
                        Text(illustration.caption)
                            .font(.cyDisplay(13.5, weight: .regular))
                            .tracking(0.8)
                            .foregroundStyle(Color.cyGranate)
                        Text(illustration.brief)
                            .font(.cyBody(13).italic())
                            .foregroundStyle(Color.cyTintaSuave)
                            .lineSpacing(2.5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Rectangle().fill(Color.cyOro.opacity(0.45)).frame(height: 1)
                        Versal(texto: "Ficha de arte", tamano: 8)
                        Rectangle().fill(Color.cyOro.opacity(0.45)).frame(height: 1)
                    }
                    glifo(lado: 34).frame(width: 34, height: 34)
                    Text(illustration.caption)
                        .font(.cyDisplay(12.5, weight: .regular))
                        .tracking(1)
                        .foregroundStyle(Color.cyGranate)
                        .multilineTextAlignment(.center)
                    Text(illustration.brief)
                        .font(.cyBody(12.5).italic())
                        .foregroundStyle(Color.cyTintaSuave)
                        .lineSpacing(2.5)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, horizontal ? 18 : 15)
        .padding(.vertical, horizontal ? 16 : 13)
        .background(Color.cyPergaminoOsc.opacity(0.45))
        .marcoOrnamental(opacidadLinea: 0.6)
    }

    private func glifo(lado: CGFloat) -> some View {
        GlifoLamina().stroke(Color.cyOro, lineWidth: 1.1).opacity(0.85)
    }
}
