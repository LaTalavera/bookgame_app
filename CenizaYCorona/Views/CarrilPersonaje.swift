import SwiftUI

/// El panel de personaje fijo del iPad.
struct CarrilPersonaje: View {
    let state: GameState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 13) {
                    Medallon(inicial: inicial, lado: 60)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(state.nombre)
                            .font(.cyDisplay(15, weight: .semibold))
                            .foregroundStyle(Color.cyGranate)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(state.vocacion.nombre)
                            .font(.cyBody(11.5).italic())
                            .foregroundStyle(Color.cyTintaSuave)
                    }
                }

                HStack(spacing: 0) {
                    ForEach(Atributo.allCases) { atributo in
                        VStack(spacing: 3) {
                            Versal(texto: atributo.sigla, tamano: 8)
                            Text("\(state.atributo(atributo))")
                                .font(.cyDisplay(18, weight: .semibold))
                                .foregroundStyle(Color.cyGranate)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 3) {
                        Versal(texto: "Def", tamano: 8)
                        Text("\(state.defensa)")
                            .font(.cyDisplay(18, weight: .semibold))
                            .foregroundStyle(Color.cyGranate)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 11)
                .background(Color.cyPergaminoCla.opacity(0.35))
                .overlay(Rectangle().stroke(Color.cyOro.opacity(0.4), lineWidth: 1))
                .padding(.top, 18)

                VStack(spacing: 11) {
                    MedidorContinuo(titulo: "Vida", valor: state.vida,
                                    total: state.vidaMaxima, color: .cyVida)
                    if state.ecosMaximos > 0 {
                        MedidorContinuo(titulo: "Ecos", valor: state.ecos,
                                        total: state.ecosMaximos, color: .cyOroOscuro)
                    }
                    MedidorDeCorrupcion(valor: state.corrupcion)
                }
                .padding(.top, 18)

                bloque("Reputación") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(state.marcadoresActivos) { track in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(track.nombre)
                                        .font(.cyDisplay(10.5, weight: .regular))
                                        .foregroundStyle(Color.cyTinta)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer(minLength: 0)
                                    Text(state.rep(track) > 0 ? "+\(state.rep(track))" : "\(state.rep(track))")
                                        .font(.cyBody(10.5))
                                        .foregroundStyle(state.rep(track) < 0 ? Color.cyCorrupcion : Color.cyGranate)
                                }
                                MedidorSegmentado(valor: max(0, state.rep(track)),
                                                  total: track == .vinculo ? 10 : RepTrack.maximo,
                                                  color: .cyGranate, alto: 7)
                            }
                            .opacity(state.rep(track) == 0 ? 0.5 : 1)
                        }
                        if !dormidos.isEmpty {
                            Text("\(dormidos.map(\.nombre).joined(separator: " y ")) no entran en juego aquí.")
                                .font(.cyBody(10.5).italic())
                                .foregroundStyle(Color.cyTintaTenue)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                bloque("Equipo") {
                    VStack(alignment: .leading, spacing: 5) {
                        lineaDeEquipo(state.arma.nombre, "Daño \(state.arma.dano)")
                        if let secundaria = state.armaSecundaria {
                            lineaDeEquipo(secundaria.nombre,
                                          secundaria.dano > 0 ? "Daño \(secundaria.dano)" : "foco")
                        }
                        lineaDeEquipo(state.armadura.nombre, "+\(state.armadura.bonoDefensa) Def")
                        if state.llevaEscudo { lineaDeEquipo("Escudo", "+1 Def") }
                    }
                }

                bloque("Palabras clave") {
                    if state.flags.isEmpty {
                        Text("Todavía ninguna.")
                            .font(.cyBody(11).italic())
                            .foregroundStyle(Color.cyTintaTenue)
                    } else {
                        NubeDeFlags(flags: state.flags.sorted(), tamano: 9)
                    }
                }

                tablaDeDados.padding(.top, 22).padding(.bottom, 26)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 26)
        }
        .scrollIndicators(.hidden)
        .background(Color.cyPergaminoOsc.opacity(0.34))
    }

    private var inicial: String { String(state.nombre.prefix(1)).uppercased() }

    private var dormidos: [RepTrack] {
        RepTrack.allCases.filter { !state.marcadoresActivos.contains($0) }
    }

    private func lineaDeEquipo(_ nombre: String, _ valor: String) -> some View {
        HStack {
            Text(nombre)
                .font(.cyBody(11.5))
                .foregroundStyle(Color.cyTinta)
            Spacer(minLength: 6)
            Text(valor)
                .font(.cyBody(11))
                .foregroundStyle(Color.cyOroOscuro)
        }
    }

    private func bloque<C: View>(_ titulo: String, @ViewBuilder contenido: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Versal(texto: titulo, tamano: 8.5)
                Rectangle().fill(Color.cyOro.opacity(0.4)).frame(height: 1)
            }
            contenido()
        }
        .padding(.top, 24)
    }

    private var tablaDeDados: some View {
        VStack(spacing: 9) {
            Versal(texto: "Pruebas 2D6 + atributo", tamano: 8)
            VStack(spacing: 5) {
                ForEach(Dificultad.allCases) { paso in
                    HStack {
                        Text(paso.nombre)
                            .font(.cyBody(11))
                            .foregroundStyle(Color.cyTintaSuave)
                        Spacer(minLength: 0)
                        Text("\(paso.objetivo)+")
                            .font(.cyDisplay(11, weight: .regular))
                            .foregroundStyle(Color.cyGranate)
                    }
                }
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(Color.cyPergaminoCla.opacity(0.42))
        .marcoOrnamental(opacidadLinea: 0.5)
    }
}

/// El medallón con la inicial del personaje.
struct Medallon: View {
    let inicial: String
    var lado: CGFloat = 76

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color.cyGranateCla, Color.cyGranateOsc],
                                     center: UnitPoint(x: 0.32, y: 0.28),
                                     startRadius: 2, endRadius: lado))
            Circle().stroke(Color.cyOro, lineWidth: 1.5)
            Text(inicial)
                .font(.cyDisplay(lado * 0.41, weight: .semibold))
                .foregroundStyle(Color.cyOroClaro)
        }
        .frame(width: lado, height: lado)
    }
}

