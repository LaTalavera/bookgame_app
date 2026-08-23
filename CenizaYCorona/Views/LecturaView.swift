import SwiftUI

struct LecturaView: View {
    let state: GameState

    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var mostrandoHoja = false

    private var esAncha: Bool { sizeClass == .regular }

    var body: some View {
        ZStack {
            if let section = state.seccion {
                if section.esFinal {
                    FinalView(state: state, section: section)
                } else if let combate = router.combate, combate.seccionID == section.id {
                    CombateView(state: state, combate: combate)
                } else {
                    lectura(section)
                }
            } else {
                seccionPerdida
            }
        }
        .sheet(isPresented: $mostrandoHoja) {
            HojaView(state: state)
        }
    }

    // ── Lectura ─────────────────────────────────────────────────────────────

    private func lectura(_ section: Section) -> some View {
        ZStack {
            Pergamino()

            VStack(spacing: 0) {
                barraSuperior(section)

                if esAncha {
                    HStack(spacing: 0) {
                        CarrilPersonaje(state: state)
                            .frame(width: 300)
                            .overlay(alignment: .trailing) {
                                Rectangle().fill(Color.cyOro.opacity(0.5)).frame(width: 1)
                            }
                        cuerpo(section)
                    }
                } else {
                    VStack(spacing: 0) {
                        BarraDeEstado(state: state)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(Color.cyPergaminoCla.opacity(0.22))
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(Color.cyOro.opacity(0.35)).frame(height: 1)
                            }
                        cuerpo(section)
                    }
                }
            }
        }
    }

    private func cuerpo(_ section: Section) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                encabezadoDeSeccion(section)
                avisos
                texto(section)

                if let ilustracion = section.illustration {
                    FichaDeArte(sectionID: section.id, illustration: ilustracion, horizontal: esAncha)
                        .padding(.top, 18)
                }

                if section.esPuntoDeDescanso {
                    puntoDeDescanso.padding(.top, 18)
                }

                if let tienda = state.tiendaActual {
                    PanelDeTienda(state: state, tienda: tienda, esAncha: esAncha)
                        .padding(.top, 18)
                }

                if state.esTablaDeFinales {
                    tablaDeFinales.padding(.top, 24)
                } else if let prueba = state.pruebaPendiente {
                    PanelDePrueba(state: state, prueba: prueba, esAncha: esAncha) { rama in
                        router.avanzar(state, a: rama.destino)
                    }
                    .padding(.top, 24)
                    .id(prueba.seccion)
                } else {
                    elecciones(section).padding(.top, 24)
                }

                Color.clear.frame(height: 34)
            }
            .padding(.horizontal, esAncha ? 40 : 18)
            .frame(maxWidth: esAncha ? 580 : .infinity)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .id(section.id)
    }

    private func encabezadoDeSeccion(_ section: Section) -> some View {
        VStack(spacing: 10) {
            Text(section.title)
                .font(.cyDisplay(esAncha ? 26 : 20, weight: .semibold))
                .foregroundStyle(Color.cyGranate)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            FileteOrnamental(ancho: esAncha ? 66 : 52)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var avisos: some View {
        if !state.avisos.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(state.avisos) { aviso in
                    HStack(alignment: .top, spacing: 7) {
                        Rombo(lleno: true, tamano: 5, color: color(de: aviso.tipo))
                            .padding(.top, 5)
                        Text(aviso.texto)
                            .font(.cyBody(11.5))
                            .tracking(aviso.tipo == .flag ? 0.7 : 0)
                            .foregroundStyle(color(de: aviso.tipo))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cyPergaminoOsc.opacity(0.32))
            .overlay(alignment: .leading) {
                Rectangle().fill(Color.cyOro.opacity(0.7)).frame(width: 2)
            }
            .padding(.bottom, 16)
        }
    }

    private func color(de tipo: Aviso.Tipo) -> Color {
        switch tipo {
        case .corrupcion: return .cyCorrupcion
        case .vida: return .cyVida
        case .reputacion: return .cyGranate
        case .ecos, .flag: return .cyOroOscuro
        case .sistema: return .cyTintaSuave
        }
    }

    private func texto(_ section: Section) -> some View {
        let tamano: CGFloat = esAncha ? 17.5 : 16.5
        return VStack(alignment: .leading, spacing: 13) {
            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { indice, parrafo in
                Text(TextoDelLibro.atribuido(parrafo, tamano: tamano,
                                             versalesIniciales: indice == 0))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func elecciones(_ section: Section) -> some View {
        VStack(spacing: 9) {
            ForEach(section.choices) { choice in
                FilaDeEleccion(choice: choice, disponible: state.cumple(choice),
                               unicaOpcion: section.choices.count == 1) {
                    router.avanzar(state, a: choice.target, por: choice)
                }
            }
        }
    }

    // ── Descanso y tabla de finales ─────────────────────────────────────────

    private var puntoDeDescanso: some View {
        let completo = state.vida >= state.vidaMaxima && state.ecos >= state.ecosMaximos
        return VStack(spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "flame")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.cyOroOscuro)
                Versal(texto: "Punto de descanso", tamano: 9)
                Spacer(minLength: 0)
            }
            Text("Recuperas todos tus Ecos y la mitad de tu Vida máxima. La Corrupción no baja con el descanso.")
                .font(.cyBody(12).italic())
                .foregroundStyle(Color.cyTintaSuave)
                .fixedSize(horizontal: false, vertical: true)
            BotonSecundario(titulo: completo ? "Ya estás al completo" : "Descansar",
                            alto: 46, punteado: completo) {
                if !completo {
                    state.descansar()
                    SaveStore.shared.guardar(state)
                }
            }
            .disabled(completo)

            VStack(alignment: .leading, spacing: 8) {
                Divider().overlay(Color.cyOro.opacity(0.35))
                Versal(texto: "Decisión de expedición", tamano: 8.5, color: .cyOroOscuro)
                Text(descripcionDeMarcha)
                    .font(.cyBody(11.5).italic())
                    .foregroundStyle(Color.cyTintaSuave)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 7) {
                    botonDeMarcha(.vigilancia, subtitulo: "Primer ataque enemigo −2")
                    botonDeMarcha(.lectura, subtitulo: "Próxima prueba +2")
                    botonDeMarcha(.silencio, subtitulo: "−1 Corrupción")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.cyPergaminoOsc.opacity(0.4))
        .marcoOrnamental(opacidadLinea: 0.55)
    }

    private var descripcionDeMarcha: String {
        if state.esperaDeMarcha > 0 {
            return "Callar la Grieta todavía exige silencio: el próximo preparativo se desbloquea en otro descanso."
        }
        guard let plan = state.planDeMarcha else {
            return "Elige un preparativo gratuito. No consume recursos ni cierra ninguna ruta."
        }
        return "\(plan.titulo). \(plan.efecto)"
    }

    private func botonDeMarcha(_ plan: PlanDeMarcha, subtitulo: String) -> some View {
        let activo = state.planDeMarcha == plan
        return Button {
            state.prepararMarcha(plan)
            SaveStore.shared.guardar(state)
        } label: {
            VStack(spacing: 2) {
                Text(plan.titulo)
                    .font(.cyDisplay(10.5, weight: activo ? .semibold : .regular))
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(subtitulo).font(.cyBody(9.2)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(activo ? Color.cyGranate : Color.cyTintaTenue)
            .frame(maxWidth: .infinity).frame(height: 44)
            .background(activo ? Color.cyGranate.opacity(0.10) : Color.cyPergaminoCla.opacity(0.35))
            .overlay(Rectangle().stroke(activo ? Color.cyOro : Color.cyOro.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!state.puedePrepararMarcha(plan))
        .opacity(state.puedePrepararMarcha(plan) ? 1 : 0.42)
    }

    private var tablaDeFinales: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 9) {
                Versal(texto: "Tabla de finales", tamano: 9)
                Rectangle().fill(Color.cyOro.opacity(0.4)).frame(height: 1)
            }
            Text("La app comprueba las condiciones por orden y te lleva a la primera que cumples.")
                .font(.cyBody(12).italic())
                .foregroundStyle(Color.cyTintaSuave)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(TablaDeFinales.reglas(para: state.seccionActual).enumerated()), id: \.offset) { indice, regla in
                    let cumple = regla.cumple(state)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: cumple ? "checkmark.circle" : "circle")
                            .font(.system(size: 11))
                            .foregroundStyle(cumple ? Color.cyGranate : Color.cyApagado)
                            .padding(.top, 2)
                        Text(regla.descripcion)
                            .font(.cyBody(12))
                            .foregroundStyle(cumple ? Color.cyTinta : Color.cyApagado)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Text("§\(regla.destino)")
                            .font(.cyDisplay(11, weight: .regular))
                            .foregroundStyle(cumple ? Color.cyOroOscuro : Color.cyApagado)
                    }
                    .opacity(indice > 0 && yaCumpleAntes(indice) ? 0.4 : 1)
                }
            }

            BotonPrimario(titulo: "Consultar mi final") {
                router.resolverTablaDeFinales(state)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.cyPergaminoCla.opacity(0.4))
        .marcoOrnamental(opacidadLinea: 0.6)
    }

    private func yaCumpleAntes(_ indice: Int) -> Bool {
        TablaDeFinales.reglas(para: state.seccionActual)
            .prefix(indice)
            .contains { $0.cumple(state) }
    }

    // ── Cromo ───────────────────────────────────────────────────────────────

    private func barraSuperior(_ section: Section) -> some View {
        HStack(spacing: 0) {
            Button { router.volverALaBiblioteca() } label: {
                Image(systemName: "books.vertical")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.cyGranate)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Versal(texto: "§\(section.id) · \(state.libroActual.title)", tamano: 10.5, color: .cyGranate)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Button { mostrandoHoja = true } label: {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.cyGranate)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(height: 50)
        .background(Color.cyPergaminoCla.opacity(0.42))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.cyOro.opacity(0.5)).frame(height: 1)
        }
    }

    private var seccionPerdida: some View {
        ZStack {
            Pergamino()
            VStack(spacing: 16) {
                Text("Esa página no está en el manuscrito.")
                    .font(.cyDisplay(18, weight: .semibold))
                    .foregroundStyle(Color.cyGranate)
                Text("La sección §\(state.seccionActual) no existe en saga.json.")
                    .font(.cyBody(13).italic())
                    .foregroundStyle(Color.cyTintaSuave)
                BotonSecundario(titulo: "Volver a la biblioteca") {
                    router.volverALaBiblioteca()
                }
                .frame(width: 260)
            }
            .padding(30)
        }
    }
}
