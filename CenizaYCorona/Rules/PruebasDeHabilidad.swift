import Foundation

// ─────────────────────────────────────────────────────────────────────────────
//  PRUEBAS DE HABILIDAD — TRANSCRITAS DEL TEXTO DE CADA SECCIÓN.
//  Veinte secciones piden "**Prueba de VOL (Difícil, 11+)**" y describen sus
//  dos ramas en prosa. Aquí están esas ramas con sus destinos, sus palabras
//  clave y sus costes, para que la app pueda tirar de verdad en vez de dejar
//  que el jugador elija el resultado.
//  Los efectos que la sección ya aplica por `sets_flags` o `rep_delta` NO se
//  repiten aquí (el caso de §124).
// ─────────────────────────────────────────────────────────────────────────────

struct RamaDePrueba: Hashable {
    let destino: Int
    var flags: [String] = []
    /// "Pierdes 1D6 puntos de Vida".
    var danoD6: Int = 0
    var corrupcion: Int = 0
}

struct Alternativa: Hashable {
    let texto: String
    let destino: Int
}

/// SEGUNDA VIA (§13). Algunas pruebas admiten resolverse con otro atributo:
/// forzar en vez de colarse, imponerse en vez de convencer. No es una regla
/// nueva: es la misma idea que las salidas de vocacion en combate, donde a
/// quien la salida no esta hecha para ella le cuesta un peldano mas. Lleva a
/// las mismas ramas, asi que no abre camino propio.
struct SegundaVia: Hashable {
    let texto: String
    let atributo: Atributo
    let dificultad: Dificultad
}

/// HERRAMIENTAS (seccion 14). El libro ya promete que ciertos objetos cambian
/// una prueba: las ganzuas del armero abren la celda de la seccion 102 "sin
/// tirar", y una cuerda amarrada deja intentar de nuevo el descenso. Dos
/// efectos y una frase: una herramienta resuelve la prueba y no se gasta; un
/// recurso deja repetirla y se gasta en el intento.
enum EfectoDeHerramienta: Hashable { case resuelve, repite }

struct HerramientaDePrueba: Hashable {
    let objeto: ObjetoDeMochila
    let efecto: EfectoDeHerramienta
    let texto: String
}

struct PruebaDeHabilidad: Hashable, Identifiable {
    let seccion: Int
    let atributo: Atributo
    let dificultad: Dificultad
    let exito: RamaDePrueba
    let fallo: RamaDePrueba
    /// Una salida que el texto ofrece para no arriesgarse a la tirada.
    var alternativa: Alternativa? = nil
    /// Otro atributo con el que el texto permite resolver el mismo obstaculo.
    var segundaVia: SegundaVia? = nil
    /// Una vía documentada para superarla sin tirar (llevar ganzúas, etc.).
    var nota: String? = nil
    /// Objetos que el propio texto dice que cambian esta prueba.
    var herramientas: [HerramientaDePrueba] = []

    var id: Int { seccion }
    var objetivo: Int { dificultad.objetivo }
}

enum PruebasDeHabilidad {

    static func para(_ seccion: Int) -> PruebaDeHabilidad? { tabla[seccion] }

    static let tabla: [Int: PruebaDeHabilidad] = Dictionary(
        uniqueKeysWithValues: todas.map { ($0.seccion, $0) })

    static let todas: [PruebaDeHabilidad] = [

        // ── Libro Primero ───────────────────────────────────────────────────
        PruebaDeHabilidad(seccion: 32, atributo: .fue, dificultad: .media,
                          exito: RamaDePrueba(destino: 33),
                          fallo: RamaDePrueba(destino: 33, danoD6: 1)),

        PruebaDeHabilidad(seccion: 36, atributo: .agi, dificultad: .media,
                          exito: RamaDePrueba(destino: 38),
                          fallo: RamaDePrueba(destino: 38, danoD6: 1)),

        PruebaDeHabilidad(seccion: 102, atributo: .agi, dificultad: .media,
                          exito: RamaDePrueba(destino: 103),
                          fallo: RamaDePrueba(destino: 103, flags: ["RUIDO_EN_LA_PRISION"]),
                          nota: "Si compraste ganzúas en el armero, superas la prueba sin tirar.",
                          herramientas: [HerramientaDePrueba(objeto: .ganzuas, efecto: .resuelve, texto: "Abrir la cerradura con las ganzúas")]),

        PruebaDeHabilidad(seccion: 114, atributo: .fue, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 115, flags: ["SABOTAJE_LOGRADO"]),
                          fallo: RamaDePrueba(destino: 115, flags: ["SABOTAJE_FALLIDO"])),

