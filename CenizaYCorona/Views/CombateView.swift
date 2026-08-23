import SwiftUI

struct CombateView: View {
    let state: GameState
    let combate: CombatSession

    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var girando = false
    @State private var giro = 0
    @State private var carasProvisionales: (Int, Int) = (3, 4)
    @State private var modo: ModoDeAtaque?
    @State private var mostrandoHoja = false

    private var esAncha: Bool { sizeClass == .regular }
    private var anchoMaximo: CGFloat { esAncha ? 640 : .infinity }

    private var modosDisponibles: [ModoDeAtaque] {
        var salida: [ModoDeAtaque] = [.arma(state.arma)]
        if let secundaria = state.armaSecundaria, secundaria.dano > 0 {
            salida.append(.arma(secundaria))
        }
        // La honda de Bren no ocupa mochila: la llevas mientras la conserves.
        if state.flags.contains("HONDA_DE_BREN") {
            salida.append(.arma(.hondaDeBren))
        }
        salida += state.hechizos.filter(\.esAtaque).map { ModoDeAtaque.hechizo($0) }
        return salida
    }

    private var modoActivo: ModoDeAtaque { modo ?? .arma(state.arma) }

    var body: some View {
        ZStack {
            Pergamino()

            VStack(spacing: 0) {
                barraSuperior

                ScrollView {
                    VStack(spacing: 0) {
                        panelDeEnemigo
                        dados.padding(.top, 20)
                        sumaYTotal.padding(.top, 14)
                        EscalaDificultad(activa: combate.dificultadEquivalente).padding(.top, 12)
                        Text("La Defensa \(combate.enemigo.defensa) del enemigo es tu objetivo; la tuya es \(state.defensa).")
                            .font(.cyBody(11).italic())
                            .foregroundStyle(Color.cyTintaTenue)
                            .multilineTextAlignment(.center)
                            .padding(.top, 6)

                        if combate.ultimaTirada != nil {
                            bandaDeResultado.padding(.top, 12)
                        }
                        registro.padding(.top, 12).padding(.bottom, 18)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: anchoMaximo)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)

                pie
            }
        }
        .sheet(isPresented: $mostrandoHoja) {
            HojaView(state: state)
        }
    }

    // ── Enemigo ─────────────────────────────────────────────────────────────

    private var panelDeEnemigo: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                GlifoLamina()
                    .stroke(Color.cyOro, lineWidth: 1.1)
                    .opacity(0.7)
                    .frame(width: 32, height: 32)
                    .padding(8)
                    .background(Color.black.opacity(0.22))
                    .overlay(Rectangle().stroke(Color.cyOro.opacity(0.7), lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text(combate.enemigo.nombre)
                        .font(.cyDisplay(16, weight: .semibold))
                        .foregroundStyle(Color.cyOroClaro)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Ronda \(combate.ronda)")
                        .font(.cyBody(12).italic())
                        .foregroundStyle(Color.cyPergaminoCla.opacity(0.7))
                }
                Spacer(minLength: 0)
            }

