import Foundation

/// COMPAÑERO DE DESCENSO (§2095)
///
/// La decisión de con quién bajas a la Grieta era, hasta ahora, pura prosa:
/// cuatro opciones idénticas en lo mecánico. Cada compañero aporta ahora un
/// único efecto pasivo, permanente y sin gestión: no hay que gastarlo, ni
/// recordarlo por ronda, ni anotarlo más de una vez en la ficha.
///
/// Espejo de la tabla COMPANIONS de ../bookgame_web/lib/game-engine.ts.
struct Companero: Hashable, Identifiable {
    var id: String { flag }
    let flag: String
    let nombre: String
    let efecto: String
    var dano: Int = 0
    var defensa: Int = 0
    var pruebaDeVol: Int = 0
    var ecos: Int = 0

    static let todos: [Companero] = [
        Companero(flag: "BAJA_COMBE", nombre: "Combe",
                  efecto: "+1 al daño de tus ataques.", dano: 1),
        Companero(flag: "BAJA_ORWYN", nombre: "Orwyn",
                  efecto: "+1 a tu Defensa.", defensa: 1),
        Companero(flag: "BAJA_ILENA", nombre: "Ilena",
                  efecto: "+1 a tus pruebas de Voluntad.", pruebaDeVol: 1),
        Companero(flag: "BAJA_SOLA", nombre: "Nadie",
                  efecto: "+1 Eco máximo: bajas en solitario y la Grieta se oye entera.", ecos: 1),
    ]

    static func con(flag: String) -> Companero? {
        todos.first { $0.flag == flag }
    }

    static func para(flags: Set<String>) -> Companero? {
        todos.first { flags.contains($0.flag) }
    }
}
