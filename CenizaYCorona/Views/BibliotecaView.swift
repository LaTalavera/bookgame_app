import SwiftUI
import UniformTypeIdentifiers

struct BibliotecaView: View {
    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var recargar = 0
    @State private var importando = false
    @State private var mensajeDeImportacion: String?
    @State private var scopePendiente: PlayScope?
    @State private var confirmandoSustitucion = false

    private var esAncha: Bool { sizeClass == .regular }
    private var anchoMaximo: CGFloat { esAncha ? 720 : .infinity }

    var body: some View {
        ZStack {
            Pergamino()

            ScrollView {
                VStack(spacing: 0) {
                    portada
                    VStack(spacing: 0) {
                        if let error = SagaLibrary.shared.loadError {
                            avisoDeError(error)
                        }
                        encabezado("Tus crónicas guardadas")
                        VStack(spacing: 9) {
                            ForEach(0..<SaveStore.numeroDeRanuras, id: \.self) { indice in
                                tarjetaDeRanura(indice)
                            }
                        }
                        BotonSecundario(titulo: "Importar una partida", alto: 44) {
                            importando = true
                        }
                        .padding(.top, 10)

                        encabezado("Nueva crónica")
                        VStack(spacing: 10) {
                            ForEach(BookID.allCases) { libro in
                                tarjetaDeLibro(libro)
                            }
                        }
                        tarjetaDeSaga
                            .padding(.top, 14)
                        pieDeFinales
                            .padding(.top, 22)
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 18)
                    .frame(maxWidth: anchoMaximo)
                    .frame(maxWidth: .infinity)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .id(recargar)
        .fileImporter(isPresented: $importando, allowedContentTypes: [.json]) { resultado in
            do {
                let url = try resultado.get()
                let indice = try SaveStore.shared.importar(desde: url)
                recargar += 1
                mensajeDeImportacion = "Partida importada en la ranura \(indice + 1)."
            } catch {
                mensajeDeImportacion = "El archivo no contiene una partida válida."
            }
        }
        .alert("Importación", isPresented: Binding(
            get: { mensajeDeImportacion != nil },
            set: { if !$0 { mensajeDeImportacion = nil } }
        )) {
            Button("Aceptar", role: .cancel) { mensajeDeImportacion = nil }
        } message: {
            Text(mensajeDeImportacion ?? "")
        }
        .alert("Las tres ranuras están ocupadas", isPresented: $confirmandoSustitucion) {
            Button("Cancelar", role: .cancel) { scopePendiente = nil }
            Button("Sustituir la más antigua", role: .destructive) {
                if let scope = scopePendiente { router.empezar(scope) }
                scopePendiente = nil
            }
        } message: {
            Text("La nueva crónica reemplazará la partida guardada más antigua cuando completes la creación del personaje.")
        }
    }

    // ── Portada ─────────────────────────────────────────────────────────────

    private var portada: some View {
        ZStack(alignment: .bottom) {
            Image("Portada")
                .resizable()
                .scaledToFill()
                .frame(height: esAncha ? 420 : 316)
                .clipped()

            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.58), location: 0),
                    .init(color: Color.black.opacity(0.12), location: 0.34),
                    .init(color: Color.cyGranateOsc.opacity(0.58), location: 0.74),
                    .init(color: Color.cyPergamino, location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: esAncha ? 420 : 316)

            VStack(spacing: 9) {
                Versal(texto: "Librojuego", tamano: 10, color: .cyOro)
                Text("Ceniza\ny Corona")
                    .font(.cyDisplay(esAncha ? 40 : 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.cyPergaminoCla)
                    .shadow(color: .black.opacity(0.75), radius: 14, y: 2)
                FileteOrnamental(ancho: 58)
                Text("Tres libros. Una sola ceniza.")
                    .font(.cyBody(13).italic())
                    .foregroundStyle(Color.cyPergaminoCla.opacity(0.8))
            }
            .padding(.bottom, 22)
        }
        .frame(height: esAncha ? 420 : 316)
        .clipped()
    }

    // ── Piezas ──────────────────────────────────────────────────────────────

    private func encabezado(_ titulo: String) -> some View {
        HStack(spacing: 10) {
            Versal(texto: titulo, tamano: 10)
            Rectangle().fill(Color.cyOro.opacity(0.5)).frame(height: 1)
        }
        .padding(.top, 16)
        .padding(.bottom, 13)
    }

    private func avisoDeError(_ error: String) -> some View {
        Text(error)
            .font(.cyBody(13).italic())
            .foregroundStyle(Color.cyGranate)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.cyGranate.opacity(0.08))
            .marcoOrnamental(color: .cyGranate, opacidadLinea: 0.4, conFlorones: false)
            .padding(.top, 16)
    }

    private func tarjetaDeRanura(_ indice: Int) -> some View {
        let partida = SaveStore.shared.ranuras[indice]
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Versal(texto: "Ranura \(indice + 1)", tamano: 8.5)
                if let partida {
                    Text(partida.nombre)
                        .font(.cyDisplay(14, weight: .semibold))
                        .foregroundStyle(Color.cyGranate)
                    Text("\(partida.vocacion.nombre) · §\(partida.seccionActual) · Vida \(partida.vida)/\(partida.vidaMaxima)")
                        .font(.cyBody(10.5).italic())
                        .foregroundStyle(Color.cyTintaSuave)
                } else {
                    Text("Esta ranura espera una nueva historia.")
                        .font(.cyBody(11.5).italic())
                        .foregroundStyle(Color.cyTintaTenue)
                }
            }
            Spacer(minLength: 6)
            if partida != nil {
                Button { router.continuar(ranura: indice) } label: {
                    Image(systemName: "play.fill")
                        .foregroundStyle(Color.cyGranate)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                if let url = try? SaveStore.shared.urlDeExportacion(ranura: indice) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.cyOroOscuro)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(Color.cyPergaminoCla.opacity(partida == nil ? 0.28 : 0.52))
        .marcoOrnamental(opacidadLinea: partida == nil ? 0.34 : 0.58, conFlorones: false)
        .contextMenu {
            if partida != nil {
                Button("Continuar") { router.continuar(ranura: indice) }
                Button("Borrar partida", role: .destructive) {
                    SaveStore.shared.borrar(ranura: indice)
                    recargar += 1
                }
            }
        }
    }

    private func tarjetaDeLibro(_ libro: BookID) -> some View {
        let scope = PlayScope.book(libro)
        let guardada = SaveStore.shared.partida(de: scope)
        let total = SagaLibrary.shared.ids(in: libro).count

        return Button {
            nuevaCronica(scope)
        } label: {
            HStack(spacing: 13) {
                SigiloDeLibro(libro: libro)
                    .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(libro.numeral) · \(libro.title.uppercased())")
                        .font(.cyDisplay(12.5, weight: .semibold))
                        .tracking(0.9)
                        .foregroundStyle(Color.cyGranate)
                    Text(libro.tagline)
                        .font(.cyBody(12.5).italic())
                        .foregroundStyle(Color.cyTintaSuave)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let guardada {
                        HStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle().fill(Color.cyGranate.opacity(0.15))
                                    Rectangle().fill(Color.cyGranate)
                                        .frame(width: geo.size.width * guardada.progreso)
                                }
                            }
                            .frame(height: 3)
                            Text("§\(guardada.seccionActual) · \(Int(guardada.progreso * 100))%")
                                .font(.cyBody(10.5))
                                .foregroundStyle(Color.cyOroOscuro)
                                .fixedSize()
                        }
                        .padding(.top, 5)
                    } else {
                        Text("Sin comenzar · \(total) secciones")
                            .font(.cyBody(10.5))
                            .foregroundStyle(Color.cyOroOscuro)
                            .padding(.top, 5)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cyPergaminoCla.opacity(guardada != nil ? 0.58 : 0.34))
            .marcoOrnamental(opacidadLinea: guardada != nil ? 0.6 : 0.42)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if guardada != nil {
                Button("Continuar §\(guardada!.seccionActual)") { router.continuar(scope) }
                Button("Empezar de nuevo", role: .destructive) {
                    SaveStore.shared.borrar(scope: scope)
                    router.empezar(scope)
                }
            }
        }
    }

    private var tarjetaDeSaga: some View {
        let scope = PlayScope.saga
        let guardada = SaveStore.shared.partida(de: scope)

        return Button {
            nuevaCronica(scope)
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Versal(texto: "Saga completa", tamano: 12.5, color: .cyOroClaro)
                    Rectangle().fill(Color.cyOro.opacity(0.35)).frame(height: 1)
                    Text("\(SagaLibrary.shared.sections.count) §")
                        .font(.cyBody(10.5))
                        .foregroundStyle(Color.cyPergamino.opacity(0.6))
                        .fixedSize()
                }
                Text("Los tres libros encadenados: la Corrupción, el Vínculo y tus palabras clave cruzan de uno a otro.")
                    .font(.cyBody(12.5).italic())
                    .foregroundStyle(Color.cyPergaminoCla.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
                if let guardada {
                    Text("Continuar · Libro \(BookID.containing(guardada.seccionActual).numeral) · §\(guardada.seccionActual)")
                        .font(.cyBody(11))
                        .foregroundStyle(Color.cyOroClaro)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [Color.cyGranate, Color(red: 63/255, green: 11/255, blue: 21/255)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .marcoOrnamental(color: .cyOro, opacidadLinea: 1)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if guardada != nil {
                Button("Empezar de nuevo", role: .destructive) {
                    SaveStore.shared.borrar(scope: scope)
                    router.empezar(scope)
                }
            }
        }
    }

    private var pieDeFinales: some View {
        let vistos = SaveStore.shared.finalesDescubiertos.count
        let total = BookID.allCases.reduce(0) { $0 + SagaLibrary.shared.endings(in: $1).count }
        return VStack(spacing: 8) {
            FileteOrnamental(ancho: 44, color: .cyOro.opacity(0.7))
            Text("\(vistos) de \(total) finales descubiertos")
                .font(.cyBody(12))
                .foregroundStyle(Color.cyTintaTenue)
            Text("Ningún menú los abre: solo se alcanzan jugando.")
                .font(.cyBody(11).italic())
                .foregroundStyle(Color.cyTintaTenue.opacity(0.8))
        }
    }

    private func nuevaCronica(_ scope: PlayScope) {
        if SaveStore.shared.ranuras.allSatisfy({ $0 != nil }) {
            scopePendiente = scope
            confirmandoSustitucion = true
        } else {
            router.empezar(scope)
        }
    }
}

/// El sello de cada libro: marca rota, corona rota, cadena rota.
struct SigiloDeLibro: View {
    let libro: BookID

    var body: some View {
        ZStack {
            Circle().stroke(Color.cyOro, lineWidth: 1)
            Group {
                switch libro {
                case .primero:
                    ZStack {
                        Circle()
                            .trim(from: 0.08, to: 0.92)
                            .stroke(Color.cyGranate, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                            .frame(width: 22, height: 22)
                        Rectangle()
                            .fill(Color.cyOro)
                            .frame(width: 1.6, height: 20)
                            .rotationEffect(.degrees(45))
                    }
                case .segundo:
                    CoronaRota().stroke(Color.cyGranate,
                                        style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                        .frame(width: 24, height: 20)
                case .tercero:
                    CadenaRota().stroke(Color.cyGranate,
                                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .frame(width: 26, height: 14)
                }
            }
        }
    }
}

struct CoronaRota: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.minX + w * 0.04, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.10))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.30, y: rect.minY + h * 0.48))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.70, y: rect.minY + h * 0.48))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.10))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.04, y: rect.maxY))
        return p
    }
}

struct CadenaRota: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY,
                                    width: w * 0.46, height: h),
                         cornerSize: CGSize(width: h / 2, height: h / 2))
        p.move(to: CGPoint(x: rect.minX + w * 0.58, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.78, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.minX + w * 0.78, y: rect.midY),
                 radius: h / 2, startAngle: .degrees(-90), endAngle: .degrees(90),
                 clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + w * 0.66, y: rect.maxY))
        return p
    }
}
