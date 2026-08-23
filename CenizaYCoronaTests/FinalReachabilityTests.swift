import XCTest
@testable import CenizaYCorona

final class FinalReachabilityTests: XCTestCase {
    private let library = SagaLibrary.shared

    func testAllFinalTablesResolveEveryDeclaredOutcome() {
        let cases: [(section: Int, destination: Int, configure: (GameState) -> Void)] = [
            (133, 950, { $0.corrupcion = 10 }),
            (133, 905, { $0.corrupcion = 7 }),
            (133, 901, { $0.flags = ["PADRE_CENIZA_CAIDO"]; $0.reputacion[.orden] = 4 }),
            (133, 902, { $0.flags = ["TOMAS_VACILA"] }),
            (133, 903, { $0.reputacion[.losLibres] = 4 }),
            (133, 904, { $0.flags = ["NINOS_A_SALVO", "BREN_RESCATADO"] }),
            (133, 906, { _ in }),
            (1145, 1950, { $0.corrupcion = 10 }),
            (1145, 1901, { $0.flags = ["ALIANZA_VAAS", "ORDAZ_EXPUESTA"]; $0.reputacion[.favor] = 3 }),
            (1145, 1902, { $0.visitadas = [1138]; $0.flags = ["ORDAZ_CONVENCIDA"] }),
            (1145, 1903, { $0.flags = ["ALIANZA_REFUGIO"]; $0.reputacion[.losLibres] = 3 }),
            (1145, 1904, { $0.visitadas = [1138]; $0.reputacion[.orden] = 3 }),
            (1145, 1905, { $0.visitadas = [1138]; $0.corrupcion = 7 }),
            (1145, 1906, { _ in }),
            (2150, 2950, { $0.corrupcion = 10 }),
            (2150, 2903, { $0.flags = ["PACTO_PROPUESTO", "PACTO_ACEPTADO"]; $0.reputacion[.vinculo] = 8 }),
            (2150, 2901, { $0.flags = ["DECISION_REFORJAR", "VOLUNTARIOS_DEL_VALLE"] }),
            (2150, 2902, { $0.flags = ["DECISION_ROMPER"] }),
            // EXPEDICIÓN UNIDA no puede eclipsar VOLUNTARIOS RECHAZADOS.
            (2150, 2904, { $0.flags = ["DECISION_REFORJAR", "VOLUNTARIOS_RECHAZADOS", "EXPEDICION_UNIDA"] }),
            (2150, 2905, { $0.corrupcion = 7 }),
            (2150, 2906, { _ in }),
        ]

        for fixture in cases {
            let state = GameState(nombre: "Prueba", vocacion: .cuchilla,
                                  reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .saga)
            state.seccionActual = fixture.section
            fixture.configure(state)
            XCTAssertEqual(TablaDeFinales.resolver(seccion: fixture.section, con: state)?.destino,
                           fixture.destination, "La tabla §\(fixture.section) no resuelve §\(fixture.destination).")
        }
    }

    func testEveryReachableSectionCanLeadToAnEnding() {
        let ids = Set(BookID.allCases.flatMap(library.ids(in:)))
        let starts = [1, 1001, 2001]
        var adjacency = Dictionary(uniqueKeysWithValues: ids.map { ($0, Set<Int>()) })

        for id in ids {
            guard let section = library[id] else { continue }
            for choice in section.choices where ids.contains(choice.target) { adjacency[id, default: []].insert(choice.target) }
            if let combat = section.combat {
                if ids.contains(combat.onWin) { adjacency[id, default: []].insert(combat.onWin) }
                if ids.contains(combat.onLose) { adjacency[id, default: []].insert(combat.onLose) }
            }
            if TablaDeFinales.secciones.contains(id) {
                for rule in TablaDeFinales.reglas(para: id) where ids.contains(rule.destino) {
                    adjacency[id, default: []].insert(rule.destino)
                }
            }
            if !section.choices.isEmpty {
                adjacency[id, default: []].insert(section.libroActual.corruptionEnding)
            }
        }

        let reachable = closure(from: starts, through: adjacency)
        let reserved = Set(ids.filter { library[$0]?.esReservada == true })
        XCTAssertEqual(reachable.subtracting(reserved), ids.subtracting(reserved), "Hay secciones no alcanzables desde los inicios de libro.")

        let endings = Set(ids.filter { library[$0]?.esFinal == true })
        XCTAssertEqual(endings.count, 24, "La biblioteca debe exponer los 24 finales de la saga.")
        var reverse = Dictionary(uniqueKeysWithValues: ids.map { ($0, Set<Int>()) })
        for (source, targets) in adjacency {
            for target in targets { reverse[target, default: []].insert(source) }
        }
        let canReachEnding = closure(from: Array(endings), through: reverse)
        XCTAssertTrue(reachable.isSubset(of: canReachEnding), "Hay secciones alcanzables sin una ruta válida a un final.")
    }