/// Las palabras clave en fichas, envueltas en varias líneas.
struct NubeDeFlags: View {
    let flags: [String]
    var tamano: CGFloat = 9.5

    var body: some View {
        FlujoHorizontal(espaciado: 6, espaciadoLinea: 6) {
            ForEach(flags, id: \.self) { flag in
                Text(flag.replacingOccurrences(of: "_", with: " "))
                    .font(.cyDisplay(tamano, weight: .regular))
                    .tracking(tamano * 0.11)
                    .foregroundStyle(Color.cyGranate)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.cyGranate.opacity(0.10))
                    .overlay(Rectangle().stroke(Color.cyOro, lineWidth: 1))
            }
        }
    }
}

/// Un Layout que coloca fichas y salta de línea al acabarse el ancho.
struct FlujoHorizontal: Layout {
    var espaciado: CGFloat = 6
    var espaciadoLinea: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let ancho = proposal.width ?? .infinity
        let filas = repartir(subviews: subviews, ancho: ancho)
        let alto = filas.reduce(0) { $0 + $1.alto } + max(0, CGFloat(filas.count - 1)) * espaciadoLinea
        let anchoUsado = filas.map(\.ancho).max() ?? 0
        return CGSize(width: min(ancho, max(anchoUsado, 0)), height: alto)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        let filas = repartir(subviews: subviews, ancho: bounds.width)
        var y = bounds.minY
        for fila in filas {
            var x = bounds.minX
            for indice in fila.indices {
                let medida = subviews[indice].sizeThatFits(.unspecified)
                subviews[indice].place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                                       proposal: ProposedViewSize(medida))
                x += medida.width + espaciado
            }
            y += fila.alto + espaciadoLinea
        }
    }

    private struct Fila {
        var indices: [Int] = []
        var ancho: CGFloat = 0
        var alto: CGFloat = 0
    }

    private func repartir(subviews: Subviews, ancho: CGFloat) -> [Fila] {
        var filas: [Fila] = []
        var actual = Fila()
        for indice in subviews.indices {
            let medida = subviews[indice].sizeThatFits(.unspecified)
            let anchoConEsta = actual.indices.isEmpty
                ? medida.width
                : actual.ancho + espaciado + medida.width
            if !actual.indices.isEmpty && anchoConEsta > ancho {
                filas.append(actual)
                actual = Fila(indices: [indice], ancho: medida.width, alto: medida.height)
            } else {
                actual.indices.append(indice)
                actual.ancho = anchoConEsta
                actual.alto = max(actual.alto, medida.height)
            }
        }
        if !actual.indices.isEmpty { filas.append(actual) }
        return filas
    }
}
