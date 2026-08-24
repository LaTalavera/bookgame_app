import Foundation
import Observation

struct Aviso: Identifiable, Hashable {
    enum Tipo: Hashable { case flag, reputacion, corrupcion, vida, ecos, sistema }
    let id = UUID()
    let tipo: Tipo
    let texto: String
}

/// Preparativos gratuitos de un punto de descanso. Nunca cierran una ruta:
/// se gastan cuando realmente ayudan en una prueba o en un combate.
enum PlanDeMarcha: String, Codable, Hashable {
    case vigilancia
    case lectura
    case silencio

    var titulo: String {
        switch self {
        case .vigilancia: return "Vigilar la ruta"
        case .lectura: return "Leer el camino"
        case .silencio: return "Callar la Grieta"
        }
    }

    var efecto: String {
        switch self {
        case .vigilancia: return "El primer ataque enemigo del próximo combate recibe −2."
        case .lectura: return "La próxima prueba con dados recibe +2."
        case .silencio: return "Reduce 1 Corrupción; no podrás elegir preparativo en el siguiente descanso."
        }
    }
}

struct EventoCronica: Identifiable, Codable, Hashable {
    enum Tipo: String, Codable, Hashable {
        case seccion, eleccion, palabra, combate, reputacion, ilustracion
        case libro, sistema, prueba, descanso, objeto, mutacion

        var nombre: String {
            switch self {
            case .seccion: return "Sección"
            case .eleccion: return "Decisión"
            case .palabra: return "Palabra"
            case .combate: return "Combate"
            case .reputacion: return "Reputación"
            case .ilustracion: return "Ilustración"
            case .libro: return "Libro"
            case .sistema: return "Sistema"
            case .prueba: return "Prueba"
            case .descanso: return "Descanso"
            case .objeto: return "Objeto"
            case .mutacion: return "Mutación"
            }
        }
    }

    let id: UUID
    let tipo: Tipo
    let seccion: Int
    let texto: String
    let detalle: String?
    let orden: Int

    init(tipo: Tipo, seccion: Int, texto: String, detalle: String? = nil, orden: Int) {
        id = UUID()
        self.tipo = tipo
        self.seccion = seccion
        self.texto = texto
        self.detalle = detalle
        self.orden = orden
    }
}

@Observable
final class GameState {

    // ── Personaje ───────────────────────────────────────────────────────────
    var nombre: String
    var vocacion: Vocacion
    var atributos: [Atributo: Int]
    /// Sube en el salto de libro (Libro I→II→III); nunca dentro de un mismo
    /// libro. Ver `nivelPendiente` y `subirDeNivel(reparto:)`.
    var nivel: Int = 1

    // ── Recursos ────────────────────────────────────────────────────────────
    var vida: Int
    var vidaMaxima: Int
    var ecos: Int
    var ecosMaximos: Int
    var corrupcion: Int
    /// Se aplica una sola vez al cruzar Corrupción 7 (Parte II, §16).
    var mutacionAplicada: Bool

    // ── Equipo ──────────────────────────────────────────────────────────────
    var arma: Arma
    var armaSecundaria: Arma?
    var armadura: Armadura
    var llevaEscudo: Bool
    var mochila: [ObjetoDeMochila]
    var hechizos: [Hechizo]

    // ── Progreso ────────────────────────────────────────────────────────────
    var reputacion: [RepTrack: Int]
    var flags: Set<String>
    var scope: PlayScope
    var seccionActual: Int
    var visitadas: Set<Int>
    var finalesVistos: Set<Int>
    var historia: [EventoCronica]
    var ilustracionesDescubiertas: Set<Int>
    var avisos: [Aviso]
    var comenzada: Date
    /// El don de vocación se gasta una vez por combate o por acto.
    var donUsadoEnEsteCombate: Bool
    /// Ojo de Vardo se gasta una vez por sección; Voto de Ceniza, una por libro.
    var ojoDeVardoUsadoEnSeccion: Bool = false
    var votoDeCenizaUsadoEnLibro: Bool = false
    /// Monedas de cada tipo (Parte de las tiendas §72/§73 y §2103).
    var monedas: [Moneda: Int] = [:]
    /// Tiendas cuyos fondos ya se han cobrado, para no repartirlos dos veces.
    var tiendasCobradas: Set<Int> = []
    /// Ventas ya realizadas (§72), y usos del amuleto de plomo por libro.
    var ventasHechas: Set<String> = []
    var amuletoGastadoEnLibro: Bool = false
    /// Preparativo que acompaña a la expedición hasta que interviene.
    var planDeMarcha: PlanDeMarcha? = nil
    var esperaDeMarcha: Int = 0
    var descansosDeSilencio: Set<Int> = []
    var penalizacionDeHeridaUsada: Bool = false

