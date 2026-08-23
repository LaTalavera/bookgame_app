import Foundation

/// Carga `saga.json` una sola vez y lo indexa por número de sección.
final class SagaLibrary {
    static let shared = SagaLibrary()

    private(set) var sections: [Int: Section] = [:]
    private(set) var loadError: String?

    private init() {
        guard let url = Bundle.main.url(forResource: "saga", withExtension: "json") else {
            loadError = "No se encontró saga.json en el bundle."
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            // El JSON es un diccionario "1": {...} con la sección como clave.
            let raw = try decoder.decode([String: Section].self, from: data)
            var index: [Int: Section] = [:]
            for section in raw.values { index[section.id] = section }
            sections = index
        } catch {
            loadError = "saga.json no se pudo leer: \(error.localizedDescription)"
        }
    }

    subscript(id: Int) -> Section? { sections[id] }

    func ids(in book: BookID) -> [Int] {
        sections.keys.filter { book.contains($0) }.sorted()
    }

    func count(in scope: PlayScope) -> Int {
        switch scope {
        case .book(let b): return ids(in: b).count
        case .saga: return sections.count
        }
    }

    /// Los finales de un libro, en orden. §x900 es la caída; §x950 el de Corrupción.
    func endings(in book: BookID) -> [Section] {
        ids(in: book).compactMap { sections[$0] }.filter { $0.esFinal }
    }

    /// Qué marcadores toca de verdad este libro. Se deduce de los `rep_delta`
    /// que aparecen en sus secciones, así que la hoja nunca enseña un medidor
    /// que la narrativa no vaya a mover.
    func marcadoresActivos(en scope: PlayScope) -> [RepTrack] {
        let relevant: [Section]
        switch scope {
        case .book(let b): relevant = ids(in: b).compactMap { sections[$0] }
        case .saga: relevant = Array(sections.values)
        }
        var found = Set<RepTrack>()
        for section in relevant {
            for key in section.repDelta.keys {
                if let track = RepTrack(rawValue: key) { found.insert(track) }
            }
        }
        return RepTrack.allCases.filter { found.contains($0) }
    }
}
