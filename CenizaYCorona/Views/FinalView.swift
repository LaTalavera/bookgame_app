import SwiftUI

struct FinalView: View {
    let state: GameState
    let section: Section

    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var esAncha: Bool { sizeClass == .regular }
    private var anchoMaximo: CGFloat { esAncha ? 600 : .infinity }

    private var esCaida: Bool { section.id % 1000 == 900 }
    private var esCorrupcion: Bool { section.id % 1000 == 950 }

    var body: some View {
        ZStack {
            Ceniza()

            Rectangle()
                .stroke(Color.cyOro.opacity(0.45), lineWidth: 1)
                .overlay(EsquinasOrnamentales(brazo: 18).stroke(Color.cyOro, lineWidth: 1.2))
                .overlay(FloronesEsquina(tamano: 10, margen: 9).fill(Color.cyOro.opacity(0.5)))
                .padding(12)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        Versal(texto: "§\(section.id)", tamano: 9.5, color: .cyOro.opacity(0.6))
                            .padding(.top, 30)

                        sigilo.padding(.top, 16)

                        Versal(texto: rotulo, tamano: 9.5, color: .cyOro)
                            .padding(.top, 16)

                        Text(tituloLimpio)
                            .font(.cyDisplay(esAncha ? 32 : 27, weight: .semibold))
                            .foregroundStyle(Color.cyPergaminoCla)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.6), radius: 16, y: 2)
                            .padding(.top, 9)
                            .fixedSize(horizontal: false, vertical: true)

                        FileteOrnamental(ancho: 62).padding(.top, 16)

                        VStack(alignment: .leading, spacing: 13) {
                            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, parrafo in
                                Text(TextoDelLibro.atribuido(parrafo,
                                                             tamano: esAncha ? 16.5 : 15.5,
                                                             color: Color.cyPergaminoCla.opacity(0.86),
                                                             cursiva: true))
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)

                        sello.padding(.top, 24)
                        epilogo
                        contadorDeFinales.padding(.top, 22)
                        Color.clear.frame(height: 28)
                    }
                    .padding(.horizontal, 30)
                    .frame(maxWidth: anchoMaximo)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)

                acciones
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                    .frame(maxWidth: anchoMaximo)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // ── Piezas ──────────────────────────────────────────────────────────────

    /// Lo que dejaste por el camino y que no cambia ningún número: las
    /// palabras clave que te llevas, leídas como cierre.
    @ViewBuilder
    private var epilogo: some View {
        let lineas = Epilogo.para(state.flags)
        if !lineas.isEmpty {
            VStack(alignment: .leading, spacing: 11) {
                Versal(texto: "Lo que queda de ti", tamano: 9, color: .cyOro.opacity(0.7))
                ForEach(Array(lineas.enumerated()), id: \.offset) { _, linea in
                    Text(linea)
                        .font(.system(size: esAncha ? 14.5 : 13.5, design: .serif))
                        .italic()
                        .foregroundStyle(Color.cyPergaminoCla.opacity(0.72))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)
        }
    }

    private var rotulo: String {
        if esCaida { return "Has caído" }
        if esCorrupcion { return "La ceniza te ha cobrado" }
        return "Final alcanzado"
    }

    /// Los títulos vienen como "FINAL 4 — Una promesa cumplida".
    private var tituloLimpio: String {
        guard let raya = section.title.range(of: "—") else { return section.title }
        return String(section.title[raya.upperBound...]).trimmingCharacters(in: .whitespaces)
    }

    private var sigilo: some View {
        ZStack {
            Circle().stroke(Color.cyOro.opacity(0.4), lineWidth: 1)
            Circle().stroke(Color.cyOro.opacity(0.25), lineWidth: 0.7).padding(5)
            CoronaRota()
                .stroke(Color.cyOro, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                .frame(width: 30, height: 24)
            Rectangle()
                .fill(Color.cyGranateCla)
                .frame(width: 1.4, height: 11)
                .offset(y: 6)
        }
        .frame(width: 64, height: 64)
    }

    private var sello: some View {
        HStack(spacing: 8) {
            datoDelSello("Libro", state.libroActual.numeral)
            datoDelSello("Corrupción", "\(state.corrupcion)/\(Reglas.corrupcionMaxima)")
            datoDelSello("Secciones", "\(state.visitadas.count)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.cyGranate.opacity(0.16))
        .marcoOrnamental(color: .cyOro, opacidadLinea: 0.5)
    }

    private func datoDelSello(_ titulo: String, _ valor: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Versal(texto: titulo, tamano: 7.5, color: .cyOro.opacity(0.85))
            Text(valor)
                .font(.cyDisplay(14, weight: .regular))
                .foregroundStyle(esCorrupcion && titulo == "Corrupción"
                                 ? Color(red: 201/255, green: 169/255, blue: 214/255)
                                 : Color.cyPergaminoCla)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var contadorDeFinales: some View {
        let delLibro = SagaLibrary.shared.endings(in: state.libroActual)
        let vistos = SaveStore.shared.finalesDescubiertos.union(state.finalesVistos)
            .filter { state.libroActual.contains($0) }
        return VStack(spacing: 7) {
            HStack(spacing: 9) {
                Versal(texto: "Finales", tamano: 8.5, color: .cyOro.opacity(0.9))
                HStack(spacing: 6) {
                    ForEach(delLibro) { final in
                        Rombo(lleno: vistos.contains(final.id), tamano: 9, color: .cyOro)
                    }
                }
                Text("\(vistos.count) / \(delLibro.count)")
                    .font(.cyBody(11.5))
                    .foregroundStyle(Color.cyPergaminoCla.opacity(0.65))
            }
            Text("Los demás finales solo se alcanzan jugando: ningún menú los abre.")
                .font(.cyBody(11.5).italic())
                .foregroundStyle(Color.cyPergaminoCla.opacity(0.5))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var acciones: some View {
        VStack(spacing: 9) {
            if let siguiente = state.siguienteLibro {
                Button {
                    state.continuarAlSiguienteLibro()
                    router.combate = nil
                    SaveStore.shared.guardar(state)
                } label: {
                    Text("Continuar al Libro \(siguiente.numeral)".uppercased())
                        .font(.cyDisplay(13, weight: .bold))
                        .tracking(2.6)
                        .foregroundStyle(Color(red: 42/255, green: 19/255, blue: 15/255))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 54)
                        .background(
                            LinearGradient(colors: [Color(red: 217/255, green: 185/255, blue: 104/255),
                                                    Color(red: 158/255, green: 123/255, blue: 46/255)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .overlay(Rectangle().stroke(Color.cyOroClaro, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Button {
                router.volverALaBiblioteca()
            } label: {
                Text("Volver a la biblioteca".uppercased())
                    .font(.cyDisplay(11, weight: .semibold))
                    .tracking(1.9)
                    .foregroundStyle(Color.cyOro)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .overlay(Rectangle().stroke(Color.cyOro.opacity(0.55), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}