    init(nombre: String, vocacion: Vocacion, reparto: [Atributo: Int], scope: PlayScope) {
        self.nombre = nombre.isEmpty ? "Marcado de Valcenar" : nombre
        self.vocacion = vocacion

        var attrs = vocacion.atributos
        for (attr, extra) in reparto { attrs[attr, default: 0] += extra }
        self.atributos = attrs

        // Parte III, §21: +1 VOL sobre la base de la vocación = +1 Vida.
        let volExtra = reparto[.vol] ?? 0
        self.vidaMaxima = vocacion.vidaInicial + volExtra
        self.vida = vocacion.vidaInicial + volExtra
        self.ecosMaximos = vocacion.ecosIniciales
        self.ecos = vocacion.ecosIniciales
        self.corrupcion = 0
        self.mutacionAplicada = false

        self.arma = vocacion.arma
        self.armaSecundaria = vocacion.armaSecundaria
        self.armadura = vocacion.armadura
        self.llevaEscudo = vocacion.escudo
        self.mochila = vocacion.mochilaInicial
        self.hechizos = vocacion.hechizos + vocacion.repertorioCompleto

        var rep: [RepTrack: Int] = [:]
        for track in RepTrack.allCases { rep[track] = 0 }
        self.reputacion = rep
        self.flags = []
        self.scope = scope
        self.seccionActual = scope.startBook.startSection
        self.visitadas = []
        self.finalesVistos = []
        self.historia = []
        self.ilustracionesDescubiertas = []
        self.avisos = []
        self.comenzada = Date()
        self.donUsadoEnEsteCombate = false
    }

    // ── Consultas ───────────────────────────────────────────────────────────

    var libroActual: BookID { BookID.containing(seccionActual) }
    var seccion: Section? { SagaLibrary.shared[seccionActual] }

    func atributo(_ a: Atributo) -> Int { atributos[a] ?? 0 }
    func rep(_ t: RepTrack) -> Int { reputacion[t] ?? 0 }

    /// Quien baja contigo a la Grieta (§2095), si ya lo has elegido.
    var companero: Companero? { Companero.para(flags: flags) }

    /// Parte II, §13: 8 + armadura + escudo, más el compañero si lo cubre.
    var defensa: Int {
        Reglas.defensaBase + armadura.bonoDefensa + (llevaEscudo ? Armadura.escudo.bonoDefensa : 0)
            + (companero?.defensa ?? 0)
    }

    var estadoDeCorrupcion: EstadoDeCorrupcion { EstadoDeCorrupcion.para(corrupcion) }
    var perdido: Bool { corrupcion >= Reglas.corrupcionMaxima }
    var herido: Bool { vida > 0 && vida * 2 <= vidaMaxima }

    /// Los espacios libres de mochila.
    var espaciosLibres: Int { max(0, Reglas.espaciosDeMochila - mochila.count) }

    /// §1145 pregunta si el Guardián del Censo ha caído: eso es haber ganado
    /// el combate de §1137, que lleva a §1138.
    var guardianDelCensoDerrotado: Bool { visitadas.contains(1138) }

    /// Los marcadores que este ámbito llega a mover, según el propio JSON.
    var marcadoresActivos: [RepTrack] {
        SagaLibrary.shared.marcadoresActivos(en: scope)
    }

    func cumple(_ choice: Choice) -> Bool {
        guard let requerido = choice.requires else { return true }
        return flags.contains(requerido)
    }

    /// La sección manda consultar la tabla de finales en vez de terminar.
    var esTablaDeFinales: Bool { TablaDeFinales.secciones.contains(seccionActual) }

    // ── Movimiento ──────────────────────────────────────────────────────────

    @discardableResult
    func ir(a destino: Int, por choice: Choice? = nil) -> [Aviso] {
        var salida: [Aviso] = []
        let primeraVisita = !visitadas.contains(destino)

        if let choice {
            registrar(.eleccion, texto: choice.etiqueta(unicaOpcion: false),
                      detalle: "§\(choice.target)")
        }
        if let flag = choice?.setsFlag {
            salida += conceder(flag: flag)
        }

        seccionActual = destino
        visitadas.insert(destino)
        ojoDeVardoUsadoEnSeccion = false

        guard let section = SagaLibrary.shared[destino] else {
            avisos = salida
            return salida
        }

        registrar(.seccion, seccion: destino, texto: section.title, detalle: section.libro)
        if section.illustration != nil, CatalogoIlustraciones.disponible(en: destino),
           ilustracionesDescubiertas.insert(destino).inserted {
            registrar(.ilustracion, seccion: destino,
                      texto: section.illustration?.caption ?? section.title)
        }

        for flag in section.setsFlags { salida += conceder(flag: flag) }

        for (clave, delta) in section.repDelta.sorted(by: { $0.key < $1.key }) {
            guard let track = RepTrack(rawValue: clave), delta != 0 else { continue }
            aplicar(reputacion: delta, a: track)
            registrar(.reputacion, seccion: destino,
                      texto: "\(track.nombre) \(delta > 0 ? "+\(delta)" : "\(delta)")")
            salida.append(Aviso(tipo: .reputacion,
                                texto: "\(track.nombre) \(delta > 0 ? "+\(delta)" : "\(delta)")"))
        }

        if let tienda = Economia.tienda(en: destino), tienda.fondos > 0,
           !tiendasCobradas.contains(destino) {
            tiendasCobradas.insert(destino)
            monedas[tienda.moneda, default: 0] += tienda.fondos
            salida.append(Aviso(tipo: .sistema,
                                texto: "Recibes \(tienda.moneda.contar(tienda.fondos))."))
        }

        if section.esPuntoDeDescanso {
            if primeraVisita && esperaDeMarcha > 0 { esperaDeMarcha -= 1 }
            salida.append(Aviso(tipo: .sistema, texto: "Punto de Descanso: puedes recuperar Ecos y Vida."))
        }

        if section.esFinal { finalesVistos.insert(destino) }

        // Parte II, §16: al llegar a 10 te pierdes. Ve a la sección x950.
        if perdido && !section.esFinal && !esTablaDeFinales {
            let final = libroActual.corruptionEnding
            if SagaLibrary.shared[final] != nil {
                salida.append(Aviso(tipo: .corrupcion,
                                    texto: "Corrupción 10. La Sangre Vieja deja de darte prestado su poder."))
                seccionActual = final
                visitadas.insert(final)
                finalesVistos.insert(final)
            }
        }

        avisos = salida
        return salida
    }

