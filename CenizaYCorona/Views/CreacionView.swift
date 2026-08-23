import SwiftUI

struct CreacionView: View {
    let scope: PlayScope

    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var sizeClass
    @FocusState private var nombreEnfocado: Bool

    @State private var nombre: String = ""
    @State private var vocacion: Vocacion = .cuchilla
    @State private var reparto: [Atributo: Int] = [.fue: 0, .agi: 0, .vol: 0]

    private var gastados: Int { reparto.values.reduce(0, +) }
    private var restantes: Int { Reglas.puntosDePersonalizacion - gastados }
    private var anchoMaximo: CGFloat { sizeClass == .regular ? 640 : .infinity }

    var body: some View {
        ZStack {
            Pergamino()

            VStack(spacing: 0) {
                barraSuperior

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        cabecera
                        campoDeNombre
                        seccion("Vocación")
                        VStack(spacing: 10) {
                            ForEach(Vocacion.allCases) { candidata in
                                tarjetaDeVocacion(candidata)
                            }
                        }
                        seccionDeReparto
                        VStack(spacing: 10) {
                            ForEach(Atributo.allCases) { atributo in
                                filaDeReparto(atributo)
                            }
                        }
                        resumen.padding(.top, 22).padding(.bottom, 26)
                    }
                    .padding(.horizontal, 18)
                    .frame(maxWidth: anchoMaximo)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)

                pieDeAccion
            }
        }
        .onTapGesture { nombreEnfocado = false }
    }

    // ── Cromo ───────────────────────────────────────────────────────────────

    private var barraSuperior: some View {
        HStack(spacing: 0) {
            Button { router.pantalla = .biblioteca } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.cyGranate)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            Versal(texto: "Crear personaje", tamano: 11.5, color: .cyGranate)
                .frame(maxWidth: .infinity)
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(Color.cyPergaminoCla.opacity(0.4))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.cyOro.opacity(0.55)).frame(height: 1)
        }
    }

    private var cabecera: some View {
        VStack(spacing: 12) {
            Text("Eres un Marcado de Valcenar: has crecido con la cicatriz de cristal en la piel.")
                .font(.cyBody(13.5).italic())
                .foregroundStyle(Color.cyTintaSuave)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            FileteOrnamental(ancho: 70)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 18)
    }

    private var campoDeNombre: some View {
        VStack(alignment: .leading, spacing: 8) {
            Versal(texto: "Nombre", tamano: 9.5)
            HStack(spacing: 10) {
                TextField("", text: $nombre, prompt:
                            Text("Marcado de Valcenar")
                                .font(.cyDisplay(17, weight: .regular))
                                .foregroundColor(Color.cyTintaTenue.opacity(0.6)))
                    .font(.cyDisplay(17, weight: .regular))
                    .foregroundStyle(Color.cyTinta)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($nombreEnfocado)
                    .submitLabel(.done)
                Image(systemName: "pencil.line")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.cyOroOscuro)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.cyPergaminoCla.opacity(0.62))
            .marcoOrnamental(opacidadLinea: 0.6)
        }
    }

    private func seccion(_ titulo: String) -> some View {
        HStack(spacing: 9) {
            Versal(texto: titulo, tamano: 9.5)
            Rectangle().fill(Color.cyOro.opacity(0.4)).frame(height: 1)
        }
        .padding(.top, 22)
        .padding(.bottom, 10)
    }

    private var seccionDeReparto: some View {
        HStack(spacing: 9) {
            Versal(texto: "Personalización", tamano: 9.5)
            Rectangle().fill(Color.cyOro.opacity(0.4)).frame(height: 1)
            Text(textoDePuntos)
                .font(.cyBody(11.5).italic())
                .foregroundStyle(restantes == 0 ? Color.cyTintaTenue : Color.cyGranate)
                .fixedSize()
        }
        .padding(.top, 22)
        .padding(.bottom, 10)
    }

    // ── Vocación ────────────────────────────────────────────────────────────

    private func tarjetaDeVocacion(_ candidata: Vocacion) -> some View {
        let elegida = candidata == vocacion
        return Button { vocacion = candidata } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(candidata.nombre)
                        .font(.cyDisplay(15, weight: .semibold))
                        .foregroundStyle(elegida ? Color.cyGranate : Color.cyTinta)
                    Text("(\(candidata.arquetipo))")
                        .font(.cyBody(11).italic())
                        .foregroundStyle(Color.cyTintaTenue)
                    Spacer(minLength: 0)
                    ZStack {
                        Circle().stroke(Color.cyOro.opacity(elegida ? 1 : 0.6), lineWidth: 1.2)
                        if elegida {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.cyGranate)
                        }
                    }
                    .frame(width: 19, height: 19)
                }

                Text(candidata.presentacion)
                    .font(.cyBody(12.5).italic())
                    .foregroundStyle(Color.cyTintaSuave)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 14) {
                    dato(candidata.resumenDeAtributos)
                    Spacer(minLength: 0)
                }

                HStack(spacing: 14) {
                    dato("Vida \(candidata.vidaInicial)")
                    if candidata.ecosIniciales > 0 { dato("Ecos \(candidata.ecosIniciales)") }
                    dato("Defensa \(candidata.defensaInicial)")
                    Spacer(minLength: 0)
                }

                if elegida {
                    VStack(alignment: .leading, spacing: 5) {
                        Rectangle().fill(Color.cyOro.opacity(0.35)).frame(height: 1)
                        etiqueta("Equipo", equipoDe(candidata))
                        etiqueta("Don · \(candidata.don.nombre)", candidata.don.descripcion)
                        if !candidata.hechizos.isEmpty {
                            etiqueta("Hechizos", candidata.hechizos.map(\.nombre).joined(separator: ", "))
                        }
                    }
                    .padding(.top, 3)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(elegida ? Color.cyGranate.opacity(0.09) : Color.cyPergaminoCla.opacity(0.32))
            .overlay(alignment: .leading) {
                if elegida { Rectangle().fill(Color.cyGranate).frame(width: 3) }
            }
            .marcoOrnamental(opacidadLinea: elegida ? 1 : 0.4, conFlorones: elegida)
        }
        .buttonStyle(.plain)
    }

    private func equipoDe(_ v: Vocacion) -> String {
        var piezas = ["\(v.arma.nombre) (Daño \(v.arma.dano))"]
        if let secundaria = v.armaSecundaria { piezas.append(secundaria.nombre) }
        if v.escudo { piezas.append("escudo (+1 Def)") }
        if v.armadura.bonoDefensa > 0 {
            piezas.append("\(v.armadura.nombre) (+\(v.armadura.bonoDefensa) Def)")
        }
        piezas.append(contentsOf: v.mochilaInicial.map(\.nombre))
        return piezas.joined(separator: " · ")
    }

    private func dato(_ texto: String) -> some View {
        Text(texto)
            .font(.cyDisplay(11.5, weight: .regular))
            .tracking(0.6)
            .foregroundStyle(Color.cyOroOscuro)
    }

    private func etiqueta(_ titulo: String, _ cuerpo: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Versal(texto: titulo, tamano: 8)
            Text(cuerpo)
                .font(.cyBody(11.5))
                .foregroundStyle(Color.cyTintaSuave)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // ── Reparto ─────────────────────────────────────────────────────────────

    private func filaDeReparto(_ atributo: Atributo) -> some View {
        let extra = reparto[atributo] ?? 0
        let base = vocacion.atributos[atributo] ?? 0
        return HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(atributo.sigla) · \(atributo.nombre)")
                    .font(.cyDisplay(12.5, weight: .regular))
                    .foregroundStyle(Color.cyTinta)
                Text(atributo.descripcion)
                    .font(.cyBody(10.5).italic())
                    .foregroundStyle(Color.cyTintaTenue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            paso(simbolo: "minus", activo: extra > 0) {
                reparto[atributo] = extra - 1
            }

            HStack(spacing: 3) {
                Text("\(base + extra)")
                    .font(.cyDisplay(20, weight: .semibold))
                    .foregroundStyle(Color.cyGranate)
                if extra > 0 {
                    Text("+\(extra)")
                        .font(.cyBody(11))
                        .foregroundStyle(Color.cyOroOscuro)
                }
            }
            .frame(width: 56)

            paso(simbolo: "plus", activo: restantes > 0 && extra < Reglas.maximoPorAtributo) {
                reparto[atributo] = extra + 1
            }
        }
        .frame(height: 52)
    }

    private func paso(simbolo: String, activo: Bool, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            Image(systemName: simbolo)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.cyGranate)
                .frame(width: 44, height: 44)
                .background(Color.cyPergaminoCla.opacity(activo ? 0.5 : 0.25))
                .overlay(Rectangle().stroke(Color.cyOro.opacity(activo ? 0.8 : 0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!activo)
        .opacity(activo ? 1 : 0.45)
    }

    private var textoDePuntos: String {
        switch restantes {
        case 0: return "sin puntos"
        case 1: return "queda 1 punto"
        default: return "quedan \(restantes) puntos"
        }
    }

    // ── Resumen ─────────────────────────────────────────────────────────────

    private var resumen: some View {
        let volExtra = reparto[.vol] ?? 0
        return HStack(spacing: 0) {
            resumenDato("Vida", "\(vocacion.vidaInicial + volExtra)")
            resumenDato("Ecos", "\(vocacion.ecosIniciales)")
            resumenDato("Defensa", "\(vocacion.defensaInicial)")
            resumenDato("Daño", "\(vocacion.arma.dano)")
        }
        .padding(.vertical, 13)
        .background(Color.cyPergaminoOsc.opacity(0.4))
        .marcoOrnamental(opacidadLinea: 0.55)
    }

    private func resumenDato(_ titulo: String, _ valor: String) -> some View {
        VStack(spacing: 4) {
            Versal(texto: titulo, tamano: 8)
            Text(valor)
                .font(.cyDisplay(20, weight: .semibold))
                .foregroundStyle(Color.cyGranate)
        }
        .frame(maxWidth: .infinity)
    }

    private var pieDeAccion: some View {
        VStack(spacing: 10) {
            BotonPrimario(titulo: "Comenzar · §\(scope.startBook.startSection)") {
                let state = GameState(nombre: nombre.trimmingCharacters(in: .whitespaces),
                                      vocacion: vocacion, reparto: reparto, scope: scope)
                router.jugar(state)
            }
            Text("Pruebas de 2D6 + atributo — Fácil 7 · Media 9 · Difícil 11 · Heroica 13")
                .font(.cyBody(11.5).italic())
                .foregroundStyle(Color.cyTintaTenue)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .frame(maxWidth: anchoMaximo)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color.cyPergamino.opacity(0),
                                    Color(red: 231/255, green: 218/255, blue: 188/255)],
                           startPoint: .top, endPoint: .bottom)
        )
    }
}
