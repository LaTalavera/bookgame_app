import SwiftUI

/// El panel de prueba de habilidad: 2D6 + atributo contra la dificultad.
/// Sustituye a las elecciones cuando la sección pide una tirada.
struct PanelDePrueba: View {
    let state: GameState
    let prueba: PruebaDeHabilidad
    let esAncha: Bool
    let alResolver: (RamaDePrueba) -> Void

    @State private var resultado: ResultadoDePrueba?
    @State private var girando = false
    @State private var giro = 0
    @State private var carasProvisionales: (Int, Int) = (3, 4)
    @State private var yescaEncendida = false

    private var modificador: Int { state.atributo(prueba.atributo) }
    private var penalizacionDeHerida: Int {
        (prueba.atributo == .fue || prueba.atributo == .agi)
            && state.herido && !state.penalizacionDeHeridaUsada ? 1 : 0
    }
    private var bonoDeMarcha: Int { state.planDeMarcha == .lectura ? 2 : 0 }
    /// El pozo sin lampara sube un peldano: dos puntos sobre el objetivo.
    private var oscuridad: Int {
        state.necesitaLampara(en: prueba.seccion) && !yescaEncendida ? 2 : 0
    }
    private var minimoEnDados: Int {
        max(2, prueba.objetivo + oscuridad - modificador - bonoDeMarcha + penalizacionDeHerida)
    }
    private func minimoEnDados(_ via: SegundaVia) -> Int {
        let penalizacion = (via.atributo == .fue || via.atributo == .agi)
            && state.herido && !state.penalizacionDeHeridaUsada ? 1 : 0
        return max(2, via.dificultad.objetivo + oscuridad - state.atributo(via.atributo) - bonoDeMarcha + penalizacion)
    }
    private var herramientasQueResuelven: [HerramientaDePrueba] {
        state.herramientas(para: prueba, atributo: prueba.atributo).filter { $0.efecto == .resuelve }
    }
    private func herramientasQueRepiten(_ r: ResultadoDePrueba) -> [HerramientaDePrueba] {
        state.herramientas(para: prueba, atributo: r.atributoUsado).filter { $0.efecto == .repite }
    }
    private var puedeForzar: Bool {
        state.corrupcion + DonForzado.vozRota.costeCorrupcion <= Reglas.corrupcionMaxima
    }

