import Foundation

// ─────────────────────────────────────────────────────────────────────────────
//  REGLAS ESPECIALES DE COMBATE — TRANSCRITAS DE LA PROSA DEL LIBRO.
//  Diecinueve de los treinta y tres combates traen una línea "*Especial: …*"
//  en su texto. Aquí están todas, con el número de sección del que salen.
// ─────────────────────────────────────────────────────────────────────────────

/// Una salida que no pasa por matar al enemigo.
struct Parlamento: Hashable {
    enum Requisito: Hashable {
        case vidaEnemigoBajaDe(Int)        // el enemigo pide tregua
        case marcador(RepTrack, minimo: Int)
    }
    var requisito: Requisito
    var atributo: Atributo
    var dificultad: Dificultad
    var flagAlSuperarla: String?
    var repAlSuperarla: (RepTrack, Int)?
    var destino: Int
    var invitacion: String
    var alFallar: String

    static func == (a: Parlamento, b: Parlamento) -> Bool {
        a.destino == b.destino && a.invitacion == b.invitacion
    }
    func hash(into h: inout Hasher) { h.combine(destino); h.combine(invitacion) }
}

/// Una salida que evita el combate entero, propia de una vocación.
/// La abre cualquiera, pero a quien está hecha para ello le sale un peldaño
/// de dificultad más barato: la Vigía no es vista, la Vidente habla con lo
/// que está hecho de Sangre Vieja.
struct SalidaDeVocacion: Hashable {
    var vocacion: Vocacion
    var atributo: Atributo
    /// Dificultad para la vocación propia; el resto la intenta un peldaño más arriba.
    var dificultad: Dificultad
    var titulo: String
    var invitacion: String
    var exito: String
    var alFallar: String
    /// Solo se puede intentar antes de dar el primer golpe.
    var antesDeGolpear: Bool = true

    func dificultad(para v: Vocacion) -> Dificultad? {
        if v == vocacion { return dificultad }
        switch dificultad {
        case .facil: return .media
        case .media: return .dificil
        case .dificil: return .heroica
        case .heroica: return nil   // ya es lo más alto: exclusiva de hecho
        }
    }
}

/// Todo lo que el texto añade a un combate concreto.
struct ReglaDeCombate {
    /// La salida propia de una vocación que evita el combate entero.
    var salida: SalidaDeVocacion? = nil
    /// "resta N al daño que le inflijas".
    var reduceDano: Int = 0
    /// Si es cierto, esa reducción no se aplica al daño mágico ni a los Dones Forzados.
    var reduccionSoloConvencional: Bool = false
    /// El enemigo abandona al bajar de esta Vida y la historia sigue por on_win.
    var huyeConVidaMenorDe: Int? = nil
    /// Se rinde si le ganas N rondas seguidas sin recibir daño.
    var seRindeTrasRondasLimpias: Int? = nil
    /// Se retira si pierde la iniciativa N rondas seguidas.
    var seRetiraTrasPerderIniciativa: Int? = nil
    /// Ataca siempre primero en el primer asalto.
    var atacaPrimeroSiempre: Bool = false
    /// Son dos y se estorban: el segundo golpe de cada ronda va con -1.
    var segundoAtaqueConPenalizacion: Bool = false
    /// Cada golpe que le das cuesta una prueba de VOL o 1 Eco (y 1 Vida si no hay).
    var costeDeGolpearVOL: Dificultad? = nil
    /// Al caer libera Sangre Vieja: prueba de VOL o +1 Corrupción.
    var descargaAlCaerVOL: Dificultad? = nil
    /// Su primer ataque exige una prueba de FUE o pierdes tu siguiente ronda.
    var primerAtaqueExigeFUE: Dificultad? = nil
    /// Inmune a hechizos mentales o de susurro.
    var inmuneAMentales: Bool = false
    /// Con esta palabra clave, tu primer ataque acierta sin tirada.
    var primerGolpeAutomaticoCon: String? = nil
    /// Ayuda de un acompañante: resta esto a las tiradas de ataque del enemigo.
    var penalizacionAlEnemigo: Int = 0
    /// La salida negociada, si el texto la ofrece.
    var parlamento: Parlamento? = nil
    /// Las elecciones propias de la sección se habilitan al bajar de esta Vida.
    var umbralDeSalida: Int? = nil
    var nota: String? = nil
}

