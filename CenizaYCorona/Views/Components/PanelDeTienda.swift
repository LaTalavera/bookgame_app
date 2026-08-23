import SwiftUI

/// La armería de §72/§73 y los intendentes de §2103. Comprar y, en §72,
/// entregar objetos de información a cambio de fondos.
struct PanelDeTienda: View {
    let state: GameState
    let tienda: Tienda
    let esAncha: Bool

    @State private var refresco = 0

    private var bolsa: Int { state.monedas(tienda.moneda) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cabecera

            if let nota = tienda.nota {
                Text(nota)
                    .font(.cyBody(12).italic())
                    .foregroundStyle(Color.cyTintaSuave)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }

            if !ventasDisponibles.isEmpty {
                Versal(texto: "Entregar a cambio de fondos", tamano: 8.5)
                    .padding(.top, 16)
                VStack(spacing: 8) {
                    ForEach(ventasDisponibles) { venta in
                        fila(titulo: venta.nombre,
                             detalle: "Su valor de información es mayor que el de venderlo.",
                             precio: "+\(tienda.moneda.contar(venta.importe))",
                             activo: true, accion: "Entregar") {
                            state.vender(venta, en: tienda)
                            SaveStore.shared.guardar(state)
                            refresco += 1
                        }
                    }
                }
                .padding(.top, 8)
            }

            if !tienda.articulos.isEmpty {
                Versal(texto: "Catálogo", tamano: 8.5)
                    .padding(.top, 16)
                VStack(spacing: 8) {
                    ForEach(tienda.articulos) { articulo in
                        articuloFila(articulo)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
        .background(Color.cyPergaminoCla.opacity(0.42))
        .marcoOrnamental(opacidadLinea: 0.6)
        .id(refresco)
    }

    private var ventasDisponibles: [Venta] {
        tienda.ventas.filter { state.puedeVender($0) }
    }

    private var cabecera: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Versal(texto: tienda.titulo, tamano: 9)
            Rectangle().fill(Color.cyOro.opacity(0.45)).frame(height: 1)
            Text(tienda.moneda.contar(bolsa))
                .font(.cyDisplay(13, weight: .semibold))
                .foregroundStyle(Color.cyGranate)
                .fixedSize()
        }
    }

    private func articuloFila(_ articulo: Articulo) -> some View {
        let puede = state.puedeComprar(articulo, en: tienda)
        let motivo: String? = {
            if state.yaComprado(articulo) { return "ya lo llevas" }
            if !state.cumpleRequisito(articulo), let r = articulo.requiere {
                return "requiere \(r.atributo.sigla) \(r.minimo)+"
            }
            if bolsa < articulo.precio { return "no te llega" }
            if case .objeto = articulo.mercancia, state.espaciosLibres == 0 { return "mochila llena" }
            return nil
        }()
        return fila(titulo: articulo.nombre,
                    detalle: articulo.detalle,
                    precio: tienda.moneda.contar(articulo.precio),
                    activo: puede, accion: "Comprar", motivo: motivo) {
            state.comprar(articulo, en: tienda)
            SaveStore.shared.guardar(state)
            refresco += 1
        }
    }

    private func fila(titulo: String, detalle: String, precio: String,
                      activo: Bool, accion: String, motivo: String? = nil,
                      pulsar: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.cyDisplay(12.5, weight: .regular))
                    .foregroundStyle(Color.cyTinta)
                if !detalle.isEmpty {
                    Text(detalle)
                        .font(.cyBody(11).italic())
                        .foregroundStyle(Color.cyTintaTenue)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let motivo {
                    Text(motivo)
                        .font(.cyBody(10.5))
                        .foregroundStyle(Color.cyApagado)
                }
            }
            Spacer(minLength: 6)
            VStack(spacing: 3) {
                Text(precio)
                    .font(.cyBody(10.5))
                    .foregroundStyle(Color.cyOroOscuro)
                    .fixedSize()
                Button(action: pulsar) {
                    Versal(texto: accion, tamano: 9, color: activo ? .cyGranate : .cyApagado)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .overlay(Rectangle().stroke(
                            activo ? Color.cyOro.opacity(0.7) : Color.cyApagado.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!activo)
            }
        }
        .opacity(activo ? 1 : 0.55)
    }
}
