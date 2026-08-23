import Foundation
import Observation

struct LineaDeCombate: Identifiable, Codable, Hashable {
    enum Lado: String, Codable, Hashable { case jugador, enemigo, sistema }
    let id: UUID
    let ronda: Int
    let lado: Lado
    let texto: String

    init(id: UUID = UUID(), ronda: Int, lado: Lado, texto: String) {
        self.id = id
        self.ronda = ronda
        self.lado = lado
        self.texto = texto
    }
}

/// Cómo vas a atacar esta ronda (Parte II, §13).
enum ModoDeAtaque: Hashable, Identifiable {
    case arma(Arma)
    case hechizo(Hechizo)

    var id: String {
        switch self {
        case .arma(let a): return "arma-\(a.nombre)"
        case .hechizo(let h): return "hechizo-\(h.nombre)"
        }
    }

    var nombre: String {
        switch self {
        case .arma(let a): return a.nombre
        case .hechizo(let h): return h.nombre
        }
    }

    var atributo: Atributo {
        switch self {
        case .arma(let a): return a.uso.atributo
        case .hechizo: return .vol
        }
    }

    var dano: Int {
        switch self {
        case .arma(let a): return a.dano
        case .hechizo(let h): return h.dano
        }
    }

    var costeEnEcos: Int {
        switch self {
        case .arma: return 0
        case .hechizo(let h): return h.coste
        }
    }
}

@Observable
final class CombatSession {

    enum Fase: String, Codable, Hashable {
        case listo
        case resuelto
        case ganado
        case perdido
    }

    let seccionID: Int
    let datos: CombatData
    let enemigo: EnemyStats

    var vidaEnemigo: Int
    var fase: Fase = .listo
    var ronda: Int = 1

    var ultimaTirada: Tirada?
    var ultimoImpacto: Bool = false
    var ultimoCritico: Bool = false
    var tituloDeResultado: String = ""
    var detalleDeResultado: String = ""
    var registro: [LineaDeCombate] = []

    /// El parlamento que ofrece esta sección, si lo ofrece.
    var regla: ReglaDeCombate? { ReglasEspeciales.regla(en: seccionID) }

    /// Hace explícita la condición de victoria que ya codifican las reglas.
    var objetivoTactico: String {
        if let salida { return "Evita la lucha si aún no has dado el primer golpe: \(salida.titulo)." }
        if let n = regla?.seRindeTrasRondasLimpias { return "Encadena \(n) rondas limpias para quebrar su voluntad." }
        if let n = regla?.seRetiraTrasPerderIniciativa { return "Gánale la iniciativa \(n) veces seguidas para que se retire." }
        if let vida = regla?.huyeConVidaMenorDe { return "Hazlo retroceder por debajo de \(vida) de Vida." }
        if regla?.costeDeGolpearVOL != nil { return "Mide los golpes: cada impacto puede cobrar Ecos o Vida." }
        if regla?.atacaPrimeroSiempre == true { return "Sobrevive al asalto inicial y recupera la iniciativa." }
        return "Abre camino: reduce su Vida a cero o encuentra una salida de la sección."
    }

    var intencionTactica: String {
        if let salida { return salida.invitacion }
        if regla?.seRindeTrasRondasLimpias != nil { return "Si no logra tocarte, perderá el valor y se retirará." }
        if regla?.seRetiraTrasPerderIniciativa != nil { return "No pelea por fanatismo: abandonará si le arrebatas el ritmo." }
        if regla?.huyeConVidaMenorDe != nil { return "Es una amenaza territorial: se marchará antes de morir." }
        if regla?.costeDeGolpearVOL != nil { return "La criatura intenta quebrar tu vínculo con la Sangre Vieja." }
        if regla?.atacaPrimeroSiempre == true { return "Ataca desde una posición ventajosa y busca desbordarte al principio." }
        return "Te corta el paso y tratará de desgastarte en un intercambio directo."
    }

    /// Parte V, §25: Luz de Cadena Rota hace 5 contra Quebrados e incorpóreos
    /// y 2 contra todo lo demás.
    var enemigoEsQuebrado: Bool {
        let n = datos.enemy.uppercased()
        return ["QUEBRADO", "ECO ", "CENTINELA", "ANCLA", "ESLABÓN", "ESLABON", "LIGADO"]
            .contains { n.contains($0) }
    }

