import SwiftUI

/// El botón granate con filo dorado y florones.
struct BotonPrimario: View {
    let titulo: String
    var subtitulo: String? = nil
    var alto: CGFloat = 54
    var habilitado: Bool = true
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            VStack(spacing: 2) {
                Text(titulo.uppercased())
                    .font(.cyDisplay(13.5, weight: .bold))
                    .tracking(2.8)
                    .foregroundStyle(Color.cyOroClaro)
                if let subtitulo {
                    Text(subtitulo)
                        .font(.cyBody(11).italic())
                        .foregroundStyle(Color.cyOroClaro.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: alto)
            .background(
                LinearGradient(colors: [Color.cyGranate, Color.cyGranateOsc],
                               startPoint: .top, endPoint: .bottom)
            )
            .marcoOrnamental(color: .cyOro, opacidadLinea: 1)
        }
        .buttonStyle(.plain)
        .disabled(!habilitado)
        .opacity(habilitado ? 1 : 0.45)
    }
}

/// El botón de contorno, para acciones secundarias.
struct BotonSecundario: View {
    let titulo: String
    var alto: CGFloat = 48
    var punteado: Bool = false
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Text(titulo.uppercased())
                .font(.cyDisplay(10.5, weight: .semibold))
                .tracking(1.7)
                .foregroundStyle(punteado ? Color.cyTintaTenue : Color.cyGranate)
                .frame(maxWidth: .infinity)
                .frame(minHeight: alto)
                .background(punteado
                            ? Color.cyPergaminoOsc.opacity(0.2)
                            : Color.cyPergaminoCla.opacity(0.55))
                .overlay(
                    Rectangle().stroke(
                        punteado ? Color.cyApagado.opacity(0.65) : Color.cyOro.opacity(0.7),
                        style: StrokeStyle(lineWidth: 1, dash: punteado ? [4, 3] : [])
                    )
                )
        }
        .buttonStyle(.plain)
    }
}

/// Una elección de la sección. Muestra el requisito, el flag que concede y
/// el número de sección de destino.
struct FilaDeEleccion: View {
    let choice: Choice
    let disponible: Bool
    var unicaOpcion: Bool = false
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(alignment: .center, spacing: 11) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(choice.etiqueta(unicaOpcion: unicaOpcion))
                        .font(.cyBody(15.5))
                        .italic(choice.esTransito)
                        .foregroundStyle(disponible ? Color.cyTinta : Color.cyApagado)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let requiere = choice.requires {
                        HStack(spacing: 5) {
                            Image(systemName: disponible ? "key" : "link")
                                .font(.system(size: 10, weight: .regular))
                            Text(disponible
                                 ? "\(legible(requiere)) · la tienes"
                                 : "Requiere \(legible(requiere))")
                                .font(.cyBody(10.5))
                                .tracking(0.6)
                        }
                        .foregroundStyle(disponible ? Color.cyOroOscuro : Color.cyApagado)
                    } else if let concede = choice.setsFlag {
                        HStack(spacing: 5) {
                            Rombo(lleno: true, tamano: 5, color: coloreDe(concede))
                            Text(legible(concede))
                                .font(.cyBody(10.5))
                                .tracking(0.6)
                                .foregroundStyle(coloreDe(concede))
                        }
                    }
                }
                Spacer(minLength: 4)
                Text("§\(choice.target)")
                    .font(.cyDisplay(11, weight: .regular))
                    .foregroundStyle(disponible ? Color.cyOroOscuro : Color.cyApagado)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .frame(minHeight: 54)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(disponible
                        ? Color.cyPergaminoCla.opacity(0.66)
                        : Color.cyPergaminoOsc.opacity(0.22))
            .overlay(alignment: .leading) {
                if disponible {
                    Rectangle().fill(Color.cyGranate).frame(width: 3)
                }
            }
            .overlay(
                Rectangle().stroke(
                    disponible ? Color.cyOro.opacity(0.6) : Color.cyApagado.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1, dash: disponible ? [] : [4, 3])
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(!disponible)
    }

    private func legible(_ flag: String) -> String {
        flag.replacingOccurrences(of: "_", with: " ")
    }

    private func coloreDe(_ flag: String) -> Color {
        ParchesDeDatos.flagsHuerfanos.contains(flag) ? .cyCorrupcion : .cyOroOscuro
    }
}

