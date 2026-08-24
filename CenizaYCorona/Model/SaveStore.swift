import Foundation

struct GameSnapshot: Codable, Hashable {
    var nombre: String
    var vocacion: Vocacion
    var atributos: [String: Int]
    var nivel: Int = 1
    var vida: Int
    var vidaMaxima: Int
    var ecos: Int
    var ecosMaximos: Int
    var corrupcion: Int
    var mutacionAplicada: Bool
    var arma: Arma
    var armaSecundaria: Arma?
    var armadura: Armadura
    var llevaEscudo: Bool
    var mochila: [ObjetoDeMochila]
    var hechizos: [Hechizo]
    var reputacion: [String: Int]
    var flags: [String]
    var scope: PlayScope
    var seccionActual: Int
    var visitadas: [Int]
    var finalesVistos: [Int]
    var historia: [EventoCronica]?
    var ilustracionesDescubiertas: [Int]?
    var combate: CombatSnapshot?
    var monedas: [String: Int] = [:]
    var tiendasCobradas: [Int] = []
    var ventasHechas: [String] = []
    var amuletoGastadoEnLibro: Bool = false
    var planDeMarcha: PlanDeMarcha?
    var esperaDeMarcha: Int?
    var descansosDeSilencio: [Int]?
    var penalizacionDeHeridaUsada: Bool?
    var votoDeCenizaUsadoEnLibro: Bool = false
    var comenzada: Date
    var guardada: Date

    init(_ s: GameState, combate: CombatSession? = nil) {
        nombre = s.nombre
        vocacion = s.vocacion
        atributos = Dictionary(uniqueKeysWithValues: s.atributos.map { ($0.key.rawValue, $0.value) })
        nivel = s.nivel
        vida = s.vida
        vidaMaxima = s.vidaMaxima
        ecos = s.ecos
        ecosMaximos = s.ecosMaximos
        corrupcion = s.corrupcion
        mutacionAplicada = s.mutacionAplicada
        arma = s.arma
        armaSecundaria = s.armaSecundaria
        armadura = s.armadura
        llevaEscudo = s.llevaEscudo
        mochila = s.mochila
        hechizos = s.hechizos
        reputacion = Dictionary(uniqueKeysWithValues: s.reputacion.map { ($0.key.rawValue, $0.value) })
        flags = s.flags.sorted()
        scope = s.scope
        seccionActual = s.seccionActual
        visitadas = s.visitadas.sorted()
        finalesVistos = s.finalesVistos.sorted()
        historia = s.historia
        ilustracionesDescubiertas = s.ilustracionesDescubiertas.sorted()
        self.combate = combate.map(CombatSnapshot.init)
        monedas = Dictionary(uniqueKeysWithValues: s.monedas.map { ($0.key.rawValue, $0.value) })
        tiendasCobradas = s.tiendasCobradas.sorted()
        ventasHechas = s.ventasHechas.sorted()
        amuletoGastadoEnLibro = s.amuletoGastadoEnLibro
        planDeMarcha = s.planDeMarcha
        esperaDeMarcha = s.esperaDeMarcha
        descansosDeSilencio = s.descansosDeSilencio.sorted()
        penalizacionDeHeridaUsada = s.penalizacionDeHeridaUsada
        votoDeCenizaUsadoEnLibro = s.votoDeCenizaUsadoEnLibro
        comenzada = s.comenzada
        guardada = Date()
    }

    func restaurar() -> GameState {
        let s = GameState(nombre: nombre, vocacion: vocacion, reparto: [:], scope: scope)
        var attrs: [Atributo: Int] = [:]
        for (k, v) in atributos { if let a = Atributo(rawValue: k) { attrs[a] = v } }
        s.atributos = attrs
        s.nivel = nivel
        s.vida = vida
        s.vidaMaxima = vidaMaxima
        s.ecos = ecos
        s.ecosMaximos = ecosMaximos
        s.corrupcion = corrupcion
        s.mutacionAplicada = mutacionAplicada
        s.arma = arma
        s.armaSecundaria = armaSecundaria
        s.armadura = armadura
        s.llevaEscudo = llevaEscudo
        s.mochila = mochila
        s.hechizos = hechizos
        var rep: [RepTrack: Int] = [:]
        for t in RepTrack.allCases { rep[t] = 0 }
        for (k, v) in reputacion { if let t = RepTrack(rawValue: k) { rep[t] = v } }
        s.reputacion = rep
        s.flags = Set(flags)
        s.seccionActual = seccionActual
        s.visitadas = Set(visitadas)
        s.finalesVistos = Set(finalesVistos)
        s.historia = historia ?? []
        s.ilustracionesDescubiertas = Set(ilustracionesDescubiertas ?? [])
        var mon: [Moneda: Int] = [:]
        for (k, v) in monedas { if let m = Moneda(rawValue: k) { mon[m] = v } }
        s.monedas = mon
        s.tiendasCobradas = Set(tiendasCobradas)
        s.ventasHechas = Set(ventasHechas)
        s.amuletoGastadoEnLibro = amuletoGastadoEnLibro
        s.planDeMarcha = planDeMarcha
        s.esperaDeMarcha = esperaDeMarcha ?? 0
        s.descansosDeSilencio = Set(descansosDeSilencio ?? [])
        s.penalizacionDeHeridaUsada = penalizacionDeHeridaUsada ?? false
        s.votoDeCenizaUsadoEnLibro = votoDeCenizaUsadoEnLibro
        s.comenzada = comenzada
        s.avisos = []
        return s
    }