            VStack(spacing: 5) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.cyOro.opacity(0.14))
                        Rectangle().fill(Color.cyOro).frame(width: geo.size.width * proporcionEnemigo)
                    }
                }
                .frame(height: 8)
                .overlay(Rectangle().stroke(Color.cyOro.opacity(0.35), lineWidth: 1))
                .animation(.easeOut(duration: 0.35), value: combate.vidaEnemigo)

                HStack {
                    Versal(texto: "Vida del enemigo", tamano: 8, color: .cyOro.opacity(0.85))
                    Spacer(minLength: 0)
                    Text("\(combate.vidaEnemigo)/\(combate.enemigo.vida)")
                        .font(.cyBody(11))
                        .foregroundStyle(Color.cyPergamino.opacity(0.8))
                }
            }
            .padding(.top, 12)

            HStack(spacing: 8) {
                estadistica("Defensa", "\(combate.enemigo.defensa)")
                estadistica("Vida", "\(combate.enemigo.vida)")
                estadistica("Ataque", "+\(combate.enemigo.ataque)")
                estadistica("Daño", "\(combate.enemigo.dano)")
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.cyOro.opacity(0.3)).frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("OBJETIVO · \(combate.objetivoTactico)")
                    .font(.cyBody(11).italic())
                    .foregroundStyle(Color.cyPergaminoCla.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
                Text("INTENCIÓN · \(combate.intencionTactica)")
                    .font(.cyBody(10.5).italic())
                    .foregroundStyle(Color.cyOroClaro.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
                if state.planDeMarcha == .vigilancia && combate.ronda == 1 {
                    Text("VIGILANCIA PREPARADA · el primer ataque enemigo recibe −2")
                        .font(.cyBody(9.5))
                        .foregroundStyle(Color(red: 190/255, green: 220/255, blue: 170/255))
                }
                if state.herido && !state.penalizacionDeHeridaUsada {
                    Text("HERIDO · tu próxima prueba de FUE o AGI recibe −1")
                        .font(.cyBody(9.5))
                        .foregroundStyle(Color(red: 235/255, green: 175/255, blue: 145/255))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Color(red: 91/255, green: 16/255, blue: 32/255),
                                    Color(red: 50/255, green: 10/255, blue: 18/255)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .marcoOrnamental(color: .cyOro, opacidadLinea: 1)
        .padding(.top, 14)
    }

    private var proporcionEnemigo: CGFloat {
        guard combate.enemigo.vida > 0 else { return 0 }
        return CGFloat(combate.vidaEnemigo) / CGFloat(combate.enemigo.vida)
    }

    private func estadistica(_ titulo: String, _ valor: String) -> some View {
        VStack(spacing: 3) {
            Versal(texto: titulo, tamano: 7.5, color: .cyOro.opacity(0.85))
            Text(valor)
                .font(.cyDisplay(17, weight: .regular))
                .foregroundStyle(Color.cyPergaminoCla)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // ── Dados ───────────────────────────────────────────────────────────────

    private var dados: some View {
        HStack(spacing: 22) {
            CaraDeDado(valor: caraA, lado: esAncha ? 88 : 76)
                .rotationEffect(.degrees(Double(giro) * 360))
            CaraDeDado(valor: caraB, lado: esAncha ? 88 : 76)
                .rotationEffect(.degrees(Double(giro) * -360))
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.62), value: giro)
    }

    private var caraA: Int { girando ? carasProvisionales.0 : (combate.ultimaTirada?.d1 ?? 3) }
    private var caraB: Int { girando ? carasProvisionales.1 : (combate.ultimaTirada?.d2 ?? 4) }

    private var sumaYTotal: some View {
        HStack(spacing: 10) {
            if let tirada = combate.ultimaTirada, !girando {
                Text("\(tirada.d1) + \(tirada.d2) = \(tirada.suma)")
                    .font(.cyBody(13))
                    .foregroundStyle(Color.cyTintaSuave)
                Text("+\(tirada.modificador)")
                    .font(.cyBody(13))
                    .foregroundStyle(Color.cyOroOscuro)
                Rectangle().fill(Color.cyOro.opacity(0.6)).frame(width: 1, height: 16)
                Text("\(tirada.total)")
                    .font(.cyDisplay(30, weight: .bold))
                    .foregroundStyle(Color.cyGranate)
            } else {
                Text(girando ? "La suerte todavía está en el aire…"
                             : "2D6 + \(modoActivo.atributo.sigla) contra Defensa \(combate.enemigo.defensa)")
                    .font(.cyBody(13).italic())
                    .foregroundStyle(Color.cyTintaTenue)
            }
        }
        .frame(height: 34)
    }

    private var bandaDeResultado: some View {
        let claro = Color(red: 216/255, green: 205/255, blue: 182/255)
        return HStack(spacing: 11) {
            Versal(texto: combate.tituloDeResultado, tamano: 13,
                   color: combate.ultimoImpacto ? .cyOroClaro : claro, peso: .bold)
            Spacer(minLength: 0)
            Text(combate.detalleDeResultado)
                .font(.cyBody(12.5))
                .foregroundStyle((combate.ultimoImpacto ? Color.cyOroClaro : claro).opacity(0.9))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(combate.ultimoImpacto ? Color.cyGranate : Color.cyTinta.opacity(0.88))
        .overlay(Rectangle().stroke(combate.ultimoImpacto ? Color.cyOro : Color.cyApagado.opacity(0.7),
                                    lineWidth: 1))
        .opacity(girando ? 0.35 : 1)
        .animation(.easeInOut(duration: 0.2), value: girando)
    }

    private var registro: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(combate.registro.suffix(5).reversed()) { linea in
                Text(linea.texto)
                    .font(.cyBody(11.5).italic())
                    .foregroundStyle(linea.lado == .sistema ? Color.cyCorrupcion : Color.cyTintaTenue)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 11)
        .overlay(alignment: .leading) {
            Rectangle().fill(Color.cyOro.opacity(0.55)).frame(width: 1)
        }
    }

    // ── Pie ─────────────────────────────────────────────────────────────────

    private var pie: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                MedidorContinuo(titulo: "Vida", valor: state.vida,
                                total: state.vidaMaxima, color: .cyVida, alto: 7)
                if state.ecosMaximos > 0 {
                    MedidorContinuo(titulo: "Ecos", valor: state.ecos,
                                    total: state.ecosMaximos, color: .cyOroOscuro, alto: 7)
                        .frame(maxWidth: 82)
                }
                MedidorDeCorrupcion(valor: state.corrupcion, alto: 7)
            }

            if combate.terminado, let destino = combate.destino {
                BotonPrimario(titulo: "Continuar · §\(destino)") {
                    state.registrarCombate(combate.enemigo.nombre, victoria: combate.fase == .ganado)
                    router.avanzar(state, a: destino)
                }
            } else {
                if let salida = combate.salida, combate.puedeIntentarSalida(state),
                   let dif = combate.dificultadDeSalida(state) {
                    botonDeSalida(salida, dif)
                }
                if let parlamento = combate.parlamento, combate.puedeParlamentar(state) {
                    botonDeParlamento(parlamento)
                }
                if !salidasDeLaSeccion.isEmpty { salidas }
                if combate.bonoDeEmboscada(state) > 0 {
                    Text("Emboscada: sumas \(state.atributo(.agi)) al daño de esta primera ronda.")
                        .font(.cyBody(11.5).italic())
                        .foregroundStyle(Color.cyGranate)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let nota = combate.regla?.nota {
                    Text(nota)
                        .font(.cyBody(11.5).italic())
                        .foregroundStyle(Color.cyOroOscuro)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if combate.frascosDisponibles(state) > 0 {
                    BotonSecundario(titulo: "Lanzar fuego alquímico · 5 de daño, ignora Defensa", alto: 46) {
                        combate.lanzarFrasco(state: state)
                        SaveStore.shared.guardar(state)
                    }
                    .disabled(girando)
                }
                if modosDisponibles.count > 1 { selectorDeModo }
                donesDeVocacion
                dones
                if combate.puedeForzarElHechizo(state, modo: modoActivo) {
                    BotonSecundario(titulo: "Forzar \(modoActivo.nombre) sin Ecos · +1 Corrupción", alto: 46) {
                        tirar(forzandoElHechizo: true)
                    }
                    .disabled(girando)
                }
                BotonPrimario(titulo: "Atacar con \(modoActivo.nombre)",
                              subtitulo: subtituloDeAtaque,
                              habilitado: !girando && puedePagar) {
                    tirar()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(maxWidth: anchoMaximo)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color.cyPergamino.opacity(0),
                                    Color(red: 231/255, green: 218/255, blue: 188/255)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    /// Las elecciones propias de la sección de combate (§38 y §122).
    private var salidasDeLaSeccion: [Choice] {
        guard !combate.terminado,
              let sec = state.seccion, sec.id == combate.seccionID,
              ReglasEspeciales.salidasDisponibles(seccion: sec.id, vidaEnemigo: combate.vidaEnemigo)
        else { return [] }
        return sec.choices.filter { state.cumple($0) }
    }

    private var salidas: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Rectangle().fill(Color.cyOro.opacity(0.45)).frame(height: 1)
                Versal(texto: "Otra salida", tamano: 8.5)
                Rectangle().fill(Color.cyOro.opacity(0.45)).frame(height: 1)
            }
            ForEach(salidasDeLaSeccion) { choice in
                FilaDeEleccion(choice: choice, disponible: true) {
                    router.avanzar(state, a: choice.target, por: choice)
                }
            }
        }
    }

    /// La salida propia de una vocación: no ser vista, o hablarle.
    /// Se marca con la vocación a la que pertenece cuando es la tuya.
    private func botonDeSalida(_ s: SalidaDeVocacion, _ dif: Dificultad) -> some View {
        let esTuya = state.vocacion == s.vocacion
        return VStack(alignment: .leading, spacing: 7) {
            if esTuya {
                Text(s.vocacion.nombre.uppercased())
                    .font(.cyDisplay(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.cyOro)
            }
            Text(s.invitacion)
                .font(.cyBody(12).italic())
                .foregroundStyle(Color.cyTintaSuave)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            BotonSecundario(titulo: "\(s.titulo) · prueba de \(s.atributo.sigla) \(dif.nombre) \(dif.objetivo)+",
                            alto: 46) {
                combate.intentarSalida(state: state)
                SaveStore.shared.guardar(state, combate: combate)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.cyPergaminoOsc.opacity(esTuya ? 0.55 : 0.4))
        .marcoOrnamental(opacidadLinea: esTuya ? 0.8 : 0.55)
    }

    /// La salida que no es matar ni morir (§1143).
    private func botonDeParlamento(_ p: Parlamento) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(p.invitacion)
                .font(.cyBody(12).italic())
                .foregroundStyle(Color.cyTintaSuave)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            BotonSecundario(titulo: "Parlamentar · prueba de \(p.atributo.sigla) \(p.dificultad.nombre) \(p.dificultad.objetivo)+",
                            alto: 46) {
                combate.parlamentar(state: state)
                SaveStore.shared.guardar(state, combate: combate)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.cyPergaminoOsc.opacity(0.4))
        .marcoOrnamental(opacidadLinea: 0.55)
    }

    private var subtituloDeAtaque: String {
        var partes = ["2D6 + \(modoActivo.atributo.sigla) \(state.atributo(modoActivo.atributo))"]
        var dano = combate.danoDe(modoActivo)
        if state.atributo(modoActivo.atributo) >= Reglas.umbralDeDanoExtra { dano += 1 }
        dano += combate.bonoDeEmboscada(state)
        partes.append("Daño \(dano)")
        if modoActivo.costeEnEcos > 0 { partes.append("\(modoActivo.costeEnEcos) Eco") }
        return partes.joined(separator: " · ")
    }

    private var puedePagar: Bool { state.ecos >= modoActivo.costeEnEcos }

    private var selectorDeModo: some View {
        HStack(spacing: 7) {
            ForEach(modosDisponibles) { candidato in
                let activo = candidato.id == modoActivo.id
                Button { modo = candidato } label: {
                    VStack(spacing: 2) {
                        Text(candidato.nombre)
                            .font(.cyDisplay(10.5, weight: activo ? .semibold : .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text("\(candidato.atributo.sigla) · Daño \(candidato.dano)")
                            .font(.cyBody(9.5))
                    }
                    .foregroundStyle(activo ? Color.cyGranate : Color.cyTintaTenue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(activo ? Color.cyGranate.opacity(0.10) : Color.cyPergaminoCla.opacity(0.35))
                    .overlay(Rectangle().stroke(activo ? Color.cyOro : Color.cyOro.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Dones y hechizos de vocación que se arman antes de atacar.
    @ViewBuilder
    private var donesDeVocacion: some View {
        let eco = combate.puedeUsarEcoProfundo(state)
        let muro = combate.puedeUsarMuroDeVoto(state)
        let furia = combate.puedeUsarFuria(state)
        if eco || muro || furia {
            HStack(spacing: 7) {
                if furia {
                    botonArmable(titulo: "Furia de Forjagrís", nota: "repites si fallas · +1 Corrupción",
                                 armado: combate.furiaArmada) {
                        combate.furiaArmada.toggle()
                    }
                }
                if eco {
                    botonArmable(titulo: "Eco Profundo", nota: "+2 mágico · +1 Corrupción",
                                 armado: combate.ecoProfundoArmado) {
                        combate.ecoProfundoArmado.toggle()
                    }
                }
                if muro {
                    botonArmable(titulo: "Muro de Voto", nota: "−2 daño · \(Hechizo.muroDeVoto.coste) Eco",
                                 armado: combate.muroDeVotoArmado) {
                        combate.muroDeVotoArmado.toggle()
                    }
                }
            }
        }
    }

    private func botonArmable(titulo: String, nota: String, armado: Bool,
                              accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            VStack(spacing: 2) {
                Text(titulo)
                    .font(.cyDisplay(10.5, weight: armado ? .semibold : .regular))
                    .lineLimit(1).minimumScaleFactor(0.75)
                Text(nota).font(.cyBody(9.5))
            }
            .foregroundStyle(armado ? Color.cyGranate : Color.cyTintaTenue)
            .frame(maxWidth: .infinity).frame(height: 44)
            .background(armado ? Color.cyGranate.opacity(0.10) : Color.cyPergaminoCla.opacity(0.35))
            .overlay(Rectangle().stroke(armado ? Color.cyOro : Color.cyOro.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(girando)
    }

    private var dones: some View {
        HStack(spacing: 7) {
            donBoton(DonForzado.golpeDeGrieta, armado: combate.golpeDeGrietaArmado) {
                combate.golpeDeGrietaArmado.toggle()
                combate.pielDeCenizaArmada = false
            }
            donBoton(DonForzado.pielDeCeniza, armado: combate.pielDeCenizaArmada) {
                combate.pielDeCenizaArmada.toggle()
                combate.golpeDeGrietaArmado = false
            }
        }
    }

    private func donBoton(_ don: DonForzado, armado: Bool, accion: @escaping () -> Void) -> some View {
        let disponible = state.corrupcion + don.costeCorrupcion <= Reglas.corrupcionMaxima
        return Button(action: { if disponible { accion() } }) {
            VStack(spacing: 2) {
                Text(don.nombre)
                    .font(.cyDisplay(10.5, weight: armado ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text("+\(don.costeCorrupcion) Corrupción")
                    .font(.cyBody(9.5))
            }
            .foregroundStyle(armado ? Color.cyCorrupcion : Color.cyTintaTenue)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(armado ? Color.cyCorrupcion.opacity(0.14) : Color.cyPergaminoOsc.opacity(0.22))
            .overlay(Rectangle().stroke(armado ? Color.cyCorrupcion : Color.cyApagado.opacity(0.55),
                                        style: StrokeStyle(lineWidth: 1, dash: armado ? [] : [4, 3])))
        }
        .buttonStyle(.plain)
        .disabled(!disponible || girando)
        .opacity(disponible ? 1 : 0.4)
    }

    private var barraSuperior: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 44, height: 44)
            HStack(spacing: 8) {
                Image(systemName: "figure.fencing")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.cyGranate)
                Versal(texto: "Combate · §\(combate.seccionID)", tamano: 10.5, color: .cyGranate)
            }
            .frame(maxWidth: .infinity)
            Button { mostrandoHoja = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bag")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.cyGranate)
                    if curacionesDisponibles > 0 {
                        Circle().fill(Color.cyGranate)
                            .frame(width: 7, height: 7)
                            .offset(x: 3, y: -2)
                    }
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.cyPergaminoCla.opacity(0.42))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.cyOro.opacity(0.5)).frame(height: 1)
        }
    }

    /// El libro (Parte II, §13) permite usar un objeto en mitad del combate.
    private var curacionesDisponibles: Int {
        state.mochila.filter(\.cura).count
    }

    // ── Tirada ──────────────────────────────────────────────────────────────

    private func tirar(forzandoElHechizo: Bool = false) {
        guard !girando, !combate.terminado else { return }
        let elegido = modoActivo
        girando = true
        giro += 1
        var pasos = 0
        Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { temporizador in
            carasProvisionales = (Int.random(in: 1...6), Int.random(in: 1...6))
            pasos += 1
            if pasos >= 6 {
                temporizador.invalidate()
                combate.atacar(state: state, modo: elegido, forzandoElHechizo: forzandoElHechizo)
                girando = false
                SaveStore.shared.guardar(state, combate: combate)
            }
        }
    }
}
