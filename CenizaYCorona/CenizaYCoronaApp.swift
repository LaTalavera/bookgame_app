import SwiftUI
import Observation

@Observable
final class Router {
    enum Pantalla: Hashable {
        case biblioteca
        case creacion(PlayScope)
        case lectura
    }

    var pantalla: Pantalla = .biblioteca
    var game: GameState?
    var combate: CombatSession?

    func empezar(_ scope: PlayScope) {
        SaveStore.shared.prepararNuevaPartida()
        pantalla = .creacion(scope)
    }

    func continuar(_ scope: PlayScope) {
        guard let guardada = SaveStore.shared.partidaConIndice(de: scope) else {
            empezar(scope)
            return
        }
        SaveStore.shared.activar(ranura: guardada.indice)
        let state = guardada.partida.restaurar()
        game = state
        restaurarOabrirCombate(state, snapshot: guardada.partida.combate)
        pantalla = .lectura
    }

    func continuar(ranura: Int) {
        guard SaveStore.shared.ranuras.indices.contains(ranura),
              let partida = SaveStore.shared.ranuras[ranura] else { return }
        SaveStore.shared.activar(ranura: ranura)
        let state = partida.restaurar()
        game = state
        restaurarOabrirCombate(state, snapshot: partida.combate)
        pantalla = .lectura
    }

    func jugar(_ state: GameState) {
        game = state
        state.ir(a: state.seccionActual)
        abrirCombateSiHaceFalta(state)
        SaveStore.shared.guardar(state, combate: combate, conservarCombate: false)
        pantalla = .lectura
    }

    func volverALaBiblioteca() {
        if let game { SaveStore.shared.guardar(game, combate: combate) }
        combate = nil
        game = nil
        pantalla = .biblioteca
    }

    /// Avanza la historia, abre el combate si lo hay y guarda.
    func avanzar(_ state: GameState, a destino: Int, por choice: Choice? = nil) {
        state.ir(a: destino, por: choice)
        combate = nil
        abrirCombateSiHaceFalta(state)
        SaveStore.shared.guardar(state, combate: combate, conservarCombate: false)
    }

    /// Resuelve una tabla de finales (§133, §1145, §2150) y salta al final.
    func resolverTablaDeFinales(_ state: GameState) {
        state.resolverTablaDeFinales()
        combate = nil
        SaveStore.shared.guardar(state)
    }

#if DEBUG
    /// Atajo de desarrollo: lanzar con CYC_SECCION=1143 abre esa sección con un
    /// personaje de prueba, para poder revisar cualquier pantalla sin jugar
    /// hasta ella. Se compila solo en Debug; la app publicada no lo lleva.
    func arranqueDeDesarrollo() {
        let env = ProcessInfo.processInfo.environment
        guard let texto = env["CYC_SECCION"], let id = Int(texto) else { return }

        let vocacion = Vocacion(rawValue: env["CYC_VOCACION"] ?? "") ?? .cuchilla
        let state = GameState(nombre: env["CYC_NOMBRE"] ?? "Wren de Valcenar",
                              vocacion: vocacion,
                              reparto: [.fue: 1, .agi: 1, .vol: 1],
                              scope: .book(BookID.containing(id)))
        for flag in (env["CYC_FLAGS"] ?? "").split(separator: ",") where !flag.isEmpty {
            state.conceder(flag: String(flag))
        }
        for par in (env["CYC_REP"] ?? "").split(separator: ",") {
            let trozos = par.split(separator: ":")
            if trozos.count == 2, let track = RepTrack(rawValue: String(trozos[0])),
               let valor = Int(trozos[1]) {
                state.reputacion[track] = valor
            }
        }
        if let c = env["CYC_CORRUPCION"], let n = Int(c) { state.ganarCorrupcion(n) }
        if let v = env["CYC_VIDA"], let n = Int(v) { state.vida = n }
        state.seccionActual = id
        jugar(state)
    }
#endif

    private func abrirCombateSiHaceFalta(_ state: GameState) {
        guard let section = state.seccion, let datos = section.combat else { return }
        combate = CombatSession(seccionID: section.id, datos: datos)
    }

    private func restaurarOabrirCombate(_ state: GameState, snapshot: CombatSnapshot?) {
        guard let section = state.seccion, let datos = section.combat else {
            combate = nil
            return
        }
        if let snapshot, snapshot.seccionID == section.id {
            combate = CombatSession(snapshot: snapshot, datos: datos)
        } else {
            combate = CombatSession(seccionID: section.id, datos: datos)
        }
    }
}

@main
struct CenizaYCoronaApp: App {
    @State private var router = Router()

    init() {
        TipografiaCeniza.registrar()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .preferredColorScheme(.light)
                .tint(Color.cyGranate)
        }
    }
}

struct RootView: View {
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            switch router.pantalla {
            case .biblioteca:
                BibliotecaView()
            case .creacion(let scope):
                CreacionView(scope: scope)
            case .lectura:
                if let game = router.game {
                    LecturaView(state: game)
                } else {
                    BibliotecaView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: router.pantalla)
#if DEBUG
        .task { router.arranqueDeDesarrollo() }
#endif
    }
}