        PruebaDeHabilidad(seccion: 120, atributo: .vol, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 121),
                          fallo: RamaDePrueba(destino: 122)),

        // §124 ya concede NIÑOS A SALVO y +2 Los Libres desde la propia sección.
        PruebaDeHabilidad(seccion: 124, atributo: .agi, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 125),
                          fallo: RamaDePrueba(destino: 125, danoD6: 1)),

        PruebaDeHabilidad(seccion: 129, atributo: .agi, dificultad: .media,
                          exito: RamaDePrueba(destino: 130),
                          fallo: RamaDePrueba(destino: 130, danoD6: 1)),

        // ── Libro Segundo ───────────────────────────────────────────────────
        PruebaDeHabilidad(seccion: 1005, atributo: .agi, dificultad: .media,
                          exito: RamaDePrueba(destino: 1006),
                          fallo: RamaDePrueba(destino: 1006),
                          alternativa: Alternativa(texto: "Presentar la carta de la Convocatoria", destino: 1006),
                          nota: "También superas la prueba si decides no ocultar nada y presentar la carta de la Convocatoria como salvoconducto."),

        PruebaDeHabilidad(seccion: 1018, atributo: .vol, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 1019),
                          fallo: RamaDePrueba(destino: 1020)),

        PruebaDeHabilidad(seccion: 1037, atributo: .agi, dificultad: .media,
                          exito: RamaDePrueba(destino: 1038),
                          fallo: RamaDePrueba(destino: 1038)),

        PruebaDeHabilidad(seccion: 1044, atributo: .vol, dificultad: .media,
                          exito: RamaDePrueba(destino: 1045),
                          fallo: RamaDePrueba(destino: 1046)),

        PruebaDeHabilidad(seccion: 1072, atributo: .vol, dificultad: .media,
                          exito: RamaDePrueba(destino: 1073),
                          fallo: RamaDePrueba(destino: 1074),
                          segundaVia: SegundaVia(texto: "Presionarlo: te impones para que hable",
                                                 atributo: .fue, dificultad: .dificil)),

        PruebaDeHabilidad(seccion: 1117, atributo: .vol, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 1119),
                          fallo: RamaDePrueba(destino: 1118)),

        PruebaDeHabilidad(seccion: 1121, atributo: .vol, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 1122),
                          fallo: RamaDePrueba(destino: 1122, danoD6: 1, corrupcion: 1)),

        PruebaDeHabilidad(seccion: 1126, atributo: .agi, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 1128),
                          fallo: RamaDePrueba(destino: 1127),
                          alternativa: Alternativa(texto: "No arriesgarte a un sigilo incierto",
                                                   destino: 1127),
                          segundaVia: SegundaVia(texto: "Abrirte paso: aprovechas su nerviosismo y te impones",
                                                 atributo: .fue, dificultad: .heroica)),

        PruebaDeHabilidad(seccion: 1133, atributo: .fue, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 1137, flags: ["MARCADOS_LIBERADOS"]),
                          fallo: RamaDePrueba(destino: 1137)),

        PruebaDeHabilidad(seccion: 1134, atributo: .vol, dificultad: .heroica,
                          exito: RamaDePrueba(destino: 1135),
                          fallo: RamaDePrueba(destino: 1137)),

        PruebaDeHabilidad(seccion: 1136, atributo: .vol, dificultad: .heroica,
                          exito: RamaDePrueba(destino: 1138, flags: ["BASTIAN_LIBERADO"]),
                          fallo: RamaDePrueba(destino: 1137)),

        // ── Libro Tercero ───────────────────────────────────────────────────
        PruebaDeHabilidad(seccion: 2012, atributo: .agi, dificultad: .media,
                          exito: RamaDePrueba(destino: 2013),
                          fallo: RamaDePrueba(destino: 2013, danoD6: 1)),

        PruebaDeHabilidad(seccion: 2044, atributo: .vol, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 2045),
                          fallo: RamaDePrueba(destino: 2045, corrupcion: 1)),

        PruebaDeHabilidad(seccion: 2046, atributo: .vol, dificultad: .media,
                          exito: RamaDePrueba(destino: 2048),
                          fallo: RamaDePrueba(destino: 2048)),

        PruebaDeHabilidad(seccion: 2079, atributo: .fue, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 2080),
                          fallo: RamaDePrueba(destino: 2080, danoD6: 1)),

        // La escalera del pozo (seccion 2110): seis horas de peldanos gastados
        // sin barandilla. Es la prueba de AGI que la cuerda del mercader promete.
        PruebaDeHabilidad(seccion: 2110, atributo: .agi, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 2111),
                          fallo: RamaDePrueba(destino: 2111, danoD6: 1),
                          nota: "Una cuerda amarrada al descenso te deja intentarlo otra vez, y se queda allí.",
                          herramientas: [
                            HerramientaDePrueba(objeto: .cuerdaImperial, efecto: .repite, texto: "Amarrar la cuerda imperial reforzada"),
                            HerramientaDePrueba(objeto: .cuerda, efecto: .repite, texto: "Amarrar la cuerda de escalada")
                          ]),

        PruebaDeHabilidad(seccion: 2124, atributo: .vol, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 2125),
                          fallo: RamaDePrueba(destino: 2125, corrupcion: 1)),

        PruebaDeHabilidad(seccion: 2133, atributo: .vol, dificultad: .dificil,
                          exito: RamaDePrueba(destino: 2134),
                          fallo: RamaDePrueba(destino: 2136))
    ]
}

