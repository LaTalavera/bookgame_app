import SwiftUI

/// Un recurso con rótulo, cuenta y barra continua (Vida y Ecos usan valores
/// altos, así que no van en muescas).
struct MedidorContinuo: View {
    let titulo: String
    let valor: Int
    let total: Int
    let color: Color
    var alto: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Versal(texto: titulo, tamano: 8.5, color: color)
                Spacer(minLength: 6)
                Text("\(valor)/\(total)")
                    .font(.cyBody(11))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(color.opacity(0.10))
                    Rectangle().fill(color)
                        .frame(width: geo.size.width * proporcion)
                }
            }
            .frame(height: alto)
            .overlay(Rectangle().stroke(color.opacity(0.32), lineWidth: 1))
            .animation(.easeOut(duration: 0.3), value: valor)
        }
    }

    private var proporcion: CGFloat {
        guard total > 0 else { return 0 }
        return max(0, min(1, CGFloat(valor) / CGFloat(total)))
    }
}

/// La Corrupción sí va de 0 a 10 en muescas.
struct MedidorDeCorrupcion: View {
    let valor: Int
    var alto: CGFloat = 8
    var conNota: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Versal(texto: "Corrupción", tamano: 8.5, color: .cyCorrupcion)
                Spacer(minLength: 6)
                Text("\(valor)/\(Reglas.corrupcionMaxima)")
                    .font(.cyBody(11))
                    .foregroundStyle(Color.cyCorrupcion)
            }
            MedidorSegmentado(valor: valor, total: Reglas.corrupcionMaxima,
                              color: .cyCorrupcion, alto: alto)
            if conNota {
                let estado = EstadoDeCorrupcion.para(valor)
                Text(estado.detalle)
                    .font(.cyBody(11).italic())
                    .foregroundStyle(valor >= 7 ? Color.cyCorrupcion : Color.cyTintaSuave)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Marcador de reputación en chip discreto, escala -5 a +5.
struct ChipReputacion: View {
    let track: RepTrack
    let valor: Int

    var body: some View {
        HStack(spacing: 6) {
            Versal(texto: track.nombreCorto, tamano: 8, color: .cyGranate)
            Text(valor > 0 ? "+\(valor)" : "\(valor)")
                .font(.cyDisplay(11, weight: .semibold))
                .foregroundStyle(valor < 0 ? Color.cyCorrupcion : Color.cyGranate)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.cyPergaminoCla.opacity(0.5))
        .overlay(Rectangle().stroke(Color.cyOro.opacity(0.55), lineWidth: 1))
    }
}

/// Fila de marcador con barra centrada en 0, para la hoja de personaje.
struct FilaReputacion: View {
    let track: RepTrack
    let valor: Int
    var anchoEtiqueta: CGFloat = 138

    var body: some View {
        HStack(spacing: 10) {
            Text(track.nombre)
                .font(.cyDisplay(11.5, weight: .regular))
                .foregroundStyle(Color.cyTinta)
                .frame(width: anchoEtiqueta, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if track == .vinculo {
                MedidorSegmentado(valor: max(0, valor), total: 10, color: .cyGranate, alto: 8)
            } else {
                escalaCentrada
            }

            Text(valor > 0 ? "+\(valor)" : "\(valor)")
                .font(.cyBody(11.5))
                .foregroundStyle(valor < 0 ? Color.cyCorrupcion : Color.cyGranate)
                .frame(width: 26, alignment: .trailing)
        }
        .opacity(valor == 0 ? 0.5 : 1)
    }

    /// Diez casillas: cinco a la izquierda del cero y cinco a la derecha.
    private var escalaCentrada: some View {
        HStack(spacing: 2) {
            ForEach(Array(stride(from: RepTrack.minimo, through: -1, by: 1)), id: \.self) { paso in
                Rectangle()
                    .fill(valor <= paso ? Color.cyCorrupcion : Color.cyCorrupcion.opacity(0.08))
                    .overlay(Rectangle().stroke(Color.cyCorrupcion.opacity(valor <= paso ? 0 : 0.28), lineWidth: 1))
            }
            Rectangle().fill(Color.cyOro).frame(width: 1)
            ForEach(Array(stride(from: 1, through: RepTrack.maximo, by: 1)), id: \.self) { paso in
                Rectangle()
                    .fill(valor >= paso ? Color.cyGranate : Color.cyGranate.opacity(0.08))
                    .overlay(Rectangle().stroke(Color.cyGranate.opacity(valor >= paso ? 0 : 0.28), lineWidth: 1))
            }
        }
        .frame(height: 8)
    }
}

/// Fila de atributo: sigla, valor y su nombre largo.
struct FilaAtributo: View {
    let atributo: Atributo
    let valor: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(atributo.sigla)
                .font(.cyDisplay(13, weight: .semibold))
                .foregroundStyle(Color.cyGranate)
                .frame(width: 34, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(atributo.nombre)
                    .font(.cyDisplay(12.5, weight: .regular))
                    .foregroundStyle(Color.cyTinta)
                Text(atributo.descripcion)
                    .font(.cyBody(10.5).italic())
                    .foregroundStyle(Color.cyTintaTenue)
            }
            Spacer(minLength: 0)
            Text("\(valor)")
                .font(.cyDisplay(19, weight: .semibold))
                .foregroundStyle(Color.cyGranate)
        }
    }
}