    var progreso: Double {
        let total = SagaLibrary.shared.count(in: scope)
        guard total > 0 else { return 0 }
        return min(1, Double(visitadas.count) / Double(total))
    }
}

final class SaveStore {
    static let shared = SaveStore()

    static let numeroDeRanuras = 3
    private(set) var ranuras: [GameSnapshot?] = Array(repeating: nil, count: numeroDeRanuras)
    private(set) var finalesDescubiertos: Set<Int> = []
    private(set) var ranuraActiva: Int?

    private let fichero: URL

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fichero = dir.appendingPathComponent("ceniza-y-corona.json")
        cargar()
    }

    static func clave(de scope: PlayScope) -> String {
        switch scope {
        case .book(let b): return "libro-\(b.rawValue)"
        case .saga: return "saga"
        }
    }

    var partidas: [String: GameSnapshot] {
        var salida: [String: GameSnapshot] = [:]
        for partida in ranuras.compactMap({ $0 }) {
            let clave = SaveStore.clave(de: partida.scope)
            if salida[clave] == nil || salida[clave]!.guardada < partida.guardada { salida[clave] = partida }
        }
        return salida
    }

    func partida(de scope: PlayScope) -> GameSnapshot? { partidaConIndice(de: scope)?.partida }

    func partidaConIndice(de scope: PlayScope) -> (indice: Int, partida: GameSnapshot)? {
        ranuras.enumerated()
            .compactMap { indice, partida in partida?.scope == scope ? (indice, partida!) : nil }
            .max { $0.1.guardada < $1.1.guardada }
            .map { ($0.0, $0.1) }
    }

    @discardableResult
    func prepararNuevaPartida() -> Int {
        let indice = ranuras.firstIndex(where: { $0 == nil })
            ?? ranuras.enumerated().compactMap { indice, valor in valor.map { (indice, $0.guardada) } }
                .min(by: { $0.1 < $1.1 })?.0
            ?? 0
        ranuraActiva = indice
        return indice
    }

    func activar(ranura indice: Int) {
        guard ranuras.indices.contains(indice), ranuras[indice] != nil else { return }
        ranuraActiva = indice
    }

    func guardar(_ state: GameState, combate: CombatSession? = nil, conservarCombate: Bool = true) {
        var indice = ranuraActiva
        if let activa = indice, let guardada = ranuras[activa], guardada.comenzada != state.comenzada {
            indice = nil
        }
        if indice == nil {
            indice = ranuras.firstIndex { $0?.comenzada == state.comenzada }
        }
        if indice == nil { indice = prepararNuevaPartida() }
        ranuraActiva = indice
        var snapshot = GameSnapshot(state, combate: combate)
        if combate == nil, conservarCombate,
           let anterior = ranuras[indice!]?.combate, anterior.seccionID == state.seccionActual {
            snapshot.combate = anterior
        }
        ranuras[indice!] = snapshot
        finalesDescubiertos.formUnion(state.finalesVistos)
        persistir()
    }

    func borrar(scope: PlayScope) {
        guard let indice = partidaConIndice(de: scope)?.indice else { return }
        borrar(ranura: indice)
    }

    func borrar(ranura indice: Int) {
        guard ranuras.indices.contains(indice) else { return }
        ranuras[indice] = nil
        if ranuraActiva == indice { ranuraActiva = nil }
        persistir()
    }

    func urlDeExportacion(ranura indice: Int) throws -> URL {
        guard ranuras.indices.contains(indice), let partida = ranuras[indice] else {
            throw CocoaError(.fileNoSuchFile)
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(partida)
        let nombre = partida.nombre.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ceniza-y-corona-\(nombre.isEmpty ? "partida" : nombre).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    @discardableResult
    func importar(desde url: URL) throws -> Int {
        let acceso = url.startAccessingSecurityScopedResource()
        defer { if acceso { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let partida = try decoder.decode(GameSnapshot.self, from: data)
        guard SagaLibrary.shared[partida.seccionActual] != nil else { throw CocoaError(.fileReadCorruptFile) }
        let indice = ranuras.firstIndex(where: { $0 == nil }) ?? prepararNuevaPartida()
        ranuras[indice] = partida
        ranuraActiva = indice
        finalesDescubiertos.formUnion(partida.finalesVistos)
        persistir()
        return indice
    }

    private struct Sobre: Codable {
        var version: Int
        var ranuras: [GameSnapshot?]
        var finalesDescubiertos: [Int]
    }

    private struct SobreAnterior: Codable {
        var partidas: [String: GameSnapshot]
        var finalesDescubiertos: [Int]
    }

    private func cargar() {
        guard let data = try? Data(contentsOf: fichero) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let sobre = try? decoder.decode(Sobre.self, from: data) {
            ranuras = Array(sobre.ranuras.prefix(Self.numeroDeRanuras))
            while ranuras.count < Self.numeroDeRanuras { ranuras.append(nil) }
            finalesDescubiertos = Set(sobre.finalesDescubiertos)
            return
        }
        if let anterior = try? decoder.decode(SobreAnterior.self, from: data) {
            let migradas = anterior.partidas.values.sorted { $0.guardada > $1.guardada }
            ranuras = Array(migradas.prefix(Self.numeroDeRanuras)).map(Optional.some)
            while ranuras.count < Self.numeroDeRanuras { ranuras.append(nil) }
            finalesDescubiertos = Set(anterior.finalesDescubiertos)
            persistir()
        }
    }

    private func persistir() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(Sobre(version: 2, ranuras: ranuras,
                                                   finalesDescubiertos: finalesDescubiertos.sorted()))
        else { return }
        try? data.write(to: fichero, options: .atomic)
    }
}