/// La cara de un dado de seis, en pergamino con puntos granate.
struct CaraDeDado: View {
    let valor: Int
    var lado: CGFloat = 78

    private static let caras: [Int: Set<Int>] = [
        1: [4], 2: [0, 8], 3: [0, 4, 8],
        4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8]
    ]

    var body: some View {
        let encendidos = CaraDeDado.caras[valor] ?? [4]
        VStack(spacing: lado * 0.05) {
            ForEach(0..<3, id: \.self) { fila in
                HStack(spacing: lado * 0.05) {
                    ForEach(0..<3, id: \.self) { col in
                        Circle()
                            .fill(Color.cyGranate)
                            .opacity(encendidos.contains(fila * 3 + col) ? 1 : 0)
                            .frame(width: lado * 0.14, height: lado * 0.14)
                    }
                }
            }
        }
        .padding(lado * 0.16)
        .frame(width: lado, height: lado)
        .background(
            LinearGradient(colors: [Color.cyPergaminoCla, Color.cyPergaminoOsc],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(Rectangle().stroke(Color.cyOro, lineWidth: 1.5))
        .shadow(color: Color.black.opacity(0.26), radius: 8, x: 0, y: 5)
    }
}

/// La escala Fácil / Media / Difícil / Heroica, con el peldaño en juego marcado.
struct EscalaDificultad: View {
    let activa: Dificultad

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Dificultad.allCases) { paso in
                VStack(spacing: 2) {
                    Versal(texto: paso.nombre, tamano: 7.5,
                           color: paso == activa ? .cyGranate : .cyOroOscuro)
                    Text("\(paso.rawValue)")
                        .font(.cyDisplay(14, weight: paso == activa ? .bold : .regular))
                        .foregroundStyle(paso == activa ? Color.cyGranate : Color.cyTintaTenue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(paso == activa
                            ? Color.cyGranate.opacity(0.10)
                            : Color.cyPergaminoCla.opacity(0.35))
                .overlay(Rectangle().stroke(
                    paso == activa ? Color.cyOro : Color.cyOro.opacity(0.35), lineWidth: 1))
            }
        }
    }
}

/// La barra de estado que corona lectura y combate.
struct BarraDeEstado: View {
    let state: GameState

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                MedidorContinuo(titulo: "Vida", valor: state.vida,
                                total: state.vidaMaxima, color: .cyVida, alto: 7)
                if state.ecosMaximos > 0 {
                    MedidorContinuo(titulo: "Ecos", valor: state.ecos,
                                    total: state.ecosMaximos, color: .cyOroOscuro, alto: 7)
                        .frame(maxWidth: 90)
                }
                MedidorDeCorrupcion(valor: state.corrupcion, alto: 7)
            }

            if state.corrupcion >= 7 {
                HStack(spacing: 7) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 11))
                    Text(EstadoDeCorrupcion.para(state.corrupcion).titulo + ". La ceniza te llama por tu nombre.")
                        .font(.cyBody(11.5).italic())
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Color.cyCorrupcion)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.cyCorrupcion.opacity(0.12))
                .overlay(alignment: .leading) {
                    Rectangle().fill(Color.cyCorrupcion).frame(width: 2)
                }
            }

            let visibles = state.marcadoresActivos.filter { state.rep($0) != 0 }
            if !visibles.isEmpty {
                HStack(spacing: 7) {
                    ForEach(visibles.prefix(3)) { track in
                        ChipReputacion(track: track, valor: state.rep(track))
                    }
                    Spacer(minLength: 0)
                    if visibles.count > 3 {
                        Text("+\(visibles.count - 3)")
                            .font(.cyBody(10.5).italic())
                            .foregroundStyle(Color.cyOroOscuro)
                    }
                }
            }
        }
    }
}
