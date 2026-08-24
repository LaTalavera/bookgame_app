import SwiftUI

/// Pantalla de reparto al cruzar a un libro nuevo (Libro I→II→III). Solo
/// aparece cuando `state.nivelPendiente` es cierto, y bloquea la lectura
/// hasta que se reparten los puntos — ver `GameState.subirDeNivel`.
struct SubidaDeNivelView: View {
    let state: GameState

    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var reparto: [Atributo: Int] = [.fue: 0, .agi: 0, .vol: 0]

    private var gastados: Int { reparto.values.reduce(0, +) }
    private var restantes: Int { Reglas.puntosPorNivel - gastados }
    private var anchoMaximo: CGFloat { sizeClass == .regular ? 560 : .infinity }

    var body: some View {
        ZStack {
            Pergamino()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        cabecera
                        VStack(spacing: 10) {
                            ForEach(Atributo.allCases) { atributo in
                                filaDeReparto(atributo)
                            }
                        }
                        .padding(.top, 22)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: anchoMaximo)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)

                pie
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .frame(maxWidth: anchoMaximo)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var cabecera: some View {
        VStack(spacing: 12) {
            Versal(texto: "Libro \(state.libroActual.numeral)", tamano: 9.5, color: .cyGranate)
                .padding(.top, 30)
            Text("Subes a nivel \(state.libroActual.rawValue)")
                .font(.cyDisplay(26, weight: .semibold))
                .foregroundStyle(Color.cyTinta)
                .multilineTextAlignment(.center)
            FileteOrnamental(ancho: 62)
            Text("Reparte \(Reglas.puntosPorNivel) puntos entre tus atributos. Se suman a los que ya tienes, sin tope.")
                .font(.cyBody(13.5).italic())
                .foregroundStyle(Color.cyTintaSuave)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(textoDePuntos)
                .font(.cyBody(11.5).italic())
                .foregroundStyle(restantes == 0 ? Color.cyTintaTenue : Color.cyGranate)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
    }

    private func filaDeReparto(_ atributo: Atributo) -> some View {
        let extra = reparto[atributo] ?? 0
        let base = state.atributo(atributo)
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

            paso(simbolo: "plus", activo: restantes > 0) {
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

    private var pie: some View {
        BotonPrimario(titulo: "Confirmar", habilitado: restantes == 0) {
            state.subirDeNivel(reparto: reparto)
            SaveStore.shared.guardar(state)
        }
    }
}