    // ── Pruebas de habilidad (Parte II, §12) ────────────────────────────────

    /// La prueba que pide la sección actual, si la pide.
    var pruebaPendiente: PruebaDeHabilidad? {
        PruebasDeHabilidad.para(seccionActual)
    }

    /// Tira 2D6 + atributo y aplica los efectos de la rama, sin moverse
    /// todavía: la vista enseña el resultado y luego avanza al destino.
    /// Cómo se aborda una prueba, más allá de tirar a pelo.
    enum ApoyoDePrueba: Hashable {
        case ninguno
        case vozRota          // Don Forzado: 2 Corrupción, éxito seguro
        case susurroDePiel    // Vidente: 1 Eco, supera VOL Fácil o Media
        case veloRoto         // Vidente: 2 Ecos, +3 a una prueba de AGI

        var hechizo: Hechizo? {
            switch self {
            case .susurroDePiel: return .susurroDePiel
            case .veloRoto: return .veloRoto
            default: return nil
            }
        }
    }

    /// Susurro de Piel solo sirve en pruebas de VOL Fácil o Media (Parte V, §24).
    func puedeUsar(_ apoyo: ApoyoDePrueba, en prueba: PruebaDeHabilidad) -> Bool {
        switch apoyo {
        case .ninguno: return true
        case .vozRota:
            return corrupcion + DonForzado.vozRota.costeCorrupcion <= Reglas.corrupcionMaxima
        case .susurroDePiel:
            guard hechizos.contains(.susurroDePiel), ecos >= Hechizo.susurroDePiel.coste else { return false }
            return prueba.atributo == .vol && (prueba.dificultad == .facil || prueba.dificultad == .media)
        case .veloRoto:
            guard hechizos.contains(.veloRoto), ecos >= Hechizo.veloRoto.coste else { return false }
            return prueba.atributo == .agi
        }
    }

    /// Ojo de Vardo (Vigía Errante): una repetición por sección de una prueba
    /// de AGI fallida.
    func puedeRepetirConOjoDeVardo(_ prueba: PruebaDeHabilidad) -> Bool {
        vocacion == .vigia && !ojoDeVardoUsadoEnSeccion && prueba.atributo == .agi
            && corrupcion < Reglas.corrupcionMaxima
    }

    /// El don repite la tirada tal como se hizo: si se resolvio por la segunda
    /// via, lo que se repite es esa via, no la prueba original.
    func puedeRepetirConOjoDeVardo(_ resultado: ResultadoDePrueba) -> Bool {
        // Repetir deshace primero el intento fallido, asi que el limite se mide
        // contra la Corrupcion que quedara, no contra la que aun se ve en pantalla.
        return !resultado.repetida && vocacion == .vigia && !ojoDeVardoUsadoEnSeccion && resultado.atributoUsado == .agi
            && corrupcion - resultado.aplicacion.corrupcion < Reglas.corrupcionMaxima
    }

    // ── EL POZO Y LAS HERRAMIENTAS ───────────────────────────────────────
    // La tienda de la seccion 2103 vende la lampara diciendo que "sin ella,
    // algunas pruebas se hacen a un nivel mas de dificultad". Esto es esa
    // frase: bajo tierra, sin luz propia, cada prueba sube un peldano. La
    // yesca sirve de luz improvisada para una sola prueba, y se gasta.
    static let primeraSeccionDelPozo = 2104

    func estaEnElPozo(_ seccion: Int) -> Bool { seccion >= GameState.primeraSeccionDelPozo }

    func necesitaLampara(en seccion: Int) -> Bool {
        estaEnElPozo(seccion) && !mochila.contains(.lamparaDeAceite)
    }

    func puedeEncenderYesca(en seccion: Int) -> Bool {
        necesitaLampara(en: seccion) && mochila.contains(.yesca)
    }

    /// Herramientas de una prueba: las que la propia prueba declara y llevas
    /// encima, mas la tinta de Grieta, que vale para cualquier prueba de VOL.
    func herramientas(para prueba: PruebaDeHabilidad, atributo: Atributo) -> [HerramientaDePrueba] {
        var lista = prueba.herramientas.filter { mochila.contains($0.objeto) }
        if atributo == .vol, mochila.contains(.tintaDeGrieta) {
            lista.append(HerramientaDePrueba(objeto: .tintaDeGrieta, efecto: .repite,
                                             texto: "Anotarlo con la tinta de Grieta"))
        }
        return lista
    }

    /// Repite una prueba fallida gastando un objeto: la cuerda que se queda
    /// amarrada al descenso, el frasco de tinta que se vacia.
    func repetirConHerramienta(_ herramienta: HerramientaDePrueba,
                               tras anterior: ResultadoDePrueba) -> ResultadoDePrueba {
        guard herramienta.efecto == .repite, !anterior.repetida,
              herramientas(para: anterior.prueba, atributo: anterior.atributoUsado).contains(herramienta),
              let i = mochila.firstIndex(of: herramienta.objeto) else { return anterior }
        mochila.remove(at: i)
        return repetir(tras: anterior, nota: "\(herramienta.texto): repites la prueba.")
    }

