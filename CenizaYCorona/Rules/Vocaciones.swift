import Foundation

/// Parte III, §20. Las cuatro vocaciones, tal y como vienen en el libro.
enum Vocacion: String, CaseIterable, Identifiable, Codable, Hashable {
    case cuchilla   // Cuchilla de Ceniza
    case vigia      // Vigía Errante
    case vidente    // Vidente Rota
    case penitente  // Penitente

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .cuchilla: return "Cuchilla de Ceniza"
        case .vigia: return "Vigía Errante"
        case .vidente: return "Vidente Rota"
        case .penitente: return "Penitente"
        }
    }

    var arquetipo: String {
        switch self {
        case .cuchilla: return "guerrera / guerrero"
        case .vigia: return "exploradora / explorador"
        case .vidente: return "hechicera marcada"
        case .penitente: return "guerrera / guerrero de la fe vieja"
        }
    }

    var presentacion: String {
        switch self {
        case .cuchilla:
            return "Aprendiste a pelear antes que a leer. En Valcenar entrenabas con la guardia del pueblo; ahora esa disciplina es lo único que tienes."
        case .vigia:
            return "Conoces el bosque mejor que las calles. Cazabas para Valcenar y vigilabas la Grieta Bermeja desde su linde, más cerca de lo que nadie más se atrevía."
        case .vidente:
            return "La Sangre Vieja te habló antes de que supieras qué era. Los sacerdotes de Valcenar te tenían más miedo a ti que a la propia Grieta."
        case .penitente:
            return "Sirves a la Fe de las Cinco Casas, la que reza a lo que fue sellado y no a lo que despertará. Tu martillo protege; tu voto, a veces, pesa más que tu martillo."
        }
    }

    var atributos: [Atributo: Int] {
        switch self {
        case .cuchilla:  return [.fue: 7, .agi: 5, .vol: 3]
        case .vigia:     return [.fue: 5, .agi: 7, .vol: 3]
        case .vidente:   return [.fue: 3, .agi: 4, .vol: 8]
        case .penitente: return [.fue: 6, .agi: 4, .vol: 6]
        }
    }

    var vidaInicial: Int {
        switch self {
        case .cuchilla: return 24
        case .vigia: return 22
        case .vidente: return 22
        case .penitente: return 24
        }
    }

    /// El Penitente puede lanzar Luz de Cadena Rota una vez; la Vidente conserva
    /// un margen mayor de Ecos para no depender de la Corrupción en combate.
    var ecosIniciales: Int {
        switch self {
        case .cuchilla: return 0
        case .vigia: return 0
        case .vidente: return 5
        case .penitente: return 2
        }
    }

    var arma: Arma {
        switch self {
        case .cuchilla: return .espadaLarga
        case .vigia: return .arcoCorto
        case .vidente: return .baston
        case .penitente: return .maza
        }
    }

    var armaSecundaria: Arma? {
        switch self {
        case .vigia: return .daga
        case .penitente: return .simboloSagrado
        default: return nil
        }
    }

    var armadura: Armadura {
        switch self {
        case .cuchilla: return .cuero
        case .vigia: return .cuero
        case .vidente: return .cuero
        case .penitente: return .ligera
        }
    }

    var escudo: Bool { self == .cuchilla || self == .vidente || self == .penitente }

    /// Parte III: la Defensa base impresa en la ficha de vocación.
    var defensaInicial: Int {
        Reglas.defensaBase + armadura.bonoDefensa + (escudo ? Armadura.escudo.bonoDefensa : 0)
    }

    var mochilaInicial: [ObjetoDeMochila] {
        switch self {
        case .cuchilla: return [.racion, .venda]
        case .vigia: return [.cuerda, .yesca, .racion, .venda]
        case .vidente: return [.racion, .tintaDeGrieta, .venda]
        case .penitente: return [.racion, .velaBendita, .venda]
        }
    }

    var hechizos: [Hechizo] {
        switch self {
        case .vidente: return [.chispaNegra, .susurroDePiel]
        case .penitente: return [.manosDeCeniza]
        default: return []
        }
    }

    /// La Parte V titula sus listas «Hechizos de la Vidente Rota» y «del
    /// Penitente»: son el repertorio de la vocación, no un catálogo ajeno. Se
    /// conocen desde el principio; lo que limita al mago son los Ecos.
    var repertorioCompleto: [Hechizo] {
        switch self {
        case .vidente: return [.grietaMenor, .ojoCeniciento, .veloRoto]
        case .penitente: return [.muroDeVoto, .luzDeCadenaRota]
        default: return []
        }
    }

    /// Los dos que el libro marca «hechizo avanzado, se aprende durante la
    /// historia». Esos sí llegan más tarde.
    var repertorio: [Hechizo] {
        switch self {
        case .vidente: return [.cadenaDeEco]
        case .penitente: return [.juramentoCompartido]
        default: return []
        }
    }

    var don: (nombre: String, descripcion: String) {
        switch self {
        case .cuchilla:
            return ("Furia de Forjagrís",
                    "Una vez por combate, si fallas una tirada de ataque, puedes tirar de nuevo. Cuesta 1 punto de Corrupción y solo lo pagas si llegas a repetir.")
        case .vigia:
            return ("Ojo de Vardo",
                    "Una vez por sección, puedes repetir una prueba de AGI fallida. Cuesta 1 punto de Corrupción.")
        case .vidente:
            return ("Eco Profundo",
                    "Hasta dos veces por combate, gasta 1 punto de Corrupción para añadir +2 a una tirada de ataque mágico.")
        case .penitente:
            return ("Voto de Ceniza",
                    "Una vez por Acto, fuera de combate, curas 1D6+2 puntos de Vida. Cuesta 1 punto de Corrupción.")
        }
    }

    var resumenDeAtributos: String {
        "FUE \(atributos[.fue] ?? 0) · AGI \(atributos[.agi] ?? 0) · VOL \(atributos[.vol] ?? 0)"
    }
}