    func danoDe(_ modo: ModoDeAtaque) -> Int {
        if case .hechizo(let h) = modo, h == .luzDeCadenaRota {
            return enemigoEsQuebrado ? 5 : 2
        }
        return modo.dano
    }

    /// §4 del plan: la Vigía suma su AGI al daño en la primera ronda.
    func bonoDeEmboscada(_ state: GameState) -> Int {
        (state.vocacion == .vigia && ronda == 1) ? state.atributo(.agi) : 0
    }
    var parlamento: Parlamento? { regla?.parlamento }
    /// Rondas seguidas ganándole limpio y rondas seguidas en que pierde la iniciativa.
    var rondasLimpias = 0
    var iniciativasPerdidas = 0
    var proximaRondaPerdida = false
    var primerGolpeDado = false

    /// Solo se puede parlamentar cuando el enemigo flaquea y sigue en pie.
    func puedeParlamentar(_ state: GameState) -> Bool {
        guard let p = parlamento, !terminado, vidaEnemigo > 0, !parlamentoIntentado else { return false }
        switch p.requisito {
        case .vidaEnemigoBajaDe(let n): return vidaEnemigo < n
        case .marcador(let t, let minimo): return state.rep(t) >= minimo
        }
    }

    var parlamentoIntentado = false
    var parlamentoLogrado = false

    // MARK: - Salida de vocación

    var salida: SalidaDeVocacion? { regla?.salida }
    var salidaIntentada = false
    var salidaLograda = false

    /// La dificultad a la que *esta* protagonista puede intentar la salida.
    /// A quien está hecha para ello le cuesta un peldaño menos.
    func dificultadDeSalida(_ state: GameState) -> Dificultad? {
        salida?.dificultad(para: state.vocacion)
    }

    func puedeIntentarSalida(_ state: GameState) -> Bool {
        guard let s = salida, !terminado, vidaEnemigo > 0,
              !salidaIntentada, dificultadDeSalida(state) != nil else { return false }
        return !(s.antesDeGolpear && primerGolpeDado)
    }

