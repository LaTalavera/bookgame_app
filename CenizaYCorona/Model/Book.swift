import Foundation

enum BookID: Int, CaseIterable, Identifiable, Codable, Hashable {
    case primero = 1
    case segundo = 2
    case tercero = 3

    var id: Int { rawValue }

    /// Cada libro ocupa su propio millar de identificadores.
    var offset: Int { (rawValue - 1) * 1000 }
    var startSection: Int { rawValue == 1 ? 1 : offset + 1 }
    var deathEnding: Int { offset + 900 }
    var corruptionEnding: Int { offset + 950 }

    var numeral: String {
        switch self {
        case .primero: return "I"
        case .segundo: return "II"
        case .tercero: return "III"
        }
    }

    var title: String {
        switch self {
        case .primero: return "La Marca Rota"
        case .segundo: return "El Trono Roto"
        case .tercero: return "La Cadena Rota"
        }
    }

    var tagline: String {
        switch self {
        case .primero: return "Naciste con una cicatriz, no con un nombre."
        case .segundo: return "Un trono vacío pesa más que uno ocupado."
        case .tercero: return "Todo juramento es una cadena."
        }
    }

    var next: BookID? { BookID(rawValue: rawValue + 1) }

    func contains(_ sectionID: Int) -> Bool { sectionID / 1000 == rawValue - 1 }

    static func containing(_ sectionID: Int) -> BookID {
        BookID(rawValue: sectionID / 1000 + 1) ?? .primero
    }
}

/// Qué se está jugando: un libro suelto o los tres encadenados.
enum PlayScope: Hashable, Codable {
    case book(BookID)
    case saga

    var startBook: BookID {
        switch self {
        case .book(let b): return b
        case .saga: return .primero
        }
    }

    var title: String {
        switch self {
        case .book(let b): return "Libro \(b.numeral) · \(b.title)"
        case .saga: return "Saga completa"
        }
    }

    /// En la saga, un final favorable encadena con el libro siguiente.
    var continuesBetweenBooks: Bool {
        if case .saga = self { return true }
        return false
    }
}
