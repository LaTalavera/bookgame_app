import Foundation

/// Los tres atributos del libro (Parte II, §11).
enum Atributo: String, CaseIterable, Identifiable, Codable, Hashable {
    case fue, agi, vol

    var id: String { rawValue }
    var sigla: String { rawValue.uppercased() }

    var nombre: String {
        switch self {
        case .fue: return "Fuerza"
        case .agi: return "Agilidad"
        case .vol: return "Voluntad"
        }
    }

    var descripcion: String {
        switch self {
        case .fue: return "músculo, resistencia, golpes cuerpo a cuerpo"
        case .agi: return "reflejos, puntería, sigilo"
        case .vol: return "carácter, magia, resistencia a la Sangre Vieja"
        }
    }
}

/// Las cuatro facciones que llevan cuenta. La Parte II §17 nombra tres;
/// el Favor Cortesano y el Vínculo aparecen en los libros segundo y tercero,
/// y el JSON los usa en sus `rep_delta`.
enum RepTrack: String, CaseIterable, Identifiable, Codable, Hashable {
    case orden
    case secta
    case losLibres = "los_libres"
    case favor
    case vinculo

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .orden: return "Orden de la Ceniza"
        case .secta: return "Secta de los Renacidos"
        case .losLibres: return "Los Libres"
        case .favor: return "Favor Cortesano"
        case .vinculo: return "Vínculo"
        }
    }

    var nombreCorto: String {
        switch self {
        case .orden: return "Orden"
        case .secta: return "Secta"
        case .losLibres: return "Libres"
        case .favor: return "Favor"
        case .vinculo: return "Vínculo"
        }
    }

    /// Los marcadores van de -5 a +5 (Parte II, §17).
    static let minimo = -5
    static let maximo = 5
}

/// Umbrales de Corrupción (Parte II, §16).
enum EstadoDeCorrupcion {
    case latente        // 0-3
    case despierta      // 4-6
    case mutando        // 7-9
    case perdido        // 10

    static func para(_ valor: Int) -> EstadoDeCorrupcion {
        switch valor {
        case ..<4: return .latente
        case 4...6: return .despierta
        case 7...9: return .mutando
        default: return .perdido
        }
    }

    var titulo: String {
        switch self {
        case .latente: return "Sin efecto aparente"
        case .despierta: return "Los animales te evitan"
        case .mutando: return "Empiezas a mutar"
        case .perdido: return "Te pierdes"
        }
    }

    var detalle: String {
        switch self {
        case .latente:
            return "Algunos Marcados y bestias sensibles a la Sangre Vieja pueden, aun así, notarte."
        case .despierta:
            return "Ciertas opciones oscuras se abren en el texto. Algunos NPC reaccionan con recelo."
        case .mutando:
            return "Has perdido 1 punto de VOL y ganado 1 de FUE. El texto empieza a llamarte «el Quebrado»."
        case .perdido:
            return "La Grieta deja de prestarte su poder. No es el final de tu historia, pero sí el de quién eras."
        }
    }
}

enum Reglas {
    /// Parte II, §13: tu Defensa base antes de sumar armadura y escudo.
    static let defensaBase = 8
    /// Parte II, §16.
    static let corrupcionMaxima = 10
    /// §13, el precio del don: usar el don de tu vocacion cuesta 1 Corrupcion.
    /// Antes solo lo pagaba la Vidente; ahora la Marca no distingue quien la llama.
    static let corrupcionPorDon = 1
    /// Parte III, §21: puntos libres a repartir sobre la vocación.
    static let puntosDePersonalizacion = 3
    static let maximoPorAtributo = 2
    /// Subida de nivel: puntos libres a repartir cada vez que cruzas a un
    /// libro nuevo (solo dos veces en toda la saga). Decisión de diseño, no
    /// del libro — ver REGLAS-Y-DATOS.md.
    static let puntosPorNivel = 1
    /// Parte II, §13: si tu atributo relevante es 7 o más, +1 de daño.
    static let umbralDeDanoExtra = 7
    /// Parte II, §14: espacios de mochila.
    static let espaciosDeMochila = 6
}