    /// Evita el combate entero. Al superarla la historia sigue por donde
    /// seguiría si hubieras ganado, pero sin haber levantado el arma.
    @discardableResult
    func intentarSalida(state: GameState) -> Bool {
        guard let s = salida, let dif = dificultadDeSalida(state),
              puedeIntentarSalida(state) else { return false }
        salidaIntentada = true
        let tirada = Dados.tirar2D6(modificador: state.atributo(s.atributo))
        ultimaTirada = tirada
        let superada = tirada.alcanza(dif.objetivo)
        ultimoImpacto = superada
        if superada {
            salidaLograda = true
            fase = .ganado
            tituloDeResultado = s.titulo.uppercased()
            detalleDeResultado = "\(tirada.total) vs \(dif.objetivo) · sin desenvainar"
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema, texto: s.exito))
        } else {
            tituloDeResultado = "NO SALE"
            detalleDeResultado = "\(tirada.total) vs \(dif.objetivo)"
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema, texto: s.alFallar))
        }
        return superada
    }

    /// Dones forzados armados para esta ronda.
    var golpeDeGrietaArmado = false
    var pielDeCenizaArmada = false
    var donDeVocacionUsado = false
    /// Furia de Forjagris (Cuchilla): se arma antes de golpear y solo cobra si
    /// llega a repetir, es decir, si fallas. El precio del don (§13): 1 Corrupcion.
    var furiaArmada = false
    /// Eco Profundo (Vidente): hasta dos veces por combate, 1 Corrupción por +2 al ataque mágico.
    var ecoProfundoArmado = false
    var ecoProfundoUsos = 0
    /// Muro de Voto (Penitente): 1 Eco, reduce en 2 el daño de esta ronda.
    var muroDeVotoArmado = false

    init(seccionID: Int, datos: CombatData) {
        self.seccionID = seccionID
        self.datos = datos
        let ficha = Bestiario.stats(para: seccionID, enemigo: datos.enemy)
        self.enemigo = ficha
        self.vidaEnemigo = ficha.vida
    }

    convenience init(snapshot: CombatSnapshot, datos: CombatData) {
        self.init(seccionID: snapshot.seccionID, datos: datos)
        vidaEnemigo = snapshot.vidaEnemigo
        fase = snapshot.fase
        ronda = snapshot.ronda
        ultimaTirada = snapshot.ultimaTirada
        ultimoImpacto = snapshot.ultimoImpacto
        ultimoCritico = snapshot.ultimoCritico ?? false
        tituloDeResultado = snapshot.tituloDeResultado
        detalleDeResultado = snapshot.detalleDeResultado
        registro = snapshot.registro
        parlamentoIntentado = snapshot.parlamentoIntentado
        parlamentoLogrado = snapshot.parlamentoLogrado
        salidaIntentada = snapshot.salidaIntentada
        salidaLograda = snapshot.salidaLograda
        golpeDeGrietaArmado = snapshot.golpeDeGrietaArmado
        pielDeCenizaArmada = snapshot.pielDeCenizaArmada
        donDeVocacionUsado = snapshot.donDeVocacionUsado
        furiaArmada = snapshot.furiaArmada ?? false
        ecoProfundoArmado = snapshot.ecoProfundoArmado ?? false
        ecoProfundoUsos = snapshot.ecoProfundoUsos ?? 0
        muroDeVotoArmado = snapshot.muroDeVotoArmado ?? false
    }

    var terminado: Bool { fase == .ganado || fase == .perdido }

    func puedeUsarFuria(_ state: GameState) -> Bool {
        state.vocacion == .cuchilla && !donDeVocacionUsado && !terminado
            && state.corrupcion < Reglas.corrupcionMaxima
    }

    func puedeUsarEcoProfundo(_ state: GameState) -> Bool {
        state.vocacion == .vidente && ecoProfundoUsos < 2 && !terminado
            && state.corrupcion < Reglas.corrupcionMaxima
    }

    /// Frasco de fuego alquímico (§73): daño directo que ignora la Defensa.
    func frascosDisponibles(_ state: GameState) -> Int {
        terminado ? 0 : state.mochila.filter { $0.danoDirecto > 0 }.count
    }

    @discardableResult
    func lanzarFrasco(state: GameState) -> Bool {
        guard !terminado,
              let i = state.mochila.firstIndex(where: { $0.danoDirecto > 0 }) else { return false }
        let frasco = state.mochila.remove(at: i)
        vidaEnemigo = max(0, vidaEnemigo - frasco.danoDirecto)
        ultimoImpacto = true
        tituloDeResultado = "FUEGO ALQUÍMICO"
        detalleDeResultado = "\(frasco.danoDirecto) de daño, ignora la Defensa"
        registro.append(LineaDeCombate(ronda: ronda, lado: .jugador,
                                       texto: "Lanzas un frasco de fuego alquímico: \(frasco.danoDirecto) de daño."))
        if vidaEnemigo <= 0 {
            // §1118: al caer libera Sangre Vieja.
            if let dif = regla?.descargaAlCaerVOL {
                let t = Dados.tirar2D6(modificador: state.atributo(.vol))
                if !t.alcanza(dif.objetivo) {
                    state.ganarCorrupcion(1)
                    registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                                   texto: "Al caer libera Sangre Vieja: +1 Corrupción."))
                }
            }
            fase = .ganado
            tituloDeResultado = "VENCES"
            detalleDeResultado = "\(enemigo.nombre) cae."
            return true
        }
        golpeDelEnemigo(state: state)
        cerrarRondaTrasFrasco(state: state)
        return true
    }

    private func cerrarRondaTrasFrasco(state: GameState) {
        if state.vida <= 0 {
            fase = .perdido
            if datos.esTutorial || !datos.esLetal {
                aplicarReves(state)
                tituloDeResultado = "TE RETIRAS"
                detalleDeResultado = "Te retiras con 1 de Vida. Revés: quedas Herido."
            } else {
                tituloDeResultado = "CAES"
                detalleDeResultado = "Tu Vida llega a 0."
            }
            return
        }
        ronda += 1
        fase = .resuelto
    }

    /// REVÉS (§13). Perder un combate que no te mata nunca fue gratis en el
    /// texto, pero sí en la ficha: te quedabas a 1 de Vida y seguías igual.
    /// Ahora esa Vida cuenta como herida nueva, así que la penalización de
    /// Herido vuelve a pesar aunque ya la hubieras gastado antes.
    private func aplicarReves(_ state: GameState) {
        state.vida = 1
        state.penalizacionDeHeridaUsada = false
    }

    func puedeUsarMuroDeVoto(_ state: GameState) -> Bool {
        state.hechizos.contains(.muroDeVoto) && !terminado
            && state.ecos >= Hechizo.muroDeVoto.coste
    }

    var destino: Int? {
        if salidaLograda { return datos.onWin }
        if parlamentoLogrado { return parlamento?.destino ?? datos.onWin }
        switch fase {
        case .ganado: return datos.onWin
        case .perdido: return datos.onLose
        default: return nil
        }
    }

    /// Tira la prueba del parlamento. Si se supera, el combate termina sin
    /// muerte y con la palabra clave que pide la tabla de finales.
    @discardableResult
    func parlamentar(state: GameState) -> Bool {
        guard let p = parlamento, puedeParlamentar(state) else { return false }
        parlamentoIntentado = true
        let tirada = Dados.tirar2D6(modificador: state.atributo(p.atributo))
        ultimaTirada = tirada
        let superada = tirada.alcanza(p.dificultad.objetivo)
        ultimoImpacto = superada
        if superada {
            parlamentoLogrado = true
            fase = .ganado
            if let f = p.flagAlSuperarla { state.conceder(flag: f) }
            if let (track, delta) = p.repAlSuperarla { state.aplicar(reputacion: delta, a: track) }
            tituloDeResultado = "LA CONVENCES"
            detalleDeResultado = "\(tirada.total) vs \(p.dificultad.objetivo) · baja el arma"
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                           texto: "Parlamento superado: \(tirada.total)."))
        } else {
            tituloDeResultado = "NO TE ESCUCHA"
            detalleDeResultado = "\(tirada.total) vs \(p.dificultad.objetivo)"
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                           texto: "Parlamento fallido: \(tirada.total). \(p.alFallar)"))
        }
        return superada
    }

    /// Dificultad equivalente de la Defensa del enemigo, para enseñarla en la escala.
    var dificultadEquivalente: Dificultad {
        var resultado = Dificultad.facil
        for paso in Dificultad.allCases where paso.rawValue <= enemigo.defensa { resultado = paso }
        return resultado
    }

    // ── Ronda ───────────────────────────────────────────────────────────────

    /// Parte II, §13: iniciativa por AGI; si la tuya iguala o supera la del
    /// enemigo, atacas primero. El libro no publica la AGI de la mayoría de
    /// enemigos, así que se usa su Ataque como AGI efectiva.
    func atacasPrimero(_ state: GameState, modo: ModoDeAtaque) -> Bool {
        if regla?.atacaPrimeroSiempre == true, ronda == 1 { return false }
        if case .arma(let arma) = modo, arma.atacaPrimeroLaPrimeraRonda, ronda == 1 { return true }
        if case .arma(let arma) = modo, arma.atacaUltimo { return false }
        return state.atributo(.agi) >= enemigo.ataque
    }

    /// Parte V, §26 llevada al Grimorio: sin Ecos, un Marcado puede tirar
    /// igualmente de la Sangre Vieja pagando Corrupción.
    func puedeForzarElHechizo(_ state: GameState, modo: ModoDeAtaque) -> Bool {
        guard !terminado, modo.costeEnEcos > 0, state.ecos < modo.costeEnEcos else { return false }
        return state.corrupcion < Reglas.corrupcionMaxima
    }

    func atacar(state: GameState, modo: ModoDeAtaque, forzandoElHechizo: Bool = false) {
        guard !terminado else { return }

        if forzandoElHechizo, puedeForzarElHechizo(state, modo: modo) {
            state.ganarCorrupcion(1)
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                           texto: "Fuerzas \(modo.nombre) sin Ecos. La Sangre Vieja cobra: +1 Corrupción."))
        } else if modo.costeEnEcos > 0 {
            guard state.gastarEcos(modo.costeEnEcos) else {
                registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                               texto: "No te quedan Ecos para \(modo.nombre)."))
                return
            }
        }

        let primeroYo = atacasPrimero(state, modo: modo)
        if primeroYo { iniciativasPerdidas += 1 } else { iniciativasPerdidas = 0 }
        let vidaAntes = state.vida
        let enemigoAntes = vidaEnemigo

        if primeroYo {
            golpeDelJugador(state: state, modo: modo)
            if vidaEnemigo > 0 { golpeDelEnemigo(state: state) }
        } else {
            golpeDelEnemigo(state: state)
            if state.vida > 0 || !datos.esLetal { golpeDelJugador(state: state, modo: modo) }
        }

        // §38: una ronda "limpia" es la que le haces daño sin recibirlo.
        if state.vida == vidaAntes && vidaEnemigo < enemigoAntes { rondasLimpias += 1 }
        else { rondasLimpias = 0 }

        cerrarRonda(state: state)
    }

    private func golpeDelJugador(state: GameState, modo: ModoDeAtaque) {
        let atributo = state.atributo(modo.atributo)
        var modificador = atributo
        var donForzadoUsado = false
        if golpeDeGrietaArmado {
            modificador += DonForzado.golpeDeGrieta.bono
            state.ganarCorrupcion(DonForzado.golpeDeGrieta.costeCorrupcion)
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                           texto: "Golpe de Grieta: +3 al ataque, +1 Corrupción."))
            golpeDeGrietaArmado = false
            donForzadoUsado = true
        }
        if ecoProfundoArmado, case .hechizo = modo {
            modificador += 2
            state.ganarCorrupcion(1)
            ecoProfundoUsos += 1
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                           texto: "Eco Profundo: +2 al ataque mágico, +1 Corrupción."))
            ecoProfundoArmado = false
        }

        var tirada = Dados.tirar2D6(modificador: modificador)
        var impacto = tirada.alcanza(enemigo.defensa)
        var golpeAutomatico = false

        // Don de la Cuchilla de Ceniza: una repetición por combate, si la armaste.
        if !impacto, furiaArmada, puedeUsarFuria(state) {
            donDeVocacionUsado = true
            furiaArmada = false
            state.ganarCorrupcion(Reglas.corrupcionPorDon)
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                           texto: "Furia de Forjagrís: repites la tirada. +\(Reglas.corrupcionPorDon) Corrupción."))
            tirada = Dados.tirar2D6(modificador: modificador)
            impacto = tirada.alcanza(enemigo.defensa)
        }

        ultimaTirada = tirada
        ultimoImpacto = impacto
        ultimoCritico = false

        // §122: con VENTAJA DE SIGILO el primer golpe entra sin tirada.
        if !primerGolpeDado, let flag = regla?.primerGolpeAutomaticoCon, state.flags.contains(flag) {
            impacto = true
            golpeAutomatico = true
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                           texto: "Ventaja de sigilo: tu primer golpe entra sin tirada."))
        }
        primerGolpeDado = true

        if impacto {
            // Parte II, §13: +1 de daño si tu atributo relevante es 7 o más.
            var dano = danoDe(modo)
            if atributo >= Reglas.umbralDeDanoExtra { dano += 1 }
            // §2095: Combe pelea a tu lado y su golpe cuenta con el tuyo.
            dano += state.companero?.dano ?? 0
            ultimoCritico = !golpeAutomatico && tirada.total >= enemigo.defensa + 5
            if ultimoCritico { dano *= 2 }
            dano += bonoDeEmboscada(state)
            // «resta N al daño que le inflijas», con la excepción del daño mágico.
            if let r = regla, r.reduceDano > 0 {
                let esMagico: Bool = { if case .hechizo = modo { return true }; return false }()
                if !(r.reduccionSoloConvencional && (esMagico || donForzadoUsado)) {
                    dano = max(1, dano - r.reduceDano)
                }
            }
            vidaEnemigo = max(0, vidaEnemigo - dano)

            // §2068 y §2115: cada golpe cuesta una prueba de VOL o 1 Eco.
            if let dif = regla?.costeDeGolpearVOL {
                let t = Dados.tirar2D6(modificador: state.atributo(.vol))
                if !t.alcanza(dif.objetivo) {
                    if state.ecos > 0 { _ = state.gastarEcos(1)
                        registro.append(LineaDeCombate(ronda: ronda, lado: .sistema, texto: "Tocarla te arranca 1 Eco."))
                    } else { state.recibirDano(1)
                        registro.append(LineaDeCombate(ronda: ronda, lado: .sistema, texto: "Sin Ecos que dar, la Cosa se cobra 1 de Vida."))
                    }
                }
            }
            tituloDeResultado = ultimoCritico ? "GOLPE DE GRACIA" : "IMPACTAS"
            detalleDeResultado = "\(tirada.total) vs Defensa \(enemigo.defensa) · \(dano) de daño"
            registro.append(LineaDeCombate(ronda: ronda, lado: .jugador,
                                           texto: "\(modo.nombre): \(tirada.d1)+\(tirada.d2)+\(modificador) = \(tirada.total). Impactas, \(dano) de daño."))
        } else {
            tituloDeResultado = "FALLAS"
            detalleDeResultado = "\(tirada.total) vs Defensa \(enemigo.defensa)"
            registro.append(LineaDeCombate(ronda: ronda, lado: .jugador,
                                           texto: "\(modo.nombre): \(tirada.d1)+\(tirada.d2)+\(modificador) = \(tirada.total). Fallas."))
        }
    }

    private func golpeDelEnemigo(state: GameState) {
        guard vidaEnemigo > 0 else { return }
        var modEnemigo = enemigo.ataque - (regla?.penalizacionAlEnemigo ?? 0)
        if regla?.segundoAtaqueConPenalizacion == true { modEnemigo -= 1 }
        if state.consumirVigilancia() {
            modEnemigo -= 2
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                           texto: "Vigilar la ruta anticipa el primer golpe: −2 al ataque enemigo."))
        }
        let tirada = Dados.tirar2D6(modificador: modEnemigo)
        guard tirada.alcanza(state.defensa) else {
            registro.append(LineaDeCombate(ronda: ronda, lado: .enemigo,
                                           texto: "\(enemigo.nombre) tira \(tirada.total) contra tu Defensa \(state.defensa) y falla."))
            return
        }

        var dano = enemigo.dano
        if muroDeVotoArmado {
            if state.gastarEcos(Hechizo.muroDeVoto.coste) {
                dano = max(0, dano - 2)
                registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                               texto: "Muro de Voto: el golpe te hace 2 menos."))
            }
            muroDeVotoArmado = false
        }
        if pielDeCenizaArmada {
            state.ganarCorrupcion(DonForzado.pielDeCeniza.costeCorrupcion)
            pielDeCenizaArmada = false
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                           texto: "Piel de Ceniza: ignoras el golpe. +1 Corrupción."))
            dano = 0
        }

        if dano > 0 {
            state.recibirDano(dano)
            registro.append(LineaDeCombate(ronda: ronda, lado: .enemigo,
                                           texto: "\(enemigo.nombre) tira \(tirada.total) y te alcanza: \(dano) de daño."))
        }
    }

    private func cerrarRonda(state: GameState) {
        // §14: el lobo huye al bajar de 4 y la historia sigue por on_win.
        if let umbral = regla?.huyeConVidaMenorDe, vidaEnemigo > 0, vidaEnemigo < umbral {
            fase = .ganado
            tituloDeResultado = "HUYE"
            detalleDeResultado = "\(enemigo.nombre) se retira hacia la oscuridad."
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema, texto: detalleDeResultado))
            return
        }
        let jefes: Set<Int> = [122, 126, 1137, 1143, 2136, 2147]
        if enemigo.vida >= 16, !jefes.contains(seccionID), vidaEnemigo > 0,
           vidaEnemigo <= Int(ceil(Double(enemigo.vida) * 0.2)) {
            fase = .ganado
            tituloDeResultado = "SE RETIRA"
            detalleDeResultado = "\(enemigo.nombre) está herido y abandona la lucha."
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema, texto: detalleDeResultado))
            return
        }
        // §38: se rinde tras dos rondas limpias. §1068: se retira tras perder la iniciativa dos veces.
        if let n = regla?.seRindeTrasRondasLimpias, rondasLimpias >= n, vidaEnemigo > 0 {
            fase = .ganado
            tituloDeResultado = "SE RINDE"
            detalleDeResultado = "\(enemigo.nombre) baja las manos y se marcha sin nada."
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema, texto: detalleDeResultado))
            return
        }
        if let n = regla?.seRetiraTrasPerderIniciativa, iniciativasPerdidas >= n, vidaEnemigo > 0 {
            fase = .ganado
            tituloDeResultado = "SE RETIRA"
            detalleDeResultado = "No piensa morir por un encargo."
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema, texto: detalleDeResultado))
            return
        }
        if vidaEnemigo <= 0 {
            // §1118: al caer libera Sangre Vieja.
            if let dif = regla?.descargaAlCaerVOL {
                let t = Dados.tirar2D6(modificador: state.atributo(.vol))
                if !t.alcanza(dif.objetivo) {
                    state.ganarCorrupcion(1)
                    registro.append(LineaDeCombate(ronda: ronda, lado: .sistema,
                                                   texto: "Al caer libera Sangre Vieja: +1 Corrupción."))
                }
            }
            fase = .ganado
            tituloDeResultado = "VENCES"
            detalleDeResultado = "\(enemigo.nombre) cae."
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema, texto: detalleDeResultado))
            return
        }

        if state.vida <= 0 {
            fase = .perdido
            if datos.esTutorial {
                // El texto de §3 y §4 dice que aquí no mueres: sigues con 1 de Vida.
                aplicarReves(state)
                tituloDeResultado = "TE ARRASTRAN FUERA"
                detalleDeResultado = "Te arrastran fuera. Revés: sigues con 1 de Vida y Herido."
            } else if datos.esLetal {
                tituloDeResultado = "CAES"
                detalleDeResultado = "Tu Vida llega a 0."
            } else {
                aplicarReves(state)
                tituloDeResultado = "TE RETIRAS"
                detalleDeResultado = "Te retiras con 1 de Vida. Revés: quedas Herido."
            }
            registro.append(LineaDeCombate(ronda: ronda, lado: .sistema, texto: detalleDeResultado))
            return
        }

        ronda += 1
        fase = .resuelto
    }
}

