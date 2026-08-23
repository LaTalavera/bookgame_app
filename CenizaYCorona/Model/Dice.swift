import Foundation

/// Parte II, §12: las cuatro dificultades del libro.
enum Dificultad: Int, CaseIterable, Identifiable, Hashable {
    case facil = 7
    case media = 9
    case dificil = 11
    case heroica = 13

    var id: Int { rawValue }

    var nombre: String {
        switch self {
        case .facil: return "Fácil"
        case .media: return "Media"
        case .dificil: return "Difícil"
        case .heroica: return "Heroica"
        }
    }

    var objetivo: Int { rawValue }
}

struct Tirada: Codable, Hashable {
    let d1: Int
    let d2: Int
    let modificador: Int

    var suma: Int { d1 + d2 }
    var total: Int { suma + modificador }

    /// El libro no define pifias ni críticos: 2D6 + atributo contra un número.
    func alcanza(_ objetivo: Int) -> Bool { total >= objetivo }
}

enum Dados {
    static func d6() -> Int { Int.random(in: 1...6) }

    static func tirar2D6(modificador: Int = 0) -> Tirada {
        Tirada(d1: d6(), d2: d6(), modificador: modificador)
    }

    /// Para curaciones del tipo "1D6+2".
    static func tirarD6(cantidad: Int = 1, mas bonus: Int = 0) -> Int {
        var total = bonus
        for _ in 0..<cantidad { total += d6() }
        return total
    }
}
