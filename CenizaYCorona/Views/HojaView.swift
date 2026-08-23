import SwiftUI

/// La Hoja de Personaje de la Parte III, §23.
struct HojaView: View {
    let state: GameState

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var pestana = 0

    private var anchoMaximo: CGFloat { sizeClass == .regular ? 660 : .infinity }

    var body: some View {
        ZStack {
            Pergamino()

            VStack(spacing: 0) {
                barraSuperior
                selectorDePestana

                ScrollView {
                    Group { if pestana == 0 { contenidoPersonaje } else { contenidoCronica } }
                    .padding(.horizontal, 18)
                    .frame(maxWidth: anchoMaximo)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var selectorDePestana: some View {
        HStack(spacing: 0) {
            botonDePestana("Personaje", indice: 0)
            botonDePestana("Crónica", indice: 1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(Color.cyPergaminoCla.opacity(0.24))
    }

    private func botonDePestana(_ titulo: String, indice: Int) -> some View {
        Button { pestana = indice } label: {
            Versal(texto: titulo, tamano: 9.5,
                   color: pestana == indice ? .cyGranate : .cyTintaTenue)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(pestana == indice ? Color.cyGranate.opacity(0.08) : .clear)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(pestana == indice ? Color.cyOro : .clear).frame(height: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var contenidoPersonaje: some View {
        VStack(alignment: .leading, spacing: 0) {
            identidad
            atributos.padding(.top, 20)
            recursos.padding(.top, 20)
            bloqueDeReputacion
            bloqueDeEquipo
            bloqueDeMochila
            if !state.hechizos.isEmpty { bloqueDeHechizos }
            bloqueDeInvocaciones
            bloqueDeDon
            bloqueDePalabrasClave
            pie.padding(.top, 26).padding(.bottom, 30)
        }
    }

    private var contenidoCronica: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 7) {
                Versal(texto: "La crónica recuerda", tamano: 9)
                Text("Tu historia")
                    .font(.cyDisplay(25, weight: .semibold))
                    .foregroundStyle(Color.cyGranate)
                FileteOrnamental(ancho: 54)
                HStack(spacing: 18) {
                    resumen("\(state.historia.filter { $0.tipo == .eleccion }.count)", "decisiones")
                    resumen("\(state.historia.filter { $0.tipo == .prueba }.count)", "pruebas")
                    resumen("\(state.finalesVistos.count)", "finales")
                }
                .padding(.top, 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)

            if !state.ilustracionesDescubiertas.isEmpty { galeria }
            acontecimientos
            Color.clear.frame(height: 30)
        }
    }

    private func resumen(_ valor: String, _ titulo: String) -> some View {
        VStack(spacing: 1) {
            Text(valor).font(.cyDisplay(18, weight: .semibold)).foregroundStyle(Color.cyGranate)
            Text(titulo).font(.cyBody(10).italic()).foregroundStyle(Color.cyTintaTenue)
        }
    }

    private var galeria: some View {
        bloque("Galería descubierta", nota: "\(state.ilustracionesDescubiertas.count)") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 12) {
                ForEach(state.ilustracionesDescubiertas.sorted(), id: \.self) { id in
                    if let section = SagaLibrary.shared[id], CatalogoIlustraciones.disponible(en: id) {
                        LaminaReal(seccion: id, pie: "§\(id) · \(section.illustration?.caption ?? section.title)",
                                   altura: 150)
                    }
                }
            }
        }
    }

    private var acontecimientos: some View {
        bloque("Acontecimientos", nota: "\(state.historia.count)") {
            if state.historia.isEmpty {
                Text("La primera página de tu crónica aún está en blanco.")
                    .font(.cyBody(12).italic()).foregroundStyle(Color.cyTintaTenue)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(state.historia.reversed()) { evento in
                        HStack(alignment: .top, spacing: 10) {
                            Rombo(lleno: true, tamano: 5, color: .cyOro).padding(.top, 7)
                            VStack(alignment: .leading, spacing: 2) {
                                Versal(texto: "\(evento.tipo.nombre) · §\(evento.seccion)", tamano: 7.5)
                                Text(evento.texto.replacingOccurrences(of: "_", with: " "))
                                    .font(.cyDisplay(12.5, weight: .regular)).foregroundStyle(Color.cyTinta)
                                if let detalle = evento.detalle {
                                    Text(detalle).font(.cyBody(10.5).italic()).foregroundStyle(Color.cyTintaTenue)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) { Rectangle().fill(Color.cyOro.opacity(0.22)).frame(height: 1) }
                    }
                }
            }
        }
    }

    private var barraSuperior: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 44, height: 44)
            Versal(texto: "Hoja de personaje", tamano: 10.5, color: .cyGranate)
                .frame(maxWidth: .infinity)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.cyGranate)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(height: 52)
        .background(Color.cyPergaminoCla.opacity(0.42))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.cyOro.opacity(0.5)).frame(height: 1)
        }
    }

    private var identidad: some View {
        HStack(spacing: 15) {
            Medallon(inicial: String(state.nombre.prefix(1)).uppercased(), lado: 76)
            VStack(alignment: .leading, spacing: 4) {
                Text(state.nombre)
                    .font(.cyDisplay(21, weight: .semibold))
                    .foregroundStyle(Color.cyGranate)
                    .fixedSize(horizontal: false, vertical: true)
                Text(state.vocacion.nombre)
                    .font(.cyBody(13).italic())
                    .foregroundStyle(Color.cyTintaSuave)
                Versal(texto: "Libro \(state.libroActual.numeral) · §\(state.seccionActual)", tamano: 10)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 18)
    }

    private var atributos: some View {
        VStack(spacing: 9) {
            ForEach(Atributo.allCases) { atributo in
                FilaAtributo(atributo: atributo, valor: state.atributo(atributo))
            }
            Rectangle().fill(Color.cyOro.opacity(0.35)).frame(height: 1)
            HStack {
                Text("Defensa")
                    .font(.cyDisplay(12.5, weight: .regular))
                    .foregroundStyle(Color.cyTinta)
                Text("8 base + \(state.armadura.bonoDefensa) armadura\(state.llevaEscudo ? " + 1 escudo" : "")\(state.companero.map { $0.defensa > 0 ? " + \($0.nombre)" : "" } ?? "")")
                    .font(.cyBody(10.5).italic())
                    .foregroundStyle(Color.cyTintaTenue)
                Spacer(minLength: 0)
                Text("\(state.defensa)")
                    .font(.cyDisplay(19, weight: .semibold))
                    .foregroundStyle(Color.cyGranate)
            }
            if let companero = state.companero {
                Rectangle().fill(Color.cyOro.opacity(0.35)).frame(height: 1)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Baja contigo")
                        .font(.cyDisplay(12.5, weight: .regular))
                        .foregroundStyle(Color.cyTinta)
                    Text("\(companero.nombre) · \(companero.efecto)")
                        .font(.cyBody(10.5).italic())
                        .foregroundStyle(Color.cyTintaTenue)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.cyPergaminoCla.opacity(0.38))
        .marcoOrnamental(opacidadLinea: 0.55)
    }

    private var recursos: some View {
        VStack(alignment: .leading, spacing: 13) {
            MedidorContinuo(titulo: "Vida", valor: state.vida,
                            total: state.vidaMaxima, color: .cyVida, alto: 9)
            if state.ecosMaximos > 0 {
                MedidorContinuo(titulo: "Ecos", valor: state.ecos,
                                total: state.ecosMaximos, color: .cyOroOscuro, alto: 9)
            }
            MedidorDeCorrupcion(valor: state.corrupcion, alto: 9, conNota: true)
        }
    }

    private var bloqueDeReputacion: some View {
        bloque("Reputación", nota: "de -5 a +5") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(state.marcadoresActivos) { track in
                    FilaReputacion(track: track, valor: state.rep(track))
                }
                let dormidos = RepTrack.allCases.filter { !state.marcadoresActivos.contains($0) }
                if !dormidos.isEmpty {
                    Text("\(dormidos.map(\.nombre).joined(separator: " y ")) no entran en juego en este libro.")
                        .font(.cyBody(11).italic())
                        .foregroundStyle(Color.cyTintaTenue)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var bloqueDeEquipo: some View {
        bloque("Equipo en mano") {
            VStack(alignment: .leading, spacing: 7) {
                filaDeEquipo("Arma principal", state.arma.nombre, "Daño \(state.arma.dano)",
                             nota: state.arma.nota)
                if let secundaria = state.armaSecundaria {
                    filaDeEquipo("Secundaria", secundaria.nombre,
                                 secundaria.dano > 0 ? "Daño \(secundaria.dano)" : "foco",
                                 nota: secundaria.nota)
                }
                if state.llevaEscudo {
                    filaDeEquipo("Escudo", "Escudo", "+1 Def", nota: nil)
                }
                filaDeEquipo("Armadura", state.armadura.nombre,
                             "+\(state.armadura.bonoDefensa) Def", nota: state.armadura.nota)
            }
        }
    }

    private func filaDeEquipo(_ ranura: String, _ nombre: String,
                              _ valor: String, nota: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Versal(texto: ranura, tamano: 8)
                Spacer(minLength: 6)
                Text(valor)
                    .font(.cyBody(11))
                    .foregroundStyle(Color.cyOroOscuro)
            }
            Text(nombre)
                .font(.cyDisplay(13, weight: .regular))
                .foregroundStyle(Color.cyTinta)
            if let nota {
                Text(nota)
                    .font(.cyBody(10.5).italic())
                    .foregroundStyle(Color.cyTintaTenue)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var bloqueDeMochila: some View {
        bloque("Mochila", nota: "\(state.mochila.count) de \(Reglas.espaciosDeMochila)") {
            VStack(spacing: 7) {
                ForEach(state.mochila) { objeto in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(objeto.nombre)
                                .font(.cyDisplay(12.5, weight: .regular))
                                .foregroundStyle(Color.cyTinta)
                            if !objeto.descripcion.isEmpty {
                                Text(objeto.descripcion)
                                    .font(.cyBody(10.5).italic())
                                    .foregroundStyle(Color.cyTintaTenue)
                            }
                        }
                        Spacer(minLength: 0)
                        if objeto.cura {
                            Button {
                                state.usar(objeto: objeto)
                                SaveStore.shared.guardar(state)
                            } label: {
                                Versal(texto: "Usar", tamano: 9, color: .cyGranate)
                                    .padding(.horizontal, 12)
                                    .frame(height: 34)
                                    .overlay(Rectangle().stroke(Color.cyOro.opacity(0.7), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                ForEach(0..<state.espaciosLibres, id: \.self) { _ in
                    HStack {
                        Text("—")
                            .font(.cyBody(12))
                            .foregroundStyle(Color.cyApagado.opacity(0.6))
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var bloqueDeHechizos: some View {
        bloque("Hechizos conocidos") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(state.hechizos) { hechizo in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(hechizo.nombre)
                                .font(.cyDisplay(12.5, weight: .regular))
                                .foregroundStyle(Color.cyTinta)
                            Spacer(minLength: 6)
                            Text("\(hechizo.coste) Eco\(hechizo.coste == 1 ? "" : "s")")
                                .font(.cyBody(11))
                                .foregroundStyle(Color.cyOroOscuro)
                        }
                        Text(hechizo.descripcion)
                            .font(.cyBody(11).italic())
                            .foregroundStyle(Color.cyTintaTenue)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    /// Hechizos de curación y el Voto de Ceniza, usables desde aquí.
    @ViewBuilder
    private var bloqueDeInvocaciones: some View {
        let lanzables = state.hechizosFueraDeCombate
        if !lanzables.isEmpty || state.vocacion == .penitente {
            bloque("Invocar", nota: state.ecosMaximos > 0 ? "\(state.ecos) Ecos" : nil) {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(lanzables) { hechizo in
                        filaInvocable(titulo: hechizo.nombre,
                                      detalle: hechizo.descripcion,
                                      coste: "\(hechizo.coste) Eco\(hechizo.coste == 1 ? "" : "s")",
                                      activo: state.puedeLanzar(hechizo)) {
                            state.lanzar(hechizo)
                            SaveStore.shared.guardar(state)
                        }
                    }
                    if state.vocacion == .penitente {
                        filaInvocable(titulo: "Voto de Ceniza",
                                      detalle: "Curas 1D6+2 puntos de Vida. Una vez por libro.",
                                      coste: state.votoDeCenizaUsadoEnLibro ? "gastado" : "+1 Corrupción",
                                      activo: state.puedeUsarVotoDeCeniza) {
                            state.usarVotoDeCeniza()
                            SaveStore.shared.guardar(state)
                        }
                    }
                }
            }
        }
    }

    private func filaInvocable(titulo: String, detalle: String, coste: String,
                               activo: Bool, accion: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.cyDisplay(12.5, weight: .regular))
                    .foregroundStyle(Color.cyTinta)
                Text(detalle)
                    .font(.cyBody(11).italic())
                    .foregroundStyle(Color.cyTintaTenue)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            VStack(spacing: 3) {
                Text(coste)
                    .font(.cyBody(10.5))
                    .foregroundStyle(Color.cyOroOscuro)
                Button(action: accion) {
                    Versal(texto: "Usar", tamano: 9, color: activo ? .cyGranate : .cyApagado)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .overlay(Rectangle().stroke(
                            activo ? Color.cyOro.opacity(0.7) : Color.cyApagado.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!activo)
            }
        }
        .opacity(activo ? 1 : 0.5)
    }

    private var bloqueDeDon: some View {
        bloque("Don de vocación") {
            VStack(alignment: .leading, spacing: 3) {
                Text(state.vocacion.don.nombre)
                    .font(.cyDisplay(13, weight: .semibold))
                    .foregroundStyle(Color.cyGranate)
                Text(state.vocacion.don.descripcion)
                    .font(.cyBody(11.5).italic())
                    .foregroundStyle(Color.cyTintaSuave)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var bloqueDePalabrasClave: some View {
        bloque("Palabras clave", nota: "\(state.flags.count)") {
            if state.flags.isEmpty {
                Text("Todavía no has desbloqueado ninguna.")
                    .font(.cyBody(12).italic())
                    .foregroundStyle(Color.cyTintaTenue)
            } else {
                NubeDeFlags(flags: state.flags.sorted(), tamano: 9.5)
            }
        }
    }

    private var pie: some View {
        let delLibro = SagaLibrary.shared.endings(in: state.libroActual).count
        let vistos = state.finalesVistos.filter { state.libroActual.contains($0) }.count
        return VStack(spacing: 8) {
            FileteOrnamental(ancho: 44, color: .cyOro.opacity(0.7))
            HStack {
                Text("\(state.visitadas.count) secciones leídas")
                    .font(.cyBody(11.5))
                    .foregroundStyle(Color.cyTintaTenue)
                Spacer(minLength: 0)
                Text("\(vistos) de \(delLibro) finales")
                    .font(.cyBody(11.5).italic())
                    .foregroundStyle(Color.cyTintaTenue)
            }
        }
    }

    private func bloque<C: View>(_ titulo: String, nota: String? = nil,
                                 @ViewBuilder contenido: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Versal(texto: titulo, tamano: 9.5)
                Rectangle().fill(Color.cyOro.opacity(0.4)).frame(height: 1)
                if let nota {
                    Text(nota)
                        .font(.cyBody(10.5).italic())
                        .foregroundStyle(Color.cyTintaTenue)
                        .fixedSize()
                }
            }
            contenido()
        }
        .padding(.top, 22)
    }
}