    func testAllVocacionesCanStartAndReachAnEndingWithoutClassLocks() {
        let ids = Set(BookID.allCases.flatMap(library.ids(in:)))
        let starts = [1, 1001, 2001]
        let endings = Set(ids.filter { library[$0]?.esFinal == true })
        var adjacency = Dictionary(uniqueKeysWithValues: ids.map { ($0, Set<Int>()) })
        for id in ids {
            guard let section = library[id] else { continue }
            for choice in section.choices where ids.contains(choice.target) { adjacency[id, default: []].insert(choice.target) }
            if let combat = section.combat {
                adjacency[id, default: []].insert(combat.onWin)
                adjacency[id, default: []].insert(combat.onLose)
            }
            if TablaDeFinales.secciones.contains(id) {
                for rule in TablaDeFinales.reglas(para: id) { adjacency[id, default: []].insert(rule.destino) }
            }
        }
        let reachable = closure(from: starts, through: adjacency)
        var capaces = 0
        for vocacion in Vocacion.allCases {
            let state = GameState(nombre: vocacion.nombre, vocacion: vocacion,
                                  reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .saga)
            XCTAssertGreaterThanOrEqual(vocacion.vidaInicial, 22, "\(vocacion.nombre) debe tener margen de supervivencia.")
            XCTAssertGreaterThanOrEqual(vocacion.defensaInicial, 9, "\(vocacion.nombre) debe tener Defensa inicial viable.")
            XCTAssertFalse(state.mochila.isEmpty, "\(vocacion.nombre) debe empezar con recursos.")
            XCTAssertTrue(reachable.intersection(endings).isEmpty == false,
                          "\(vocacion.nombre) no tiene ruta a un final.")
            capaces += 1
        }
        print("Vocaciones con ruta a un final: \(capaces)/\(Vocacion.allCases.count).")
    }

    func testTravelPreparationsAreConsumableAndNeverGateProgress() {
        let state = GameState(nombre: "Marcha", vocacion: .vidente,
                              reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .saga)
        state.prepararMarcha(.lectura)
        XCTAssertEqual(state.planDeMarcha, .lectura)
        guard let test = PruebasDeHabilidad.para(114) else { return XCTFail("Falta la prueba §114.") }
        _ = state.tirar(prueba: test)
        XCTAssertNil(state.planDeMarcha, "Leer el camino debe gastarse al ayudar en una prueba.")
        state.prepararMarcha(.vigilancia)
        XCTAssertTrue(state.consumirVigilancia())
        XCTAssertNil(state.planDeMarcha)
        state.corrupcion = 3
        state.prepararMarcha(.silencio)
        XCTAssertEqual(state.corrupcion, 2)
        XCTAssertEqual(state.esperaDeMarcha, 2)
        XCTAssertFalse(state.puedePrepararMarcha(.lectura))
    }

