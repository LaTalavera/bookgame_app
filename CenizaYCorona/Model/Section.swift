import Foundation

/// Una ilustración pendiente: por ahora solo existe como ficha de arte en texto.
struct Illustration: Codable, Hashable {
    let caption: String
    let brief: String
}

/// El bloque `combat` del JSON. El enemigo llega solo como nombre;
/// sus estadísticas viven en `Bestiary`.
struct CombatData: Codable, Hashable {
    let enemy: String
    let onWin: Int
    let onLose: Int
    let notes: String?

    /// Un combate es letal cuando la derrota lleva a un final de muerte (§x900).
    /// Se deduce del propio JSON, no hace falta anotarlo a mano.
    var esLetal: Bool { onLose % 1000 == 900 }

    /// Los combates tutoriales del prólogo llevan a la misma sección ganes o
    /// pierdas: el texto dice que ahí no mueres, te dejan con 1 de Vida.
    var esTutorial: Bool { onWin == onLose }
}

struct Choice: Codable, Hashable, Identifiable {
    /// 297 de las 493 elecciones vienen con `text: null`: son tránsitos
    /// lineales de una sección a la siguiente, sin decisión que tomar.
    let text: String?
    let target: Int
    let requires: String?
    let setsFlag: String?

    var id: String { "\(target)|\(text ?? "")" }

    var esTransito: Bool { (text ?? "").trimmingCharacters(in: .whitespaces).isEmpty }

    /// Lo que se enseña en el botón.
    func etiqueta(unicaOpcion: Bool) -> String {
        if let text, !text.trimmingCharacters(in: .whitespaces).isEmpty { return text }
        return unicaOpcion ? "Continuar" : "Ir a la sección \(target)"
    }
}

struct Section: Codable, Hashable, Identifiable {
    let id: Int
    let thread: String
    let title: String
    let illustration: Illustration?
    let text: String
    let combat: CombatData?
    let choices: [Choice]
    let setsFlags: [String]
    let repDelta: [String: Int]
    let libro: String

    /// El texto viene con párrafos separados por línea en blanco.
    var paragraphs: [String] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Un final: ni elecciones ni combate del que salir. Las secciones que
    /// mandan consultar la tabla de finales (§133, §1145, §2150) tampoco
    /// tienen elecciones, pero no son finales: se resuelven aparte.
    var esFinal: Bool {
        choices.isEmpty && combat == nil
            && !TablaDeFinales.secciones.contains(id)
            && !esReservada
    }

    /// §134 y compañía: huecos marcados "(reservada)" para ampliaciones futuras.
    var esReservada: Bool { title.hasPrefix("(") }

    /// Parte II, §18: el texto marca los descansos con 🕯.
    var esPuntoDeDescanso: Bool {
        text.contains("🕯") || text.contains("Punto de Descanso")
    }

    /// "FINAL 4 — Una promesa cumplida" -> "Una promesa cumplida".
    var tituloSinPrefijo: String {
        guard let raya = title.range(of: "—") else { return title }
        return String(title[raya.upperBound...]).trimmingCharacters(in: .whitespaces)
    }

    /// La ficha del enemigo, si esta sección es un combate.
    var enemigo: EnemyStats? {
        guard let combat else { return nil }
        return Bestiario.stats(para: id, enemigo: combat.enemy)
    }
}