extension SalidaDeVocacion {
    /// La Vigía Errante cazaba en la linde de la Grieta: sabe no estar.
    static func sigilo(_ dif: Dificultad, _ invitacion: String, _ exito: String) -> SalidaDeVocacion {
        SalidaDeVocacion(vocacion: .vigia, atributo: .agi, dificultad: dif,
                         titulo: "Pasar sin ser visto", invitacion: invitacion, exito: exito,
                         alFallar: "Te oyen. Ya no hay forma de evitarlo.")
    }
    /// La Vidente Rota está hecha de lo mismo que ellos.
    static func hablar(_ dif: Dificultad, _ invitacion: String, _ exito: String) -> SalidaDeVocacion {
        SalidaDeVocacion(vocacion: .vidente, atributo: .vol, dificultad: dif,
                         titulo: "Hablarle", invitacion: invitacion, exito: exito,
                         alFallar: "Lo que queda dentro no entiende ya ninguna lengua.")
    }
    static func imponerse(_ dif: Dificultad, _ invitacion: String, _ exito: String) -> SalidaDeVocacion {
        SalidaDeVocacion(vocacion: .cuchilla, atributo: .fue, dificultad: dif,
                         titulo: "Imponerse", invitacion: invitacion, exito: exito,
                         alFallar: "Confunde tu advertencia con una invitación.")
    }
    static func tregua(_ dif: Dificultad, _ invitacion: String, _ exito: String) -> SalidaDeVocacion {
        SalidaDeVocacion(vocacion: .penitente, atributo: .vol, dificultad: dif,
                         titulo: "Invocar tregua", invitacion: invitacion, exito: exito,
                         alFallar: "El juramento que sirve ahora no admite tregua.")
    }
}

enum ReglasEspeciales {

    static func regla(en seccion: Int) -> ReglaDeCombate? { tabla[seccion] }
    static func parlamento(en seccion: Int) -> Parlamento? { tabla[seccion]?.parlamento }

    static func salidasDisponibles(seccion: Int, vidaEnemigo: Int) -> Bool {
        guard let umbral = tabla[seccion]?.umbralDeSalida else { return true }
        return vidaEnemigo < umbral
    }