    /// Una herramienta resuelve la prueba y no se gasta (las ganzuas de la
    /// seccion 102 abren la celda "sin tirar", como dice el propio texto).
    func resolverConHerramienta(_ herramienta: HerramientaDePrueba,
                                prueba: PruebaDeHabilidad) -> ResultadoDePrueba {
        guard herramienta.efecto == .resuelve,
              herramientas(para: prueba, atributo: prueba.atributo).contains(herramienta) else {
            return tirar(prueba: prueba)
        }
        var efectos = ["\(herramienta.texto): superas la prueba sin tirar."]
        let rama = prueba.exito
        let aplicacion = aplicar(rama: rama, en: &efectos)
        let tirada = Tirada(d1: 6, d2: 6, modificador: atributo(prueba.atributo))
        registrar(.prueba, texto: "Prueba de \(prueba.atributo.sigla)",
                  detalle: "\(herramienta.texto) · superada sin tirar")
        return ResultadoDePrueba(prueba: prueba, tirada: tirada, superada: true,
                                 rama: rama, forzada: true, efectos: efectos, aplicacion: aplicacion)
    }


    /// Repite una prueba fallida gastando el don del Vigía.
    func repetirConOjoDeVardo(prueba: PruebaDeHabilidad, tras anterior: ResultadoDePrueba) -> ResultadoDePrueba {
        guard puedeRepetirConOjoDeVardo(anterior) else { return anterior }
        ojoDeVardoUsadoEnSeccion = true
        return repetir(tras: anterior, nota: "Ojo de Vardo: repites la prueba. +\(Reglas.corrupcionPorDon) Corrupción.") {
            self.ganarCorrupcion(Reglas.corrupcionPorDon)
        }
    }

    /// Repetir es volver a tirar los mismos dados, no rehacer la prueba entera:
    /// se conserva el modificador que ya se pago (Lectura del camino, Herido,
    /// el compañero) y el objetivo de la via que se eligio.
    /// `cobrar` se ejecuta despues de revertir el intento anterior: cobrar antes
    /// haria que una mutacion saltara con una Corrupcion que esta a punto de
    /// deshacerse, y la mutacion no se revierte.
    private func repetir(tras anterior: ResultadoDePrueba, nota: String,
                         cobrar: () -> Void = {}) -> ResultadoDePrueba {
        deshacer(anterior.aplicacion)
        cobrar()
        var efectos = [nota]
        let tirada = Dados.tirar2D6(modificador: anterior.tirada.modificador)
        let superada = tirada.alcanza(anterior.objetivoUsado)
        let rama = superada ? anterior.prueba.exito : anterior.prueba.fallo
        let aplicacion = aplicar(rama: rama, en: &efectos)
        registrar(.prueba, texto: "Prueba de \(anterior.atributoUsado.sigla)",
                  detalle: "\(tirada.total) contra \(anterior.objetivoUsado) · repetida · \(superada ? "superada" : "fallida")")
        return ResultadoDePrueba(prueba: anterior.prueba, tirada: tirada, superada: superada,
                                 rama: rama, efectos: efectos, segundaVia: anterior.segundaVia,
                                 aplicacion: aplicacion, objetivo: anterior.objetivoUsado, repetida: true)
    }

    /// Al repetir hay que revertir lo que aplicó el intento anterior: las
    /// palabras clave que añadió, el daño que salió en los dados y la
    /// corrupción que cobró.
    private func deshacer(_ aplicada: RamaAplicada) {
        for flag in aplicada.flagsNuevas { flags.remove(flag) }
        if aplicada.dano > 0 { vida = min(vidaMaxima, vida + aplicada.dano) }
        if aplicada.corrupcion != 0 { corrupcion = max(0, corrupcion - aplicada.corrupcion) }
        if aplicada.amuletoGastado { amuletoGastadoEnLibro = false }
    }