/// Lo que ha pasado al tirar una prueba.
/// Lo que una rama aplico de verdad, para poder revertirlo si se repite la
/// tirada: las palabras clave que anadio (no las que ya estaban), el dano que
/// salio en los dados y la corrupcion cobrada.
struct RamaAplicada: Hashable {
    var flagsNuevas: [String] = []
    var dano: Int = 0
    /// Corrupcion realmente ganada, no la que pedia la rama: si el amuleto de
    /// plomo absorbio el punto, aqui queda 0 y deshacer no resta un fantasma.
    var corrupcion: Int = 0
    /// Si esa rama fue la que gasto el amuleto, deshacer se lo devuelve.
    var amuletoGastado: Bool = false
}

struct ResultadoDePrueba: Hashable {
    let prueba: PruebaDeHabilidad
    let tirada: Tirada
    let superada: Bool
    let rama: RamaDePrueba
    var forzada: Bool = false
    var efectos: [String] = []
    /// Se resolvio con la segunda via: otro atributo y otro objetivo.
    var segundaVia: SegundaVia? = nil
    /// Lo que la rama aplico, para poder revertirlo al repetir la tirada.
    var aplicacion: RamaAplicada = RamaAplicada()
    /// El objetivo contra el que se tiro de verdad: la dificultad de la via
    /// elegida mas lo que le sumara el entorno (la oscuridad del pozo).
    var objetivo: Int? = nil
    /// Una prueba solo se repite una vez, venga la segunda tirada de un don o
    /// de un objeto gastado.
    var repetida: Bool = false
    var atributoUsado: Atributo { segundaVia?.atributo ?? prueba.atributo }
    var objetivoUsado: Int { objetivo ?? segundaVia?.dificultad.objetivo ?? prueba.objetivo }
}
