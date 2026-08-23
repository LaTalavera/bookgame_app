import Foundation

/// Parte II, §14. El daño de las armas es fijo.
struct Arma: Hashable, Codable, Identifiable {
    enum Uso: String, Codable, Hashable {
        case cuerpoACuerpo, distancia, foco

        /// Parte II, §13: FUE cuerpo a cuerpo, AGI a distancia, VOL al lanzar.
        var atributo: Atributo {
            switch self {
            case .cuerpoACuerpo: return .fue
            case .distancia: return .agi
            case .foco: return .vol
            }
        }
    }

    var id: String { nombre }
    let nombre: String
    let dano: Int
    let uso: Uso
    var nota: String? = nil
    /// El arco corto ataca primero en la primera ronda.
    var atacaPrimeroLaPrimeraRonda: Bool = false
    /// El mandoble ataca el último de la ronda.
    var atacaUltimo: Bool = false

    static let daga = Arma(nombre: "Daga", dano: 2, uso: .cuerpoACuerpo, nota: "Puede lanzarse (usa AGI).")
    static let espadaCorta = Arma(nombre: "Espada corta", dano: 3, uso: .cuerpoACuerpo)
    static let espadaLarga = Arma(nombre: "Espada larga", dano: 4, uso: .cuerpoACuerpo, nota: "Requiere FUE 5+.")
    static let hacha = Arma(nombre: "Hacha", dano: 4, uso: .cuerpoACuerpo, nota: "Requiere FUE 5+.")
    static let maza = Arma(nombre: "Maza", dano: 4, uso: .cuerpoACuerpo)
    static let mandoble = Arma(nombre: "Mandoble", dano: 5, uso: .cuerpoACuerpo,
                               nota: "Requiere FUE 7+; atacas último en la ronda.",
                               atacaUltimo: true)
    static let arcoCorto = Arma(nombre: "Arco corto", dano: 3, uso: .distancia,
                                nota: "Atacas primero en la primera ronda de cualquier combate.",
                                atacaPrimeroLaPrimeraRonda: true)
    static let arcoLargo = Arma(nombre: "Arco largo", dano: 3, uso: .distancia, nota: "Requiere AGI 6+.")
    static let baston = Arma(nombre: "Bastón", dano: 3, uso: .cuerpoACuerpo,
                             nota: "Foco mágico: necesario para ciertos hechizos.")
    static let simboloSagrado = Arma(nombre: "Símbolo sagrado", dano: 0, uso: .foco,
                                     nota: "Foco para los dones de Penitente.")
    /// La honda que Bren te dejó en Valcenar. No se compra ni se cambia: la
    /// tienes solo si conservas la palabra clave HONDA_DE_BREN.
    static let hondaDeBren = Arma(nombre: "Honda de Bren", dano: 2, uso: .distancia,
                                  nota: "Atacas primero en la primera ronda. Solo si conservas la honda de Bren.",
                                  atacaPrimeroLaPrimeraRonda: true)
}

struct Armadura: Hashable, Codable, Identifiable {
    var id: String { nombre }
    let nombre: String
    let bonoDefensa: Int
    var nota: String? = nil

    static let ropas = Armadura(nombre: "Ropas de viaje", bonoDefensa: 0)
    static let cuero = Armadura(nombre: "Cuero reforzado", bonoDefensa: 1)
    static let ligera = Armadura(nombre: "Armadura ligera", bonoDefensa: 1)
    static let malla = Armadura(nombre: "Cota de malla", bonoDefensa: 2,
                                nota: "Requiere FUE 5+; -1 a pruebas de AGI.")
    static let escudo = Armadura(nombre: "Escudo", bonoDefensa: 1, nota: "Ocupa una mano.")
}

/// Lo que va en los 6 espacios de mochila.
struct ObjetoDeMochila: Hashable, Codable, Identifiable {
    var id: String { nombre }
    let nombre: String
    var descripcion: String = ""
    /// Curación al usarlo, si la tiene: (dados, bonus).
    var curaD6: Int = 0
    var curaBonus: Int = 0
    var consumible: Bool = false
    /// Daño directo que ignora la Defensa (fuego alquímico).
    var danoDirecto: Int = 0
    /// Permite un Descanso fuera de un Punto de Descanso (raciones de montaña).
    var permiteDescanso: Bool = false

    var cura: Bool { curaD6 > 0 || curaBonus > 0 }

    static let racion = ObjetoDeMochila(nombre: "Ración de viaje",
                                        descripcion: "Provisiones para el camino.", consumible: true)
    static let venda = ObjetoDeMochila(nombre: "Venda",
                                       descripcion: "Cura 1D6 PV. Un solo uso.",
                                       curaD6: 1, consumible: true)
    static let cuerda = ObjetoDeMochila(nombre: "Cuerda de escalada",
                                        descripcion: "Amarrada a un descenso, te deja repetir una prueba de AGI fallida. Se queda allí.")
    static let yesca = ObjetoDeMochila(nombre: "Yesca", descripcion: "Luz improvisada: anula por una prueba el peldaño de oscuridad del pozo. Se gasta.")
    static let tintaDeGrieta = ObjetoDeMochila(nombre: "Frasco de tinta de Grieta",
                                               descripcion: "Anota lo que la Grieta te dicta: repite una prueba de VOL fallida. Un uso.")
    static let velaBendita = ObjetoDeMochila(nombre: "Vela bendita",
                                             descripcion: "Arde donde no debería arder.")
    // ── Comprables en las tiendas del libro ──────────────────────────────
    static let ganzuas = ObjetoDeMochila(nombre: "Ganzúas",
                                         descripcion: "Abren cerraduras: superas sin tirar las pruebas que el texto permite forzar con ellas. No se gastan.")
    static let fuegoAlquimico = ObjetoDeMochila(nombre: "Frasco de fuego alquímico",
                                                descripcion: "Daño 5 contra un enemigo, ignora su Defensa. Un uso.",
                                                consumible: true, danoDirecto: 5)
    static let cuerdaImperial = ObjetoDeMochila(nombre: "Cuerda imperial reforzada",
                                                descripcion: "Amarrada al descenso, te deja repetir una prueba de AGI fallida. Se queda allí.")
    static let lamparaDeAceite = ObjetoDeMochila(nombre: "Lámpara de aceite pesado",
                                                 descripcion: "Sin ella, las pruebas del pozo se hacen a un nivel más de dificultad.")
    static let sangreAsentada = ObjetoDeMochila(nombre: "Poción de sangre asentada",
                                                descripcion: "Recupera 2D6 de Vida en cualquier momento.",
                                                curaD6: 2, consumible: true)
    static let amuletoDePlomo = ObjetoDeMochila(nombre: "Amuleto de plomo de la Orden",
                                                descripcion: "Una vez por libro, ignora un punto de Corrupción que fueras a ganar.")
    static let racionesDeMontana = ObjetoDeMochila(nombre: "Raciones de montaña",
                                                   descripcion: "Permiten un Descanso adicional donde elijas.",
                                                   consumible: true, permiteDescanso: true)

    static let pocionDeCuracion = ObjetoDeMochila(nombre: "Poción de curación",
                                                  descripcion: "Cura 2D6 PV. Un solo uso.",
                                                  curaD6: 2, consumible: true)
}