    func tirar(prueba: PruebaDeHabilidad, forzandoElDon: Bool = false,
               bonoDeApoyo: Int = 0, porSegundaVia: Bool = false,
               encendiendoYesca: Bool = false) -> ResultadoDePrueba {
        var efectos: [String] = []
        if forzandoElDon {
            // Voz Rota (Parte V, §26): superas la prueba pagando Corrupción.
            ganarCorrupcion(DonForzado.vozRota.costeCorrupcion)
            efectos.append("Voz Rota: superas la prueba. +\(DonForzado.vozRota.costeCorrupcion) Corrupción.")
            let rama = prueba.exito
            aplicar(rama: rama, en: &efectos)
            let tirada = Tirada(d1: 6, d2: 6, modificador: atributo(prueba.atributo))
            registrar(.prueba, texto: "Prueba de \(prueba.atributo.sigla)", detalle: "Voz Rota · superada")
            return ResultadoDePrueba(prueba: prueba, tirada: tirada, superada: true,
                                     rama: rama, forzada: true, efectos: efectos)
        }

        // La oscuridad solo pesa sobre quien tira de verdad: forzar el don la
        // esquiva, asi que la yesca no se gasta en esa rama.
        var oscuridad = necesitaLampara(en: prueba.seccion) ? 2 : 0
        if oscuridad > 0, encendiendoYesca, let i = mochila.firstIndex(of: .yesca) {
            mochila.remove(at: i)
            oscuridad = 0
            efectos.append("Enciendes la yesca: la oscuridad no te cobra el peldaño.")
        } else if oscuridad > 0 {
            efectos.append("Sin lámpara de aceite: un peldaño más de dificultad.")
        }

        let via = porSegundaVia ? prueba.segundaVia : nil
        let atributoDePrueba = via?.atributo ?? prueba.atributo
        let objetivoDePrueba = (via?.dificultad.objetivo ?? prueba.objetivo) + oscuridad
        if let via {
            efectos.append("Segunda vía: resuelves con \(via.atributo.sigla) (\(objetivoDePrueba)+).")
        }
        let penalizacionDeHerida = (atributoDePrueba == .fue || atributoDePrueba == .agi)
            && herido && !penalizacionDeHeridaUsada ? 1 : 0
        if penalizacionDeHerida > 0 {
            penalizacionDeHeridaUsada = true
            efectos.append("Herido: −1 a la tirada.")
        }
        let bonoDeMarcha = planDeMarcha == .lectura ? 2 : 0
        if bonoDeMarcha > 0 {
            planDeMarcha = nil
            efectos.append("Lectura del camino: +2 a la tirada.")
        }
        // §2095: Ilena sostiene la voluntad de quien baja con ella.
        let bonoDeCompanero = atributoDePrueba == .vol ? (companero?.pruebaDeVol ?? 0) : 0
        if bonoDeCompanero > 0, let companero {
            efectos.append("\(companero.nombre): +\(bonoDeCompanero) a la tirada.")
        }
        let tirada = Dados.tirar2D6(modificador: atributo(atributoDePrueba) + bonoDeApoyo + bonoDeMarcha + bonoDeCompanero - penalizacionDeHerida)
        let superada = tirada.alcanza(objetivoDePrueba)
        let rama = superada ? prueba.exito : prueba.fallo
        let aplicacion = aplicar(rama: rama, en: &efectos)
        registrar(.prueba, texto: "Prueba de \(atributoDePrueba.sigla)",
                  detalle: "\(tirada.total) contra \(objetivoDePrueba) · \(superada ? "superada" : "fallida")")
        return ResultadoDePrueba(prueba: prueba, tirada: tirada, superada: superada,
                                 rama: rama, efectos: efectos, segundaVia: via,
                                 aplicacion: aplicacion, objetivo: objetivoDePrueba)
    }

    /// Tira la prueba con el apoyo elegido: hechizo, don forzado o nada.
    func tirar(prueba: PruebaDeHabilidad, apoyo: ApoyoDePrueba,
               encendiendoYesca: Bool = false) -> ResultadoDePrueba {
        guard puedeUsar(apoyo, en: prueba) else { return tirar(prueba: prueba, encendiendoYesca: encendiendoYesca) }
        switch apoyo {
        case .ninguno:
            return tirar(prueba: prueba, encendiendoYesca: encendiendoYesca)
        case .vozRota:
            return tirar(prueba: prueba, forzandoElDon: true)
        case .susurroDePiel:
            _ = gastarEcos(Hechizo.susurroDePiel.coste)
            var efectos = ["Susurro de Piel: superas la prueba sin tirar."]
            let rama = prueba.exito
            aplicar(rama: rama, en: &efectos)
            registrar(.prueba, texto: "Prueba de \(prueba.atributo.sigla)", detalle: "Susurro de Piel · superada")
            let tirada = Tirada(d1: 6, d2: 6, modificador: atributo(prueba.atributo))
            return ResultadoDePrueba(prueba: prueba, tirada: tirada, superada: true,
                                     rama: rama, forzada: true, efectos: efectos)
        case .veloRoto:
            _ = gastarEcos(Hechizo.veloRoto.coste)
            var resultado = tirar(prueba: prueba, bonoDeApoyo: 3, encendiendoYesca: encendiendoYesca)
            resultado.efectos.insert("Velo Roto: +3 a la tirada.", at: 0)
            return resultado
        }
    }

    @discardableResult
    private func aplicar(rama: RamaDePrueba, en efectos: inout [String]) -> RamaAplicada {
        var aplicada = RamaAplicada()
        for flag in rama.flags where !flags.contains(flag) {
            flags.insert(flag)
            aplicada.flagsNuevas.append(flag)
            efectos.append(flag.replacingOccurrences(of: "_", with: " "))
            if let nota = aplicarEfectoDeCompanero(flag) { efectos.append(nota) }
        }
        if rama.danoD6 > 0 {
            let dano = Dados.tirarD6(cantidad: rama.danoD6)
            recibirDano(dano)
            aplicada.dano = dano
            efectos.append("Pierdes \(dano) de Vida.")
        }
        if rama.corrupcion != 0 {
            let corrupcionAntes = corrupcion
            let amuletoAntes = amuletoGastadoEnLibro
            ganarCorrupcion(rama.corrupcion)
            aplicada.corrupcion = corrupcion - corrupcionAntes
            aplicada.amuletoGastado = !amuletoAntes && amuletoGastadoEnLibro
            efectos.append("+\(rama.corrupcion) Corrupción.")
        }
        return aplicada
    }

