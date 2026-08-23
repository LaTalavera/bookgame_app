import SwiftUI

/// Las cuatro escuadras de las esquinas del marco.
struct EsquinasOrnamentales: Shape {
    var brazo: CGFloat = 15
    var radio: CGFloat = 5

    func path(in rect: CGRect) -> Path {
        var p = Path()
        func esquina(_ x: CGFloat, _ y: CGFloat, _ dx: CGFloat, _ dy: CGFloat) {
            p.move(to: CGPoint(x: x, y: y + dy * (brazo + radio)))
            p.addLine(to: CGPoint(x: x, y: y + dy * radio))
            p.addQuadCurve(to: CGPoint(x: x + dx * radio, y: y),
                           control: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x + dx * (brazo + radio), y: y))
        }
        esquina(rect.minX, rect.minY,  1,  1)
        esquina(rect.maxX, rect.minY, -1,  1)
        esquina(rect.maxX, rect.maxY, -1, -1)
        esquina(rect.minX, rect.maxY,  1, -1)
        return p
    }
}

/// Los florones: una hojita en cada esquina, hacia dentro.
struct FloronesEsquina: Shape {
    var tamano: CGFloat = 9
    var margen: CGFloat = 7

    func path(in rect: CGRect) -> Path {
        var p = Path()
        func hoja(_ origen: CGPoint, _ dx: CGFloat, _ dy: CGFloat) {
            let fin = CGPoint(x: origen.x + dx * tamano, y: origen.y + dy * tamano)
            p.move(to: origen)
            p.addQuadCurve(to: fin, control: CGPoint(x: origen.x + dx * tamano, y: origen.y))
            p.addQuadCurve(to: origen, control: CGPoint(x: origen.x, y: origen.y + dy * tamano))
        }
        hoja(CGPoint(x: rect.minX + margen, y: rect.minY + margen),  1,  1)
        hoja(CGPoint(x: rect.maxX - margen, y: rect.minY + margen), -1,  1)
        hoja(CGPoint(x: rect.maxX - margen, y: rect.maxY - margen), -1, -1)
        hoja(CGPoint(x: rect.minX + margen, y: rect.maxY - margen),  1, -1)
        return p
    }
}

struct MarcoOrnamental: ViewModifier {
    var color: Color = .cyOro
    var opacidadLinea: Double = 0.55
    var conFlorones: Bool = true

    func body(content: Content) -> some View {
        content
            .overlay(Rectangle().stroke(color.opacity(opacidadLinea), lineWidth: 1))
            .overlay(EsquinasOrnamentales().stroke(color, lineWidth: 1.2))
            .overlay(
                Group {
                    if conFlorones {
                        FloronesEsquina().fill(color.opacity(0.5))
                    }
                }
            )
    }
}

extension View {
    func marcoOrnamental(color: Color = .cyOro,
                         opacidadLinea: Double = 0.55,
                         conFlorones: Bool = true) -> some View {
        modifier(MarcoOrnamental(color: color,
                                 opacidadLinea: opacidadLinea,
                                 conFlorones: conFlorones))
    }
}

/// Filete dorado con rombo al centro.
struct FileteOrnamental: View {
    var ancho: CGFloat = 56
    var color: Color = .cyOro

    var body: some View {
        HStack(spacing: 9) {
            LinearGradient(colors: [color.opacity(0), color],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: ancho, height: 1)
            Rectangle()
                .fill(color)
                .frame(width: 7, height: 7)
                .rotationEffect(.degrees(45))
            LinearGradient(colors: [color, color.opacity(0)],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: ancho, height: 1)
        }
        .frame(height: 11)
    }
}

/// Rótulo en versales espaciadas, el recurso tipográfico de la casa.
struct Versal: View {
    let texto: String
    var tamano: CGFloat = 10
    var color: Color = .cyOroOscuro
    var peso: Font.Weight = .semibold

    var body: some View {
        Text(texto.uppercased())
            .font(.cyDisplay(tamano, weight: peso))
            .tracking(tamano * 0.24)
            .foregroundStyle(color)
    }
}

/// Rombo relleno o hueco: el pip de habilidades y marcadores.
struct Rombo: View {
    var lleno: Bool
    var tamano: CGFloat = 11
    var color: Color = .cyGranate

    var body: some View {
        Rectangle()
            .fill(lleno ? color : Color.clear)
            .overlay(Rectangle().stroke(color.opacity(lleno ? 0 : 0.35), lineWidth: 1))
            .frame(width: tamano, height: tamano)
            .rotationEffect(.degrees(45))
    }
}

/// Barra de 0 a N en muescas, como en el prototipo.
struct MedidorSegmentado: View {
    let valor: Int
    let total: Int
    var color: Color = .cyVida
    var alto: CGFloat = 8

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<max(total, 1), id: \.self) { i in
                Rectangle()
                    .fill(i < valor ? color : color.opacity(0.09))
                    .overlay(Rectangle().stroke(color.opacity(i < valor ? 0 : 0.30), lineWidth: 1))
            }
        }
        .frame(height: alto)
    }
}