struct CombatSnapshot: Codable, Hashable {
    let seccionID: Int
    let vidaEnemigo: Int
    let fase: CombatSession.Fase
    let ronda: Int
    let ultimaTirada: Tirada?
    let ultimoImpacto: Bool
    let ultimoCritico: Bool?
    let tituloDeResultado: String
    let detalleDeResultado: String
    let registro: [LineaDeCombate]
    let parlamentoIntentado: Bool
    let parlamentoLogrado: Bool
    let salidaIntentada: Bool
    let salidaLograda: Bool
    let golpeDeGrietaArmado: Bool
    let pielDeCenizaArmada: Bool
    let donDeVocacionUsado: Bool
    /// Opcionales para que las partidas guardadas antes de "El precio del don"
    /// sigan cargando: un guardado viejo simplemente no traia estos campos.
    let furiaArmada: Bool?
    let ecoProfundoArmado: Bool?
    let ecoProfundoUsos: Int?
    let muroDeVotoArmado: Bool?

    init(_ combate: CombatSession) {
        seccionID = combate.seccionID
        vidaEnemigo = combate.vidaEnemigo
        fase = combate.fase
        ronda = combate.ronda
        ultimaTirada = combate.ultimaTirada
        ultimoImpacto = combate.ultimoImpacto
        ultimoCritico = combate.ultimoCritico
        tituloDeResultado = combate.tituloDeResultado
        detalleDeResultado = combate.detalleDeResultado
        registro = combate.registro
        parlamentoIntentado = combate.parlamentoIntentado
        parlamentoLogrado = combate.parlamentoLogrado
        salidaIntentada = combate.salidaIntentada
        salidaLograda = combate.salidaLograda
        golpeDeGrietaArmado = combate.golpeDeGrietaArmado
        pielDeCenizaArmada = combate.pielDeCenizaArmada
        donDeVocacionUsado = combate.donDeVocacionUsado
        furiaArmada = combate.furiaArmada
        ecoProfundoArmado = combate.ecoProfundoArmado
        ecoProfundoUsos = combate.ecoProfundoUsos
        muroDeVotoArmado = combate.muroDeVotoArmado
    }
}