    /// Resuelve la tabla de finales de esta sección y salta al final que toque.
    @discardableResult
    func resolverTablaDeFinales() -> ReglaDeFinal? {
        guard let regla = TablaDeFinales.resolver(seccion: seccionActual, con: self) else { return nil }
        ir(a: regla.destino)
        avisos = [Aviso(tipo: .sistema, texto: regla.descripcion)]
        return regla
    }

    @discardableResult
    func conceder(flag: String) -> [Aviso] {
        guard !flags.contains(flag) else { return [] }
        flags.insert(flag)
        registrar(.palabra, texto: flag.replacingOccurrences(of: "_", with: " "))
        var avisosNuevos = [Aviso(tipo: .flag, texto: flag.replacingOccurrences(of: "_", with: " "))]
        if let nota = aplicarEfectoDeCompanero(flag) {
            avisosNuevos.append(Aviso(tipo: .sistema, texto: nota))
        }
        return avisosNuevos
    }

    /// §2095. Elegir compañía es la única decisión del descenso con efecto
    /// permanente: se aplica una sola vez, al concederse la palabra clave.
    /// Los bonos de daño, Defensa y Voluntad se leen en vivo desde `companero`;
    /// aquí solo se resuelve el de Ecos, que sí modifica la ficha.
    @discardableResult
    private func aplicarEfectoDeCompanero(_ flag: String) -> String? {
        guard let companero = Companero.con(flag: flag) else { return nil }
        if companero.ecos > 0 {
            ecosMaximos += companero.ecos
            ecos += companero.ecos
        }
        registrar(.sistema, texto: "Compañero: \(companero.nombre)", detalle: companero.efecto)
        return "\(companero.nombre): \(companero.efecto)"
    }

    func aplicar(reputacion delta: Int, a track: RepTrack) {
        let actual = rep(track)
        switch track {
        case .orden, .secta, .losLibres, .favor:
            // Parte II, §17: el marcador va de -5 a +5.
            reputacion[track] = max(RepTrack.minimo, min(RepTrack.maximo, actual + delta))
        case .vinculo:
            // El Vínculo del Libro Tercero usa una escala mayor (§2150 pide 8+).
            reputacion[track] = max(0, actual + delta)
        }
    }

    // ── Recursos ────────────────────────────────────────────────────────────

    /// Amuleto de plomo (§2103): una vez por libro anula un punto de Corrupción.
    var puedeUsarAmuleto: Bool {
        mochila.contains(.amuletoDePlomo) && !amuletoGastadoEnLibro
    }

    func ganarCorrupcion(_ cantidad: Int = 1) {
        var cantidad = cantidad
        if cantidad > 0, puedeUsarAmuleto {
            amuletoGastadoEnLibro = true
            cantidad -= 1
            avisos.append(Aviso(tipo: .sistema,
                                texto: "El amuleto de plomo absorbe un punto de Corrupción."))
            if cantidad == 0 { return }
        }
        ganarCorrupcionSinAmuleto(cantidad)
    }

    private func ganarCorrupcionSinAmuleto(_ cantidad: Int = 1) {
        corrupcion = max(0, min(Reglas.corrupcionMaxima, corrupcion + cantidad))
        aplicarMutacionSiProcede()
    }

    func reducirCorrupcion(_ cantidad: Int) {
        corrupcion = max(0, corrupcion - cantidad)
    }

    /// Parte II, §16: al llegar a 7, -1 VOL permanente y +1 FUE.
    private func aplicarMutacionSiProcede() {
        guard !mutacionAplicada, corrupcion >= 7 else { return }
        mutacionAplicada = true
        atributos[.vol] = max(0, atributo(.vol) - 1)
        atributos[.fue] = atributo(.fue) + 1
        avisos.append(Aviso(tipo: .corrupcion, texto: "Empiezas a mutar: -1 VOL, +1 FUE."))
        registrar(.mutacion, texto: "La Corrupción transforma tu cuerpo", detalle: "−1 VOL · +1 FUE")
    }

    /// Devuelve true si has caído a 0.
    @discardableResult
    func recibirDano(_ cantidad: Int) -> Bool {
        vida = max(0, vida - cantidad)
        return vida == 0
    }

    func curar(_ cantidad: Int) {
        vida = min(vidaMaxima, vida + cantidad)
        if vida * 2 > vidaMaxima { penalizacionDeHeridaUsada = false }
    }

    func gastarEcos(_ cantidad: Int) -> Bool {
        guard ecos >= cantidad else { return false }
        ecos -= cantidad
        return true
    }

    /// Parte II, §18: Ecos al completo y la mitad de la Vida máxima.
    // ── Hechizos y dones fuera de combate (Parte V) ─────────────────────────

    /// Los hechizos que se pueden lanzar ahora mismo desde la hoja.
    var hechizosFueraDeCombate: [Hechizo] {
        hechizos.filter { $0.momento == .fueraDeCombate && $0.curaD6 > 0 }
    }

    func puedeLanzar(_ hechizo: Hechizo) -> Bool {
        ecos >= hechizo.coste && vida < vidaMaxima
    }

