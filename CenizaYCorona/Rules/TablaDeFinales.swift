import Foundation

// Las tablas viven en Resources/ending-rules.json, compartido con la web.
// Mantener las condiciones como datos evita que los dos motores se separen.
struct RangoDeCorrupcion: Codable, Hashable {
    let min: Int?
    let max: Int?
}

struct CondicionesDeFinal: Codable, Hashable {
    let corruption: RangoDeCorrupcion?
    let allFlags: [String]?
    let anyFlags: [String]?
    let reputation: [String: Int]?
    let allVisitedSections: [Int]?
    let fallback: Bool?
}

struct ReglaDeFinal: Codable, Hashable {
    let destination: Int
    let description: String
    let conditions: CondicionesDeFinal

    var destino: Int { destination }
    var descripcion: String { description }

    func cumple(_ state: GameState) -> Bool {
        if conditions.fallback == true { return true }
        if let range = conditions.corruption {
            if let min = range.min, state.corrupcion < min { return false }
            if let max = range.max, state.corrupcion > max { return false }
        }
        if (conditions.allFlags ?? []).contains(where: { !state.flags.contains($0) }) { return false }
        if let anyFlags = conditions.anyFlags, !anyFlags.isEmpty,
           !anyFlags.contains(where: { state.flags.contains($0) }) { return false }
        if (conditions.reputation ?? [:]).contains(where: { key, minimum in
            guard let track = RepTrack(rawValue: key) else { return true }
            return state.rep(track) < minimum
        }) { return false }
        if (conditions.allVisitedSections ?? []).contains(where: { !state.visitadas.contains($0) }) { return false }
        return true
    }
}

private struct TablaDeReglasDeFinal: Codable, Hashable {
    let sectionId: Int
    let rules: [ReglaDeFinal]
}

private struct ArchivoDeReglasDeFinal: Codable {
    let tables: [TablaDeReglasDeFinal]
}

private final class ReglasDeFinalCompartidas {
    static let shared = ReglasDeFinalCompartidas()

    let tables: [TablaDeReglasDeFinal]
    let loadError: String?

    private init() {
        let bundle = Bundle.main
        let fallbackBundle = Bundle(for: ReglasDeFinalCompartidas.self)
        guard let url = bundle.url(forResource: "ending-rules", withExtension: "json")
            ?? fallbackBundle.url(forResource: "ending-rules", withExtension: "json") else {
            tables = []
            loadError = "No se encontró ending-rules.json en el bundle."
            return
        }
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            tables = try decoder.decode(ArchivoDeReglasDeFinal.self, from: Data(contentsOf: url)).tables
            loadError = nil
        } catch {
            tables = []
            loadError = "ending-rules.json no se pudo leer: \(error.localizedDescription)"
        }
    }
}

enum TablaDeFinales {
    static let secciones: Set<Int> = Set(ReglasDeFinalCompartidas.shared.tables.map(\.sectionId))

    static func reglas(para seccion: Int) -> [ReglaDeFinal] {
        ReglasDeFinalCompartidas.shared.tables.first(where: { $0.sectionId == seccion })?.rules ?? []
    }

    static func resolver(seccion: Int, con state: GameState) -> ReglaDeFinal? {
        reglas(para: seccion).first { $0.cumple(state) }
    }
}

/// Conserva el punto de extensión visual de las palabras clave históricas.
/// Las condiciones de final ya no se corrigen aquí: vienen de ending-rules.json.
enum ParchesDeDatos {
    static let flagsHuerfanos: Set<String> = []
}