    static let tabla: [Int: ReglaDeCombate] = [

        // §14 — «si su Vida baja de 4, huye hacia la oscuridad»
        14: ReglaDeCombate(salida: .hablar(.media, "Debajo de la rabia todavía hay un lobo. Puedes intentar alcanzarlo antes de que salte.", "El animal se detiene en seco, tiembla, y se va por donde vino sin mirar atrás."),
                            huyeConVidaMenorDe: 4,
                           nota: "Si baja de 4 de Vida, el lobo huye hacia la oscuridad."),

        // §16 — «Ayuda de Cael: -2 a las tiradas de ataque del enemigo»
        16: ReglaDeCombate(penalizacionAlEnemigo: 2,
                           nota: "Cael te cubre: el Custodio ataca con −2."),

        // §33 — «resta 1 al daño que le inflijas (mínimo 1)»
        33: ReglaDeCombate(salida: .sigilo(.media, "La Espina no persigue: espera. Se puede rodear si sabes dónde no pisar.", "La rodeáis por el arroyo seco. Ni se entera de que habéis pasado."), reduceDano: 1, nota: "Su corteza absorbe parte de cada golpe."),

        // §38 — «si le ganas dos rondas seguidas sin recibir daño, se rinde»
        38: ReglaDeCombate(seRindeTrasRondasLimpias: 2,
                           nota: "Si le ganas dos rondas seguidas sin que te toque, se rinde y huye."),

        // §86 — «en su primer ataque, si acierta, superas una prueba de FUE Media»
        86: ReglaDeCombate(salida: .sigilo(.dificil, "La araña cuelga sobre el desfiladero. Hay una repisa por la que se puede cruzar.", "Cruzáis por la repisa. La araña sigue esperando algo que ya no va a pasar por debajo."),
                            primerAtaqueExigeFUE: .media,
                           nota: "Su primer mordisco puede dejarte sin la siguiente ronda."),

        // §109 — «inmune a hechizos de susurro/mentales»
        109: ReglaDeCombate(inmuneAMentales: true,
                            nota: "Un autómata no escucha susurros."),

        // §122 — «con VENTAJA DE SIGILO, tu primer ataque es automático»
        122: ReglaDeCombate(primerGolpeAutomaticoCon: "VENTAJA_DE_SIGILO", umbralDeSalida: 8,
                            nota: "A Vida 8 o menos ofrece tregua."),

        126: ReglaDeCombate(salida: .hablar(.heroica, "Bajo las placas del Quebrado Mayor aún resuena el nombre que perdió.", "Pronuncias ese nombre y la criatura se aparta, estremecida por un recuerdo que no puede combatir.")),

        // §1022 — el Sabueso detecta la Corrupción
        1022: ReglaDeCombate(nota: "Detecta Corrupción de 4 o más salvo ocultación previa (AGI Difícil)."),

        // §1046 y §1127 — «el segundo guardia en atacar cada ronda lo hace con -1»
        1046: ReglaDeCombate(salida: .sigilo(.dificil, "Los guardias registran el sótano por turnos. Hay una ventana de tres respiraciones.", "Sacas a todo el mundo por la carbonera antes de que el segundo turno baje."),
                              segundoAtaqueConPenalizacion: true,
                             nota: "Se estorban entre ellos en el sótano."),
        1127: ReglaDeCombate(salida: .sigilo(.dificil, "El puesto de control tiene un ángulo muerto en la escalera.", "Subís pegados al muro. Los dos guardias siguen mirando la puerta equivocada."),
                              segundoAtaqueConPenalizacion: true,
                             nota: "Se estorban entre ellos en la escalera."),

        // §1068 — «si pierde la iniciativa dos rondas seguidas, se retira»
        1068: ReglaDeCombate(salida: .imponerse(.dificil, "El espadachín pelea por paga y prestigio. Puedes demostrarle que ninguno compensa este duelo.", "Lee tu guardia, calcula el precio y decide conservar el nombre."),
                             seRetiraTrasPerderIniciativa: 2,
                             nota: "No va a morir por un encargo: si le ganas la iniciativa dos veces seguidas, se retira."),

        // §1118 — «al caer, libera una descarga de Sangre Vieja»
        1118: ReglaDeCombate(salida: .hablar(.media, "El Quebrado Menor conserva un gesto humano: se cubre los ojos de la luz.", "Se aparta. No entiende lo que le dices, pero reconoce que no vienes a matarlo."),
                              descargaAlCaerVOL: .media,
                             nota: "Al caer libera Sangre Vieja."),

        // §1143 — la tregua con Ordaz (rama añadida al libro)
        1143: ReglaDeCombate(parlamento: Parlamento(
            requisito: .vidaEnemigoBajaDe(6), atributo: .vol, dificultad: .dificil,
            flagAlSuperarla: "ORDAZ_CONVENCIDA", repAlSuperarla: nil, destino: 1144,
            invitacion: "Ordaz flaquea. Puedes bajar el arma y parlamentar en vez de rematarla.",
            alFallar: "No te escucha. El combate continúa.")),

        // §2016 y §2080 — «resta 2 al daño de armas convencionales; el mágico le afecta por completo»
        2016: ReglaDeCombate(reduceDano: 2, reduccionSoloConvencional: true,
                             nota: "La piedra apaga el acero. La Sangre Vieja no."),
        2080: ReglaDeCombate(reduceDano: 2, reduccionSoloConvencional: true,
                             nota: "La piedra apaga el acero. La Sangre Vieja no."),

        // §2029 — «si tu Vínculo es 4 o más, puedes hablar con ella en vez de combatir»
        2029: ReglaDeCombate(parlamento: Parlamento(
            requisito: .marcador(.vinculo, minimo: 4), atributo: .vol, dificultad: .media,
            flagAlSuperarla: nil, repAlSuperarla: (.vinculo, 1), destino: 2030,
            invitacion: "El Ancla todavía recuerda lo que fue. Puedes intentar hablarle.",
            alFallar: "No queda nada que escuche. Los filamentos se tensan.")),

        // §2033 y §2052 — «ataca siempre primero en el primer asalto»
        2033: ReglaDeCombate(salida: .sigilo(.dificil, "Los Errantes cazan por vibración. Si nadie se mueve, no hay nada que cazar.", "Os quedáis quietos en la nieve hasta que pasan de largo."), atacaPrimeroSiempre: true, nota: "Cae sobre ti antes de que lo veas."),
        2052: ReglaDeCombate(salida: .sigilo(.dificil, "Vienen por el flanco, pero todavía no saben cuántos sois ni dónde.", "Los desvías con un rastro falso y se pierden por el barranco equivocado."), atacaPrimeroSiempre: true, nota: "Cae sobre ti antes de que lo veas."),

        // §2068 y §2115 — «cada vez que le causas daño, prueba de VOL Fácil o pierdes 1 Eco»
        2068: ReglaDeCombate(salida: .hablar(.dificil, "La Cosa de Eslabón es cadena rota, igual que tú. Puedes intentar decírselo.", "Se detiene. Por un instante los filamentos se ordenan, y os deja pasar."),
                              costeDeGolpearVOL: .facil,
                             nota: "Tocarla cuesta: cada golpe te arranca un Eco."),
        2115: ReglaDeCombate(salida: .hablar(.dificil, "Otra vez lo mismo, y esta vez ya sabes qué decirle.", "Se aparta sin que tengas que levantar la voz."),
                              costeDeGolpearVOL: .facil,
                             nota: "Tocarla cuesta: cada golpe te arranca un Eco."),
        20: ReglaDeCombate(salida: .sigilo(.media, "Los cuervos de cristal cazan por reflejo del sonido. Todavía no os han fijado.", "Pasáis por debajo de la bandada sin que un solo cristal se gire.")),
        42: ReglaDeCombate(salida: .sigilo(.media, "La bandada vuelve a girar sobre el campamento. Todavía puedes sacar a la gente sin ruido.", "Los sacáis a todos en silencio, pegados a la pared de roca.")),
        53: ReglaDeCombate(salida: .tregua(.media, "El fanático todavía reconoce el símbolo de una fe anterior a la Secta.", "Duda lo bastante para dejarte pasar sin derramar más sangre.")),
        59: ReglaDeCombate(salida: .sigilo(.media, "El saqueador todavía no te ha visto. Podrías dejar que siga su camino.", "Lo dejas pasar a tres pasos de ti, sin aliento, y no llega a saber que estuviste ahí.")),
        94: ReglaDeCombate(salida: .hablar(.facil, "El Eco no ataca: repite. Es un recuerdo atrapado, y todavía tiene nombre.", "Le dices el nombre en voz alta y el Eco se deshace, aliviado, sin un ruido.")),
        101: ReglaDeCombate(salida: .imponerse(.media, "Los dos fanáticos esperan una presa aislada, no alguien dispuesto a romper su formación.", "Tu avance les obliga a abrirse y retirarse antes de quedar atrapados.")),
        118: ReglaDeCombate(salida: .tregua(.dificil, "Bajo la armadura del Custodio queda una disciplina que aún puede reconocer un juramento.", "Baja el arma un instante y acepta que el paso no merece otra muerte.")),
    ]
}