    /// Manos de Ceniza y Juramento Compartido: curan y cuestan Ecos.
    func lanzar(_ hechizo: Hechizo) {
        guard puedeLanzar(hechizo), gastarEcos(hechizo.coste) else { return }
        let curado = Dados.tirarD6(cantidad: hechizo.curaD6, mas: hechizo.curaBonus)
        curar(curado)
        avisos = [Aviso(tipo: .vida, texto: "\(hechizo.nombre): recuperas \(curado) de Vida.")]
    }

    /// Voto de Ceniza (Penitente): una vez por libro, cura 1D6+2 fuera de combate.
    var puedeUsarVotoDeCeniza: Bool {
        vocacion == .penitente && !votoDeCenizaUsadoEnLibro && vida < vidaMaxima
            && corrupcion < Reglas.corrupcionMaxima
    }

    func usarVotoDeCeniza() {
        guard puedeUsarVotoDeCeniza else { return }
        votoDeCenizaUsadoEnLibro = true
        ganarCorrupcion(Reglas.corrupcionPorDon)
        let curado = Dados.tirarD6(cantidad: 1, mas: 2)
        curar(curado)
        avisos = [Aviso(tipo: .vida, texto: "Voto de Ceniza: recuperas \(curado) de Vida. +\(Reglas.corrupcionPorDon) Corrupción.")]
    }

    // ── Tienda (§72, §73 y §2103) ───────────────────────────────────────────

    var tiendaActual: Tienda? { Economia.tienda(en: seccionActual) }

    func monedas(_ m: Moneda) -> Int { monedas[m] ?? 0 }

    /// El catálogo imprime requisitos de FUE/AGI; aquí se comprueban.
    func cumpleRequisito(_ articulo: Articulo) -> Bool {
        guard let r = articulo.requiere else { return true }
        return atributo(r.atributo) >= r.minimo
    }

    func yaComprado(_ articulo: Articulo) -> Bool {
        guard !articulo.repetible else { return false }
        switch articulo.mercancia {
        case .arma(let a): return arma == a || armaSecundaria == a
        case .armadura(let a): return armadura == a
        case .escudo: return llevaEscudo
        case .objeto(let o): return mochila.contains(o)
        }
    }

    func puedeComprar(_ articulo: Articulo, en tienda: Tienda) -> Bool {
        guard monedas(tienda.moneda) >= articulo.precio else { return false }
        guard cumpleRequisito(articulo), !yaComprado(articulo) else { return false }
        if case .objeto = articulo.mercancia, espaciosLibres == 0 { return false }
        return true
    }

    @discardableResult
    func comprar(_ articulo: Articulo, en tienda: Tienda) -> Bool {
        guard puedeComprar(articulo, en: tienda) else { return false }
        monedas[tienda.moneda, default: 0] -= articulo.precio
        switch articulo.mercancia {
        case .arma(let a):
            // El arma comprada pasa a ser la principal; la anterior queda de reserva.
            armaSecundaria = arma
            arma = a
        case .armadura(let a):
            armadura = a
        case .escudo:
            llevaEscudo = true
        case .objeto(let o):
            mochila.append(o)
        }
        avisos = [Aviso(tipo: .sistema,
                        texto: "Compras \(articulo.nombre) por \(tienda.moneda.contar(articulo.precio)).")]
        registrar(.objeto, texto: "Compra: \(articulo.nombre)",
                  detalle: tienda.moneda.contar(articulo.precio))
        return true
    }

    func puedeVender(_ venta: Venta) -> Bool {
        flags.contains(venta.flag) && !ventasHechas.contains(venta.flag)
    }

    /// §72: entregar el mapa o la tablilla a Orwyn a cambio de Esquirlas.
    @discardableResult
    func vender(_ venta: Venta, en tienda: Tienda) -> Bool {
        guard puedeVender(venta) else { return false }
        ventasHechas.insert(venta.flag)
        monedas[tienda.moneda, default: 0] += venta.importe
        avisos = [Aviso(tipo: .sistema,
                        texto: "Entregas \(venta.nombre) por \(tienda.moneda.contar(venta.importe)).")]
        registrar(.objeto, texto: "Entrega: \(venta.nombre)",
                  detalle: "+\(tienda.moneda.contar(venta.importe))")
        return true
    }

    /// El siguiente hechizo del repertorio que todavía no conoces.
    var proximoHechizoPorAprender: Hechizo? {
        vocacion.repertorio.first { !hechizos.contains($0) }
    }

    func descansar() {
        ecos = ecosMaximos
        let mitad = Int(ceil(Double(vidaMaxima) / 2.0))
        curar(mitad)
        var texto = "Descansas: Ecos al completo y +\(mitad) de Vida."
        // Parte II, §18: en el descanso repasas la Hoja y avanzas tu Grimorio.
        if let nuevo = proximoHechizoPorAprender {
            hechizos.append(nuevo)
            ecosMaximos += 1
            ecos = ecosMaximos
            texto += " Aprendes \(nuevo.nombre)."
            registrar(.objeto, texto: "Aprendes \(nuevo.nombre)", detalle: "Grimorio")
        }
        avisos = [Aviso(tipo: .vida, texto: texto)]
        registrar(.descanso, texto: "Punto de descanso", detalle: "+\(mitad) Vida · Ecos al completo")
    }

