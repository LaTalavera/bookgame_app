import Foundation

/// Parte V. Hechizos de la Vidente Rota y del Penitente.
struct Hechizo: Hashable, Codable, Identifiable {
    enum Momento: String, Codable, Hashable { case combate, fueraDeCombate }

    var id: String { nombre }
    let nombre: String
    let coste: Int              // en Ecos
    let momento: Momento
    let descripcion: String
    /// Daño si es un ataque mágico (2D6 + VOL contra la Defensa).
    var dano: Int = 0
    /// Curación fuera de combate.
    var curaD6: Int = 0
    var curaBonus: Int = 0

    var esAtaque: Bool { momento == .combate && dano > 0 }

    // Vidente Rota
    static let chispaNegra = Hechizo(
        nombre: "Chispa Negra", coste: 1, momento: .combate,
        descripcion: "Ataque mágico: 2D6 + VOL contra la Defensa. Daño 4.", dano: 4)
    static let susurroDePiel = Hechizo(
        nombre: "Susurro de Piel", coste: 1, momento: .fueraDeCombate,
        descripcion: "Superas automáticamente una prueba de VOL Fácil o Media.")
    static let grietaMenor = Hechizo(
        nombre: "Grieta Menor", coste: 2, momento: .combate,
        descripcion: "Ataque mágico. Daño 4. Si acierta, el objetivo sufre -1 a su próxima tirada.", dano: 4)
    static let ojoCeniciento = Hechizo(
        nombre: "Ojo Ceniciento", coste: 1, momento: .fueraDeCombate,
        descripcion: "Lees una escena, objeto o persona buscando resonancia de Sangre Vieja.")
    static let veloRoto = Hechizo(
        nombre: "Velo Roto", coste: 2, momento: .fueraDeCombate,
        descripcion: "+3 a una prueba de sigilo (AGI) inmediatamente posterior.")
    static let cadenaDeEco = Hechizo(
        nombre: "Cadena de Eco", coste: 3, momento: .combate,
        descripcion: "Ataque mágico contra dos objetivos. Daño 3 a cada uno alcanzado.", dano: 3)

    // Penitente
    static let manosDeCeniza = Hechizo(
        nombre: "Manos de Ceniza", coste: 1, momento: .fueraDeCombate,
        descripcion: "Curas 1D6 PV a ti mismo o a un aliado presente.", curaD6: 1)
    static let muroDeVoto = Hechizo(
        nombre: "Muro de Voto", coste: 1, momento: .combate,
        descripcion: "Reduce en 2 el daño que vas a recibir esta ronda.")
    static let luzDeCadenaRota = Hechizo(
        nombre: "Luz de Cadena Rota", coste: 2, momento: .combate,
        descripcion: "Daño 5 contra Quebrados e incorpóreos; Daño 2 contra el resto.", dano: 5)
    static let juramentoCompartido = Hechizo(
        nombre: "Juramento Compartido", coste: 2, momento: .fueraDeCombate,
        descripcion: "Tú y tu aliado recuperáis 1D6 PV.", curaD6: 1)
}

/// Parte V, §26. Cualquier Marcado puede forzar su don pagando Corrupción.
struct DonForzado: Hashable, Codable, Identifiable {
    enum Efecto: String, Codable, Hashable {
        case bonoDeAtaque      // Golpe de Grieta
        case ignorarDano       // Piel de Ceniza
        case exitoAutomatico   // Voz Rota
        case narrativo         // Aliento de la Grieta
    }

    var id: String { nombre }
    let nombre: String
    let costeCorrupcion: Int
    let efecto: Efecto
    let descripcion: String
    var bono: Int = 0
    var enCombate: Bool = true

    static let golpeDeGrieta = DonForzado(
        nombre: "Golpe de Grieta", costeCorrupcion: 1, efecto: .bonoDeAtaque,
        descripcion: "+3 a una sola tirada de ataque.", bono: 3)
    static let pielDeCeniza = DonForzado(
        nombre: "Piel de Ceniza", costeCorrupcion: 1, efecto: .ignorarDano,
        descripcion: "Ignoras todo el daño de un único golpe enemigo.")
    static let vozRota = DonForzado(
        nombre: "Voz Rota", costeCorrupcion: 2, efecto: .exitoAutomatico,
        descripcion: "Superas automáticamente una prueba de habilidad, sea cual sea su dificultad.",
        enCombate: false)
    static let alientoDeLaGrieta = DonForzado(
        nombre: "Aliento de la Grieta", costeCorrupcion: 2, efecto: .narrativo,
        descripcion: "Fuerzas una puerta, sanas una herida grave o sobrevives a algo que debería matarte.",
        enCombate: false)

    static let enCombateDisponibles: [DonForzado] = [.golpeDeGrieta, .pielDeCeniza]
    static let fueraDeCombate: [DonForzado] = [.vozRota, .alientoDeLaGrieta]
}
