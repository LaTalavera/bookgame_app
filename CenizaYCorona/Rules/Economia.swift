import Foundation

// ─────────────────────────────────────────────────────────────────────────────
//  ECONOMÍA — TRANSCRITA DEL LIBRO.
//  Solo hay dos momentos de compra en toda la saga: la armería del Puesto
//  (§72 y §73, en Esquirlas de la Orden) y los intendentes de la expedición
//  (§2103, en Coronas de Cárdenas). El Libro Segundo no tiene tienda.
// ─────────────────────────────────────────────────────────────────────────────

enum Moneda: String, Codable, Hashable, CaseIterable {
    case esquirlas
    case coronas

    var nombre: String {
        switch self {
        case .esquirlas: return "Esquirlas de la Orden"
        case .coronas: return "Coronas de Cárdenas"
        }
    }

    var corto: String {
        switch self {
        case .esquirlas: return "Esquirlas"
        case .coronas: return "Coronas"
        }
    }

    func contar(_ n: Int) -> String {
        switch self {
        case .esquirlas: return n == 1 ? "1 Esquirla" : "\(n) Esquirlas"
        case .coronas: return n == 1 ? "1 Corona" : "\(n) Coronas"
        }
    }
}

/// Lo que se lleva uno al comprar.
enum Mercancia: Hashable {
    case arma(Arma)
    case armadura(Armadura)
    case escudo
    case objeto(ObjetoDeMochila)
}

struct Articulo: Identifiable, Hashable {
    let nombre: String
    let precio: Int
    let mercancia: Mercancia
    var detalle: String = ""
    /// Requisito de atributo impreso en el catálogo, si lo hay.
    var requiere: (atributo: Atributo, minimo: Int)? = nil
    /// Se puede comprar más de una vez (consumibles).
    var repetible: Bool = false

    var id: String { nombre }

    static func == (a: Articulo, b: Articulo) -> Bool { a.nombre == b.nombre }
    func hash(into h: inout Hasher) { h.combine(nombre) }
}

/// Entregar un objeto de información a cambio de fondos (§72).
struct Venta: Identifiable, Hashable {
    let flag: String
    let nombre: String
    let importe: Int
    var id: String { flag }
}

struct Tienda {
    let seccion: Int
    let moneda: Moneda
    /// Fondos que se conceden al llegar, una sola vez.
    var fondos: Int = 0
    var ventas: [Venta] = []
    var articulos: [Articulo] = []
    var titulo: String = "Armería"
    var nota: String? = nil
}

enum Economia {

    static func tienda(en seccion: Int) -> Tienda? { tiendas[seccion] }

    static let tiendas: [Int: Tienda] = [

        // ── §72 — El armero: Brenna entrega los fondos, Orwyn compra información
        72: Tienda(
            seccion: 72,
            moneda: .esquirlas,
            fondos: 10,
            ventas: [
                Venta(flag: "MAPA_DE_LAS_FAUCES", nombre: "Mapa de las Fauces", importe: 5),
                Venta(flag: "TABLILLA_DE_ARCILLA_RUNICA", nombre: "Tablilla de Arcilla Rúnica", importe: 5),
            ],
            titulo: "El armero",
            nota: "«La Orden cubre los gastos de quien va a jugarse el cuello por ella.» No habrá otra oportunidad de comprar hasta que esto termine."),

        // ── §73 — La armería de Brenna
        73: Tienda(
            seccion: 73,
            moneda: .esquirlas,
            articulos: [
                Articulo(nombre: "Espada larga", precio: 4, mercancia: .arma(.espadaLarga),
                         detalle: "Daño 4.", requiere: (.fue, 5)),
                Articulo(nombre: "Hacha", precio: 4, mercancia: .arma(.hacha),
                         detalle: "Daño 4.", requiere: (.fue, 5)),
                Articulo(nombre: "Arco largo", precio: 5, mercancia: .arma(.arcoLargo),
                         detalle: "Daño 3, a distancia.", requiere: (.agi, 6)),
                Articulo(nombre: "Cota de malla", precio: 6, mercancia: .armadura(.malla),
                         detalle: "+2 Defensa, −1 a las pruebas de AGI.", requiere: (.fue, 5)),
                Articulo(nombre: "Escudo", precio: 3, mercancia: .escudo,
                         detalle: "+1 Defensa adicional."),
                Articulo(nombre: "Poción de curación", precio: 3, mercancia: .objeto(.pocionDeCuracion),
                         detalle: "Cura 2D6 de Vida. Un uso.", repetible: true),
                Articulo(nombre: "Frasco de fuego alquímico", precio: 3, mercancia: .objeto(.fuegoAlquimico),
                         detalle: "Daño 5 que ignora la Defensa. Un uso.", repetible: true),
                Articulo(nombre: "Cuerda de escalada", precio: 2, mercancia: .objeto(.cuerda),
                         detalle: "Amarrada a un descenso, repites una prueba de AGI fallida. Se queda allí."),
                Articulo(nombre: "Ganzúas", precio: 2, mercancia: .objeto(.ganzuas),
                         detalle: "Superas sin tirar las cerraduras que el texto permite forzar con ellas."),
                Articulo(nombre: "Yesca", precio: 2, mercancia: .objeto(.yesca),
                         detalle: "Luz improvisada: anula por una prueba el peldaño de oscuridad del pozo."),
            ],
            titulo: "La armería"),

        // ── §2103 — Los intendentes de las Casas
        2103: Tienda(
            seccion: 2103,
            moneda: .coronas,
            fondos: 12,
            articulos: [
                Articulo(nombre: "Cuerda imperial reforzada", precio: 3, mercancia: .objeto(.cuerdaImperial),
                         detalle: "Amarrada al descenso, repites una prueba de AGI fallida. Se queda allí."),
                Articulo(nombre: "Lámpara de aceite pesado", precio: 2, mercancia: .objeto(.lamparaDeAceite),
                         detalle: "Sin ella, las pruebas del pozo se hacen a un nivel más de dificultad."),
                Articulo(nombre: "Yesca", precio: 1, mercancia: .objeto(.yesca),
                         detalle: "Luz improvisada: anula por una prueba el peldaño de oscuridad del pozo.", repetible: true),
                Articulo(nombre: "Poción de sangre asentada", precio: 4, mercancia: .objeto(.sangreAsentada),
                         detalle: "Recupera 2D6 de Vida.", repetible: true),
                Articulo(nombre: "Amuleto de plomo de la Orden", precio: 4, mercancia: .objeto(.amuletoDePlomo),
                         detalle: "Una vez por libro, ignora un punto de Corrupción."),
                Articulo(nombre: "Raciones de montaña", precio: 1, mercancia: .objeto(.racionesDeMontana),
                         detalle: "Un Descanso adicional donde elijas.", repetible: true),
            ],
            titulo: "Preparativos",
            nota: "Última oportunidad de reforzar el equipo antes de bajar al pozo."),
    ]
}