    var body: some View {
        VStack(spacing: 0) {
            cabecera
            dados.padding(.top, 16)
            marcador.padding(.top, 12)

            if let resultado, !girando {
                bandaDeResultado(resultado).padding(.top, 14)
                if !resultado.efectos.isEmpty {
                    efectos(resultado).padding(.top, 10)
                }
            }

            if oscuridad > 0, resultado == nil {
                Text("Bajo tierra sin lámpara de aceite pesado: un peldaño más de dificultad.")
                    .font(.cyBody(11.5).italic())
                    .foregroundStyle(Color.cyGranate)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
            }

            if let nota = prueba.nota, resultado == nil {
                Text(nota)
                    .font(.cyBody(11.5).italic())
                    .foregroundStyle(Color.cyTintaTenue)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
            }

            acciones.padding(.top, 16)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
        .background(Color.cyPergaminoCla.opacity(0.42))
        .marcoOrnamental(opacidadLinea: 0.6)
    }

    // ── Piezas ──────────────────────────────────────────────────────────────

    private var cabecera: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Rectangle().fill(Color.cyOro.opacity(0.45)).frame(height: 1)
                Versal(texto: "Prueba de \(prueba.atributo.sigla)", tamano: 9)
                Rectangle().fill(Color.cyOro.opacity(0.45)).frame(height: 1)
            }
            Text("\(prueba.dificultad.nombre) · necesitas \(minimoEnDados)+ en 2D6")
                .font(.cyDisplay(15, weight: .semibold))
                .foregroundStyle(Color.cyGranate)
        }
    }

    private var dados: some View {
        HStack(spacing: 20) {
            CaraDeDado(valor: caraA, lado: esAncha ? 82 : 72)
                .rotationEffect(.degrees(Double(giro) * 360))
            CaraDeDado(valor: caraB, lado: esAncha ? 82 : 72)
                .rotationEffect(.degrees(Double(giro) * -360))
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.62), value: giro)
    }

    private var caraA: Int { girando ? carasProvisionales.0 : (resultado?.tirada.d1 ?? 3) }
    private var caraB: Int { girando ? carasProvisionales.1 : (resultado?.tirada.d2 ?? 4) }

    private var marcador: some View {
        HStack(spacing: 10) {
            if let resultado, !girando {
                Text("\(resultado.tirada.d1) + \(resultado.tirada.d2) = \(resultado.tirada.suma)")
                    .font(.cyBody(13))
                    .foregroundStyle(Color.cyTintaSuave)
                Text("+\(resultado.tirada.modificador) \(resultado.atributoUsado.sigla)")
                    .font(.cyBody(13))
                    .foregroundStyle(Color.cyOroOscuro)
                Rectangle().fill(Color.cyOro.opacity(0.6)).frame(width: 1, height: 16)
                Text("\(resultado.tirada.total)")
                    .font(.cyDisplay(28, weight: .bold))
                    .foregroundStyle(Color.cyGranate)
            } else {
                Text(girando ? "La suerte todavía está en el aire…"
                             : "2D6 + \(prueba.atributo.sigla) \(modificador)\(bonoDeMarcha > 0 ? " +2" : "")\(penalizacionDeHerida > 0 ? " −1" : "") contra \(prueba.objetivo)")
                    .font(.cyBody(13).italic())
                    .foregroundStyle(Color.cyTintaTenue)
            }
        }
        .frame(height: 32)
    }

    private func bandaDeResultado(_ r: ResultadoDePrueba) -> some View {
        let claro = Color(red: 216/255, green: 205/255, blue: 182/255)
        return HStack(spacing: 11) {
            Versal(texto: r.forzada ? "Voz rota" : (r.superada ? "Lo consigues" : "Fallas"),
                   tamano: 12.5, color: r.superada ? .cyOroClaro : claro, peso: .bold)
            Spacer(minLength: 0)
            Text("\(r.tirada.total) vs \(r.objetivoUsado)")
                .font(.cyBody(12.5))
                .foregroundStyle((r.superada ? Color.cyOroClaro : claro).opacity(0.9))
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(r.superada ? Color.cyGranate : Color.cyTinta.opacity(0.88))
        .overlay(Rectangle().stroke(r.superada ? Color.cyOro : Color.cyApagado.opacity(0.7), lineWidth: 1))
    }

    private func efectos(_ r: ResultadoDePrueba) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(r.efectos.enumerated()), id: \.offset) { _, efecto in
                HStack(alignment: .top, spacing: 7) {
                    Rombo(lleno: true, tamano: 5, color: .cyOroOscuro).padding(.top, 5)
                    Text(efecto)
                        .font(.cyBody(11.5))
                        .foregroundStyle(Color.cyTintaSuave)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var acciones: some View {
        if let resultado, !girando {
            VStack(spacing: 8) {
                // Ojo de Vardo: repetir una prueba de AGI fallida, una vez por sección.
                if !resultado.superada, state.puedeRepetirConOjoDeVardo(resultado) {
                    BotonSecundario(titulo: "Ojo de Vardo · repetir la prueba · +\(Reglas.corrupcionPorDon) Corrupción", alto: 46) {
                        self.resultado = state.repetirConOjoDeVardo(prueba: prueba, tras: resultado)
                        SaveStore.shared.guardar(state)
                    }
                }
                // Herramientas que compran una segunda tirada: la cuerda que queda
                // amarrada al descenso, el frasco de tinta que se vacia.
                if !resultado.superada {
                    ForEach(herramientasQueRepiten(resultado), id: \.self) { herramienta in
                        BotonSecundario(titulo: "\(herramienta.texto) · repetir la prueba · gastas el objeto", alto: 46) {
                            self.resultado = state.repetirConHerramienta(herramienta, tras: resultado)
                            SaveStore.shared.guardar(state)
                        }
                    }
                }
                BotonPrimario(titulo: "Continuar · §\(resultado.rama.destino)") {
                    alResolver(resultado.rama)
                }
            }
        } else {
            VStack(spacing: 8) {
                BotonPrimario(titulo: "Tirar la prueba", habilitado: !girando) { tirar() }

                // Una herramienta resuelve la prueba y no se gasta.
                ForEach(herramientasQueResuelven, id: \.self) { herramienta in
                    BotonSecundario(titulo: "\(herramienta.texto) · sin tirar", alto: 46) {
                        resultado = state.resolverConHerramienta(herramienta, prueba: prueba)
                        SaveStore.shared.guardar(state)
                    }
                    .disabled(girando)
                }

                // La yesca es la luz improvisada: anula el peldaño una vez.
                if state.puedeEncenderYesca(en: prueba.seccion) {
                    BotonSecundario(titulo: yescaEncendida
                                    ? "Yesca lista · la encenderás al tirar"
                                    : "Encender la yesca · anula el peldaño · la gastas",
                                    alto: 46, punteado: !yescaEncendida) {
                        yescaEncendida.toggle()
                    }
                    .disabled(girando)
                }

                BotonSecundario(titulo: puedeForzar
                                ? "Voz Rota · superarla sin tirar, +\(DonForzado.vozRota.costeCorrupcion) Corrupción"
                                : "Voz Rota · la ceniza ya no da más",
                                alto: 46, punteado: !puedeForzar) {
                    if puedeForzar { forzar() }
                }
                .disabled(!puedeForzar || girando)

                // Hechizos de la Vidente Rota que ayudan en una prueba.
                if state.puedeUsar(.susurroDePiel, en: prueba) {
                    BotonSecundario(titulo: "Susurro de Piel · superarla sin tirar, \(Hechizo.susurroDePiel.coste) Eco",
                                    alto: 46) { conApoyo(.susurroDePiel) }
                }
                if state.puedeUsar(.veloRoto, en: prueba) {
                    BotonSecundario(titulo: "Velo Roto · +3 a la tirada, \(Hechizo.veloRoto.coste) Ecos",
                                    alto: 46) { conApoyo(.veloRoto) }
                }

                if let alternativa = prueba.alternativa {
                    BotonSecundario(titulo: alternativa.texto, alto: 46) {
                        alResolver(RamaDePrueba(destino: alternativa.destino))
                    }
                }

                // Segunda vía: el mismo obstáculo resuelto con otro atributo.
                if let via = prueba.segundaVia {
                    BotonSecundario(titulo: "\(via.texto) · \(via.atributo.sigla) \(via.dificultad.objetivo)+ · necesitas \(minimoEnDados(via))+",
                                    alto: 46) { tirar(porSegundaVia: true) }
                        .disabled(girando)
                }
            }
        }
    }

    // ── Tirada ──────────────────────────────────────────────────────────────

    private func tirar() {
        tirar(porSegundaVia: false)
    }

    private func tirar(porSegundaVia: Bool) {
        guard !girando, resultado == nil else { return }
        girando = true
        giro += 1
        var pasos = 0
        Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { temporizador in
            carasProvisionales = (Int.random(in: 1...6), Int.random(in: 1...6))
            pasos += 1
            if pasos >= 6 {
                temporizador.invalidate()
                resultado = state.tirar(prueba: prueba, porSegundaVia: porSegundaVia, encendiendoYesca: yescaEncendida)
                girando = false
                SaveStore.shared.guardar(state)
            }
        }
    }

    /// Lanza un hechizo de apoyo y resuelve la prueba con él.
    private func conApoyo(_ apoyo: GameState.ApoyoDePrueba) {
        guard !girando, resultado == nil else { return }
        resultado = state.tirar(prueba: prueba, apoyo: apoyo, encendiendoYesca: yescaEncendida)
        SaveStore.shared.guardar(state)
    }

    private func forzar() {
        guard !girando, resultado == nil else { return }
        resultado = state.tirar(prueba: prueba, forzandoElDon: true)
        SaveStore.shared.guardar(state)
    }
}
