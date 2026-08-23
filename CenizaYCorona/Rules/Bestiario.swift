import Foundation

// ─────────────────────────────────────────────────────────────────────────────
//  BESTIARIO — EXTRAÍDO DEL PROPIO LIBRO.
//  Cada ficha sale de la línea "◈ NOMBRE — Defensa N · Vida N · Ataque +N ·
//  Daño N" del texto de su sección. No hay nada inventado aquí: si cambias el
//  texto de una sección en saga.json, actualiza también la ficha de abajo.
// ─────────────────────────────────────────────────────────────────────────────

struct EnemyStats: Hashable {
    let nombre: String
    /// Lo que tu tirada de ataque tiene que igualar o superar.
    let defensa: Int
    let vida: Int
    /// Modificador que el enemigo suma a sus 2D6 contra tu Defensa.
    let ataque: Int
    /// Daño fijo, como en el libro.
    let dano: Int
}

enum Bestiario {
    /// Ficha por sección: el mismo nombre puede tener números distintos
    /// según el encuentro (por ejemplo el Custodio asistido de §16).
    static let porSeccion: [Int: EnemyStats] = [
        3: EnemyStats(nombre: "FANÁTICO RENACIDO", defensa: 8, vida: 12, ataque: 2, dano: 3),
        4: EnemyStats(nombre: "CUSTODIO DE GRIETA", defensa: 10, vida: 16, ataque: 3, dano: 4),
        14: EnemyStats(nombre: "LOBO QUEBRADO", defensa: 8, vida: 10, ataque: 2, dano: 3),
        16: EnemyStats(nombre: "CUSTODIO DE GRIETA (asistido)", defensa: 10, vida: 16, ataque: 3, dano: 4),
        20: EnemyStats(nombre: "BANDADA DE CUERVOS DE CRISTAL", defensa: 7, vida: 8, ataque: 1, dano: 2),
        33: EnemyStats(nombre: "ESPINA ANDANTE", defensa: 9, vida: 18, ataque: 2, dano: 4),
        38: EnemyStats(nombre: "RENEGADO VARDO", defensa: 8, vida: 11, ataque: 2, dano: 2),
        42: EnemyStats(nombre: "BANDADA DE CUERVOS DE CRISTAL", defensa: 7, vida: 8, ataque: 1, dano: 2),
        53: EnemyStats(nombre: "FANÁTICO RENACIDO", defensa: 8, vida: 12, ataque: 2, dano: 3),
        59: EnemyStats(nombre: "SAQUEADOR DE LA ESTEPA", defensa: 9, vida: 14, ataque: 2, dano: 3),
        86: EnemyStats(nombre: "ARAÑA DE GRIETA", defensa: 10, vida: 16, ataque: 3, dano: 3),
        94: EnemyStats(nombre: "ECO ERRANTE", defensa: 9, vida: 10, ataque: 2, dano: 3),
        101: EnemyStats(nombre: "FANÁTICO RENACIDO x2 (o x1 con acompañante)", defensa: 8, vida: 12, ataque: 2, dano: 3),
        109: EnemyStats(nombre: "CENTINELA ROTO", defensa: 11, vida: 20, ataque: 3, dano: 4),
        118: EnemyStats(nombre: "CUSTODIO DE GRIETA", defensa: 10, vida: 16, ataque: 3, dano: 4),
        122: EnemyStats(nombre: "EL PADRE CENIZA", defensa: 10, vida: 22, ataque: 2, dano: 3),
        126: EnemyStats(nombre: "QUEBRADO MAYOR", defensa: 12, vida: 40, ataque: 4, dano: 6),
        1022: EnemyStats(nombre: "SABUESO DEL CENSO", defensa: 10, vida: 14, ataque: 3, dano: 3),
        1046: EnemyStats(nombre: "GUARDIA DE PALACIO x2", defensa: 9, vida: 13, ataque: 2, dano: 3),
        1068: EnemyStats(nombre: "ESPADACHÍN DE CASA RIVAL", defensa: 11, vida: 15, ataque: 3, dano: 4),
        1118: EnemyStats(nombre: "QUEBRADO MENOR", defensa: 9, vida: 14, ataque: 2, dano: 3),
        1127: EnemyStats(nombre: "GUARDIA DE PALACIO x2", defensa: 9, vida: 13, ataque: 2, dano: 3),
        1137: EnemyStats(nombre: "EL GUARDIÁN DEL CENSO", defensa: 13, vida: 44, ataque: 4, dano: 6),
        1143: EnemyStats(nombre: "LA DUQUESA ILLIANA ORDAZ", defensa: 10, vida: 20, ataque: 3, dano: 4),
        2016: EnemyStats(nombre: "GUARDIÁN DE CALZADA", defensa: 12, vida: 22, ataque: 3, dano: 5),
        2029: EnemyStats(nombre: "ANCLA VIVIENTE", defensa: 10, vida: 20, ataque: 2, dano: 4),
        2033: EnemyStats(nombre: "ERRANTE DEL CONFÍN", defensa: 10, vida: 15, ataque: 3, dano: 4),
        2052: EnemyStats(nombre: "ERRANTE DEL CONFÍN", defensa: 11, vida: 17, ataque: 3, dano: 4),
        2068: EnemyStats(nombre: "COSA DE ESLABÓN", defensa: 11, vida: 18, ataque: 3, dano: 4),
        2080: EnemyStats(nombre: "GUARDIÁN DE CALZADA", defensa: 12, vida: 20, ataque: 3, dano: 5),
        2115: EnemyStats(nombre: "COSA DE ESLABÓN", defensa: 12, vida: 20, ataque: 3, dano: 4),
        2136: EnemyStats(nombre: "EL PRIMER LIGADO", defensa: 13, vida: 34, ataque: 4, dano: 5),
        2147: EnemyStats(nombre: "ASHKELEN, EL DURMIENTE", defensa: 13, vida: 42, ataque: 4, dano: 7)
    ]

    /// Si una sección de combate no tuviera ficha, se deduce del libro al que
    /// pertenece para que la partida nunca se quede sin números.
    static func stats(para seccion: Int, enemigo: String) -> EnemyStats {
        if let ficha = porSeccion[seccion] { return ficha }
        let paso = BookID.containing(seccion).rawValue - 1
        return EnemyStats(nombre: enemigo, defensa: 9 + paso, vida: 14 + paso * 4,
                          ataque: 2 + paso, dano: 3 + paso)
    }
}