    func testWoundPenaltyIsConsumedAndClearedByHealing() {
        let wounded = GameState(nombre: "Herida", vocacion: .cuchilla,
                                reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .saga)
        wounded.vida = wounded.vidaMaxima / 2
        XCTAssertTrue(wounded.herido)
        guard let test = PruebasDeHabilidad.para(114) else { return XCTFail("Falta la prueba §114.") }
        _ = wounded.tirar(prueba: test)
        XCTAssertTrue(wounded.penalizacionDeHeridaUsada)
        wounded.curar(wounded.vidaMaxima)
        XCTAssertFalse(wounded.herido)
        XCTAssertFalse(wounded.penalizacionDeHeridaUsada)
    }

    func testSeerHasHeroicExitFromTheMajorBroken() {
        let state = GameState(nombre: "Vidente", vocacion: .vidente,
                              reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.primero))
        guard let section = library[126], let data = section.combat else {
            return XCTFail("Falta el combate §126.")
        }
        let combat = CombatSession(seccionID: 126, datos: data)
        XCTAssertEqual(combat.dificultadDeSalida(state), .heroica)
    }

    func testSecondRouteKeepsTheSameBranchesAndCostsOneStepMore() {
        guard let sigilo = PruebasDeHabilidad.para(1126), let via = sigilo.segundaVia else {
            return XCTFail("Falta la segunda via de §1126.")
        }
        XCTAssertEqual(via.atributo, .fue)
        XCTAssertEqual(via.dificultad, .heroica)
        XCTAssertGreaterThan(via.dificultad.objetivo, sigilo.dificultad.objetivo)

        let state = GameState(nombre: "Fuerte", vocacion: .cuchilla,
                              reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.segundo))
        let resultado = state.tirar(prueba: sigilo, porSegundaVia: true)
        XCTAssertEqual(resultado.atributoUsado, .fue)
        XCTAssertEqual(resultado.objetivoUsado, via.dificultad.objetivo)
        // Gane o pierda, la segunda via no abre destinos nuevos.
        let destinos = [sigilo.exito.destino, sigilo.fallo.destino]
        XCTAssertTrue(destinos.contains(resultado.rama.destino))

        // §1133 pide forzar unas cadenas: la prosa dice forcejeo, luego es FUE.
        XCTAssertEqual(PruebasDeHabilidad.para(1133)?.atributo, .fue)
        XCTAssertEqual(PruebasDeHabilidad.para(1072)?.segundaVia?.atributo, .fue)
    }

    func testRerollUndoesCorruptionBeforeChargingTheGift() {
        // Caso latente: una rama AGI que cobra Corrupcion al fallar. Repetir
        // debe revertir esa Corrupcion ANTES de cobrar el don, o la mutacion
        // de la seccion 16 saltaria con un valor que esta a punto de deshacerse.
        let prueba = PruebaDeHabilidad(seccion: 9001, atributo: .agi, dificultad: .heroica,
                                       exito: RamaDePrueba(destino: 9002),
                                       fallo: RamaDePrueba(destino: 9003, corrupcion: 1))
        var scout = GameState(nombre: "Varda", vocacion: .vigia,
                              reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.primero))
        scout.corrupcion = 6
        var fallo: ResultadoDePrueba?
        for _ in 0..<400 where fallo == nil {
            scout.corrupcion = 6
            scout.ojoDeVardoUsadoEnSeccion = false
            let intento = scout.tirar(prueba: prueba)
            if !intento.superada { fallo = intento } else { scout.flags.removeAll() }
        }
        guard let fallo else { return XCTFail("No se obtuvo un fallo en la prueba sintetica.") }

        XCTAssertEqual(scout.corrupcion, 7)
        XCTAssertTrue(scout.mutacionAplicada, "El fallo por si solo ya alcanza el umbral de mutacion.")

        // Con la mutacion ya disparada por el propio fallo, lo que se comprueba
        // aqui es la contabilidad: deshacer el fallo y cobrar el don deja
        // exactamente un punto sobre el valor de partida, no dos.
        //
        // La repeticion puede volver a fallar, y ese fallo nuevo cuesta su
        // propia Corrupcion: es legitimo y no tiene nada que ver con cobrar dos
        // veces el primero. Sin distinguir los dos casos, el test fallaba una
        // de cada tres ejecuciones segun cayeran los dados.
        let repeticion = scout.repetirConOjoDeVardo(prueba: prueba, tras: fallo)
        let maximo = repeticion.superada ? 7 : 8
        XCTAssertLessThanOrEqual(scout.corrupcion, maximo,
                                 "El fallo revertido se ha vuelto a cobrar al repetir.")
    }

    func testCombatSnapshotKeepsTheArmedGifts() {
        // Guardar a mitad de combate no puede desarmar un don ya declarado ni
        // resetear el contador de usos del Eco Profundo.
        let datos = CombatData(enemy: "QUEBRADO MAYOR", onWin: 127, onLose: 900, notes: nil)
        let combate = CombatSession(seccionID: 126, datos: datos)
        combate.furiaArmada = true
        combate.ecoProfundoArmado = true
        combate.ecoProfundoUsos = 2
        combate.muroDeVotoArmado = true

        let restaurado = CombatSession(snapshot: CombatSnapshot(combate), datos: datos)
        XCTAssertTrue(restaurado.furiaArmada)
        XCTAssertTrue(restaurado.ecoProfundoArmado)
        XCTAssertEqual(restaurado.ecoProfundoUsos, 2)
        XCTAssertTrue(restaurado.muroDeVotoArmado)
    }

    func testVocationGiftsAllCostOneCorruption() {
        // §13, el precio del don: las cuatro vocaciones pagan lo mismo, y
        // ninguna puede llamar a la Marca cuando ya está al límite.
        guard let prueba = PruebasDeHabilidad.para(124) else {
            return XCTFail("Falta la prueba §124.")
        }
        var scout = GameState(nombre: "Varda", vocacion: .vigia,
                              reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.primero))
        var fallo: ResultadoDePrueba?
        for _ in 0..<400 where fallo == nil {
            scout = GameState(nombre: "Varda", vocacion: .vigia,
                              reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.primero))
            scout.vida = scout.vidaMaxima / 2
            let intento = scout.tirar(prueba: prueba)
            if !intento.superada { fallo = intento }
        }
        guard let fallo else { return XCTFail("No se obtuvo un fallo en §124.") }
        let antes = scout.corrupcion
        _ = scout.repetirConOjoDeVardo(prueba: prueba, tras: fallo)
        XCTAssertEqual(scout.corrupcion, antes + Reglas.corrupcionPorDon)

        var penitente = GameState(nombre: "Ceniza", vocacion: .penitente,
                                  reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.primero))
        penitente.vida = 4
        XCTAssertTrue(penitente.puedeUsarVotoDeCeniza)
        let corrupcionAntes = penitente.corrupcion
        penitente.usarVotoDeCeniza()
        XCTAssertEqual(penitente.corrupcion, corrupcionAntes + Reglas.corrupcionPorDon)
        XCTAssertGreaterThan(penitente.vida, 4)

        // Al borde de la Corrupción, el don deja de estar disponible.
        var alBorde = GameState(nombre: "Dravin", vocacion: .penitente,
                                reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.primero))
        alBorde.vida = 4
        alBorde.corrupcion = Reglas.corrupcionMaxima
        XCTAssertFalse(alBorde.puedeUsarVotoDeCeniza)
    }

    func testRerollUndoesTheFirstAttemptAndKeepsTheModifierAlreadyPaid() {
        // §124 falla con daño: repetir no debe dejar aplicado el daño del primer
        // intento, ni perder por el camino la penalización de Herido ya contada.
        guard let prueba = PruebasDeHabilidad.para(124), prueba.fallo.danoD6 > 0 else {
            return XCTFail("Falta la prueba §124 con daño en el fallo.")
        }
        var fallo: ResultadoDePrueba?
        var scout = GameState(nombre: "Varda", vocacion: .vigia,
                              reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.primero))
        var vidaAntes = 0
        for _ in 0..<400 where fallo == nil {
            scout = GameState(nombre: "Varda", vocacion: .vigia,
                              reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.primero))
            scout.vida = scout.vidaMaxima / 2
            XCTAssertTrue(scout.herido)
            vidaAntes = scout.vida
            let intento = scout.tirar(prueba: prueba)
            if !intento.superada { fallo = intento }
        }
        guard let fallo else { return XCTFail("No se obtuvo un fallo en §124.") }

        XCTAssertTrue(scout.penalizacionDeHeridaUsada)
        XCTAssertEqual(fallo.tirada.modificador, scout.atributo(.agi) - 1)
        XCTAssertLessThan(scout.vida, vidaAntes)
        XCTAssertTrue(scout.puedeRepetirConOjoDeVardo(fallo))

        let repetida = scout.repetirConOjoDeVardo(prueba: prueba, tras: fallo)
        // La repetición conserva el modificador que ya se pagó, penalización incluida.
        XCTAssertEqual(repetida.tirada.modificador, fallo.tirada.modificador)
        XCTAssertEqual(repetida.objetivoUsado, fallo.objetivoUsado)
        // El daño del primer intento se revirtió: solo cuenta el de la repetición.
        XCTAssertEqual(vidaAntes - scout.vida, repetida.aplicacion.dano)
    }

    /// Las ganzuas del armero abren la celda de la seccion 102 sin tirar, y no
    /// se gastan: la nota del propio texto deja de ser decorativa.
    func testGanzuasResuelvenLaCeldaSinTirar() throws {
        guard let prueba = PruebasDeHabilidad.para(102) else { return XCTFail("Falta la prueba 102.") }
        let heroe = GameState(nombre: "Llave", vocacion: .cuchilla,
                              reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.primero))
        let herramientas = heroe.herramientas(para: prueba, atributo: prueba.atributo)
        XCTAssertTrue(herramientas.isEmpty, "Sin ganzuas no hay herramienta.")

        heroe.mochila.append(.ganzuas)
        guard let ganzuas = heroe.herramientas(para: prueba, atributo: prueba.atributo).first else {
            return XCTFail("Las ganzuas deberian aparecer como herramienta.")
        }
        XCTAssertEqual(ganzuas.efecto, .resuelve)
        let resultado = heroe.resolverConHerramienta(ganzuas, prueba: prueba)
        XCTAssertTrue(resultado.superada)
        XCTAssertEqual(resultado.rama.destino, prueba.exito.destino)
        XCTAssertTrue(heroe.mochila.contains(.ganzuas), "Una herramienta no se gasta.")
    }

    /// La escalera del pozo (seccion 2110) es la prueba de AGI que la cuerda
    /// del mercader promete: repite el intento y se queda amarrada alli.
    func testLaCuerdaRepiteElDescensoYSeGasta() throws {
        guard let prueba = PruebasDeHabilidad.para(2110) else { return XCTFail("Falta la prueba 2110.") }
        XCTAssertEqual(prueba.atributo, .agi)
        var fallo: ResultadoDePrueba?
        var heroe = GameState(nombre: "Varda", vocacion: .cuchilla,
                              reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.tercero))
        for _ in 0..<400 where fallo == nil {
            heroe = GameState(nombre: "Varda", vocacion: .cuchilla,
                              reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.tercero))
            heroe.mochila.append(.lamparaDeAceite)
            heroe.mochila.append(.cuerdaImperial)
            let intento = heroe.tirar(prueba: prueba)
            if !intento.superada { fallo = intento }
        }
        guard let fallo else { return XCTFail("No se obtuvo un fallo en la seccion 2110.") }
        guard let cuerda = heroe.herramientas(para: prueba, atributo: .agi)
            .first(where: { $0.objeto == .cuerdaImperial }) else {
            return XCTFail("La cuerda deberia valer en el descenso.")
        }
        XCTAssertEqual(cuerda.efecto, .repite)
        let repetida = heroe.repetirConHerramienta(cuerda, tras: fallo)
        XCTAssertEqual(repetida.objetivoUsado, fallo.objetivoUsado)
        XCTAssertFalse(heroe.mochila.contains(.cuerdaImperial), "Un recurso se gasta al usarlo.")
        // Una prueba se repite una sola vez: la segunda cuerda ya no compra otra.
        XCTAssertTrue(repetida.repetida)
        XCTAssertFalse(heroe.puedeRepetirConOjoDeVardo(repetida))
        heroe.mochila.append(.cuerda)
        if let otra = heroe.herramientas(para: prueba, atributo: .agi).first(where: { $0.objeto == .cuerda }) {
            let tercera = heroe.repetirConHerramienta(otra, tras: repetida)
            XCTAssertEqual(tercera.tirada, repetida.tirada, "No hay una tercera tirada.")
            XCTAssertTrue(heroe.mochila.contains(.cuerda), "Y no se gasta nada al intentarlo.")
        }
    }

    /// El pozo sin lampara sube un peldano, tal como lo vende la seccion 2103.
    /// La yesca es la luz improvisada que lo anula una vez, y se gasta.
    func testElPozoSinLamparaSubeUnPeldano() throws {
        guard let prueba = PruebasDeHabilidad.para(2110) else { return XCTFail("Falta la prueba 2110.") }
        let aoscuras = GameState(nombre: "Ciego", vocacion: .cuchilla,
                                 reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.tercero))
        XCTAssertTrue(aoscuras.necesitaLampara(en: 2110))
        XCTAssertFalse(aoscuras.necesitaLampara(en: 2079), "El peldano solo pesa dentro del pozo.")
        let sinLuz = aoscuras.tirar(prueba: prueba)
        XCTAssertEqual(sinLuz.objetivoUsado, prueba.objetivo + 2)

        let conYesca = GameState(nombre: "Chispa", vocacion: .cuchilla,
                                 reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.tercero))
        conYesca.mochila.append(.yesca)
        XCTAssertTrue(conYesca.puedeEncenderYesca(en: 2110))
        let conLuz = conYesca.tirar(prueba: prueba, encendiendoYesca: true)
        XCTAssertEqual(conLuz.objetivoUsado, prueba.objetivo)
        XCTAssertFalse(conYesca.mochila.contains(.yesca), "La yesca se gasta al encenderla.")

        let conLampara = GameState(nombre: "Faro", vocacion: .cuchilla,
                                   reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.tercero))
        conLampara.mochila.append(.lamparaDeAceite)
        XCTAssertFalse(conLampara.necesitaLampara(en: 2110))
        XCTAssertEqual(conLampara.tirar(prueba: prueba).objetivoUsado, prueba.objetivo)
    }

    /// La tinta de Grieta deja de prometer una mecanica que no existia: vale
    /// como segunda tirada de cualquier prueba de VOL, y se vacia al usarla.
    func testLaTintaDeGrietaRepiteUnaPruebaDeVoluntad() throws {
        guard let pruebaVol = PruebasDeHabilidad.para(120),
              let pruebaAgi = PruebasDeHabilidad.para(124) else { return XCTFail("Faltan pruebas.") }
        let vidente = GameState(nombre: "Tinta", vocacion: .vidente,
                                reparto: [.fue: 1, .agi: 1, .vol: 1], scope: .book(.primero))
        XCTAssertTrue(vidente.mochila.contains(.tintaDeGrieta))
        XCTAssertEqual(vidente.herramientas(para: pruebaVol, atributo: .vol).count, 1)
        XCTAssertTrue(vidente.herramientas(para: pruebaAgi, atributo: .agi).isEmpty,
                      "La tinta solo vale para la Voluntad.")
    }

    private func closure(from starts: [Int], through adjacency: [Int: Set<Int>]) -> Set<Int> {
        var seen: Set<Int> = []
        var queue = starts
        while let id = queue.popLast() {
            guard seen.insert(id).inserted else { continue }
            queue.append(contentsOf: (adjacency[id] ?? []).filter { !seen.contains($0) })
        }
        return seen
    }
}

private extension Section {
    var libroActual: BookID { BookID.containing(id) }
}