    func prepararMarcha(_ plan: PlanDeMarcha) {
        guard puedePrepararMarcha(plan) else { return }
        if plan == .silencio {
            reducirCorrupcion(1)
            planDeMarcha = nil
            esperaDeMarcha = 2
            descansosDeSilencio.insert(seccionActual)
        } else {
            planDeMarcha = plan
        }
        avisos = [Aviso(tipo: .sistema, texto: "\(plan.titulo): \(plan.efecto)")]
        registrar(.sistema, texto: plan.titulo, detalle: plan.efecto)
    }

    func puedePrepararMarcha(_ plan: PlanDeMarcha) -> Bool {
        guard esperaDeMarcha == 0 else { return false }
        if plan == .silencio {
            return corrupcion > 0 && !descansosDeSilencio.contains(seccionActual)
        }
        return true
    }

    /// Se consume solo al primer golpe enemigo real; si derrotas al rival antes,
    /// la vigilancia sigue siendo útil para el siguiente encuentro.
    func consumirVigilancia() -> Bool {
        guard planDeMarcha == .vigilancia else { return false }
        planDeMarcha = nil
        return true
    }

    func usar(objeto: ObjetoDeMochila) {
        guard let indice = mochila.firstIndex(of: objeto) else { return }
        var texto = "Usas \(objeto.nombre)."
        if objeto.cura {
            let curado = Dados.tirarD6(cantidad: objeto.curaD6, mas: objeto.curaBonus)
            curar(curado)
            texto = "\(objeto.nombre): recuperas \(curado) de Vida."
        }
        if objeto.permiteDescanso {
            ecos = ecosMaximos
            let mitad = Int(ceil(Double(vidaMaxima) / 2.0))
            curar(mitad)
            texto = "\(objeto.nombre): descansas. Ecos al completo y +\(mitad) de Vida."
        }
        if objeto.consumible { mochila.remove(at: indice) }
        avisos = [Aviso(tipo: .vida, texto: texto)]
        registrar(.objeto, texto: texto)
    }

    // ── Saga ────────────────────────────────────────────────────────────────

    /// En la saga completa, un final que no sea caída ni Corrupción encadena.
    var siguienteLibro: BookID? {
        guard scope.continuesBetweenBooks, let section = seccion, section.esFinal else { return nil }
        let resto = section.id % 1000
        guard resto != 900 && resto != 950 else { return nil }
        return libroActual.next
    }

    // ── Nivel ───────────────────────────────────────────────────────────────
    // Decisión de diseño (no del libro): subes de nivel solo al cruzar a un
    // libro nuevo, nunca dentro de uno. Los enemigos ya escalan por libro
    // (Bestiario.stats), así que no hace falta tocar ningún combate: llegar
    // más fuerte a un libro que ya es más duro es la sensación de progresión.

    /// Cierto justo después de cruzar a un libro nuevo, hasta que repartes
    /// los puntos de esa subida.
    var nivelPendiente: Bool { nivel < libroActual.rawValue }

    /// Reparte los puntos de la subida de nivel pendiente. `reparto` debe
    /// sumar exactamente `Reglas.puntosPorNivel` en valores no negativos; si
    /// no cuadra, no hace nada y devuelve `false`.
    @discardableResult
    func subirDeNivel(reparto: [Atributo: Int]) -> Bool {
        guard nivelPendiente,
              reparto.values.allSatisfy({ $0 >= 0 }),
              reparto.values.reduce(0, +) == Reglas.puntosPorNivel
        else { return false }
        for (attr, extra) in reparto where extra > 0 {
            atributos[attr, default: 0] += extra
        }
        nivel = libroActual.rawValue
        let detalle = reparto.filter { $0.value > 0 }
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { "\($0.key.sigla) +\($0.value)" }.joined(separator: " · ")
        registrar(.sistema, texto: "Subes a nivel \(nivel)", detalle: detalle)
        return true
    }

    /// Reparto por defecto para partidas sin nadie eligiendo (simulación,
    /// tests): todos los puntos al atributo primario de la vocación.
    @discardableResult
    func subirDeNivelAutomatico() -> Bool {
        subirDeNivel(reparto: [vocacion.atributoPrimario: Reglas.puntosPorNivel])
    }

    func continuarAlSiguienteLibro() {
        guard let siguiente = siguienteLibro else { return }
        // Cruzas con tu Corrupción, tus palabras clave y tu Vínculo intactos.
        vida = vidaMaxima
        ecos = ecosMaximos
        penalizacionDeHeridaUsada = false
        donUsadoEnEsteCombate = false
        votoDeCenizaUsadoEnLibro = false
        amuletoGastadoEnLibro = false
        let vinculo = rep(.vinculo)
        for track in RepTrack.allCases where track != .vinculo { reputacion[track] = 0 }
        reputacion[.vinculo] = vinculo
        registrar(.libro, seccion: siguiente.startSection,
                  texto: "Comienza el Libro \(siguiente.numeral)", detalle: siguiente.title)
        ir(a: siguiente.startSection)
    }

    func registrarCombate(_ enemigo: String, victoria: Bool) {
        registrar(.combate, texto: victoria ? "Victoria contra \(enemigo)" : "Derrota ante \(enemigo)")
    }

    private func registrar(_ tipo: EventoCronica.Tipo, seccion: Int? = nil,
                           texto: String, detalle: String? = nil) {
        historia.append(EventoCronica(tipo: tipo, seccion: seccion ?? seccionActual,
                                      texto: texto, detalle: detalle, orden: historia.count + 1))
        if historia.count > 600 { historia.removeFirst(historia.count - 600) }
    }
}
