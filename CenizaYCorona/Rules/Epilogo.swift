import Foundation

/// EPÍLOGO POR PALABRAS CLAVE
///
/// La crónica registra 122 palabras clave, pero la mayoría no abre ni cierra
/// ninguna puerta: son memoria, no mecánica. Este fichero las convierte en lo
/// único que necesitaban, consecuencia narrativa. Al llegar a un final, el
/// texto añade las líneas de cierre que te hayas ganado.
///
/// Regla de oro: aquí no hay reglas. Nada de esto se anota en la ficha, nada
/// de esto cambia un número. Si una palabra clave necesitase una tirada,
/// estaría en ReglasEspeciales.swift, no aquí.
///
/// GENERADO desde ceniza-y-corona-app/lib/epilogue.ts. No editar a mano:
/// cambia el TypeScript y ejecuta CenizaYCorona/scripts/gen-epilogo-swift.mjs.
enum Epilogo {
    struct Linea: Hashable, Identifiable {
        var id: String { flag }
        let flag: String
        let texto: String
    }

    /// Cuántas líneas se leen como máximo al cerrar una partida.
    static let maximoDeLineas = 6

    static let lineas: [Linea] = [
        Linea(flag: "PROMESA_A_BREN",
              texto: "Le prometiste a Bren que volverías a por él. Los que cuentan esta historia discuten casi todo menos eso: que cumpliste."),
        Linea(flag: "JURAMENTO_DE_YGRID",
              texto: "El juramento que le hiciste a Sor Ygrid en el patio de El Yunque Frío no aparece en ningún registro de la Orden. Ella lo recuerda entero."),
        Linea(flag: "VISTE_A_BREN_CAUTIVO",
              texto: "Nunca se te fue de la cabeza la imagen de Bren entre dos guardias, mirándote sin pedir ayuda. Es lo que te hizo seguir andando cuando ya no quedaban razones."),
        Linea(flag: "HONDA_DE_BREN",
              texto: "Conservaste la honda hasta el final. Está gastada por el uso y nadie sabría decir de quién fue, pero tú sí."),
        Linea(flag: "MANOS_DE_VALCENAR",
              texto: "En Valcenar todavía se dice \"manos de Valcenar\" cuando alguien arregla algo que no era suyo. Empezaron a decirlo por ti."),
        Linea(flag: "HISTORIA_DEL_PADRE_CENIZA",
              texto: "Escuchaste la historia del Padre Ceniza de su propia boca. Eso no te hizo perdonarlo. Te hizo entenderlo, que es peor."),
        Linea(flag: "LA_VERDAD_DE_TOMAS",
              texto: "Tomás dijo la verdad una sola vez, y te la dijo a ti. Le costó todo lo demás."),
        Linea(flag: "NINOS_ESCONDIDOS",
              texto: "Los niños que escondiste bajo el suelo de la capilla salieron de allí al amanecer. Ninguno de ellos recuerda tu cara; todos recuerdan tu voz diciéndoles que no hicieran ruido."),
        Linea(flag: "PIEDAD_EN_LAS_RUINAS",
              texto: "Tuviste piedad entre las ruinas cuando nadie te miraba y nadie iba a agradecértelo. Es la clase de cosa por la que se mide a la gente."),
        Linea(flag: "SANGRE_INNECESARIA",
              texto: "Hubo sangre que no hacía falta derramar. La derramaste igual. Eso también viaja contigo."),
        Linea(flag: "SENDA_DEL_GUARDIAN",
              texto: "Elegiste la senda del Guardián: quedarte delante, siempre delante, aunque doliera."),
        Linea(flag: "SENDA_DEL_PROTECTOR",
              texto: "Elegiste la senda del Protector: contar a los tuyos cada noche y no dormir hasta que salieran las cuentas."),
        Linea(flag: "SENDA_DEL_CAZADOR",
              texto: "Elegiste la senda del Cazador: llegar antes que el problema, siempre."),
        Linea(flag: "SENDA_DEL_DIPLOMATICO",
              texto: "Elegiste la senda del Diplomático: ganar las habitaciones antes que los campos de batalla."),
        Linea(flag: "SENDA_DEL_INFILTRADO",
              texto: "Elegiste la senda del Infiltrado: estar donde nadie te había invitado y salir sin que se notara."),
        Linea(flag: "SENDA_DEL_INDEPENDIENTE",
              texto: "Elegiste la senda del Independiente: no deberle nada a nadie, y pagar el precio de no tener a quién pedírselo."),
        Linea(flag: "SENDA_DEL_PEREGRINO",
              texto: "Elegiste la senda del Peregrino: andar hacia la Cadena como quien va a rezar, no como quien va a romperla."),
        Linea(flag: "SENDA_DE_LA_EMISARIA",
              texto: "Elegiste la senda de la Emisaria: hablar por los que no tenían con qué hablar."),
        Linea(flag: "SENDA_DE_LA_HEREJE",
              texto: "Elegiste la senda de la Hereje: hacer la pregunta que estaba prohibida y no bajar la voz al hacerla."),
        Linea(flag: "CAMINO_EN_SOLITARIO",
              texto: "Hiciste casi todo el camino sola. No fue orgullo: fue que soltar a la gente te parecía más limpio que enterrarla."),
        Linea(flag: "GRUPO_UNIDO",
              texto: "El grupo llegó entero hasta donde pudo llegar un grupo. Eso, en estos años, es casi un milagro administrativo."),
        Linea(flag: "NO_VAS_SOLA",
              texto: "Alguien te dijo, en el peor momento, que no ibas sola. Resultó ser verdad."),
        Linea(flag: "ALIADA_NIMA",
              texto: "Nima sigue viva y sigue siendo insoportable. Te manda cartas que no contestas y que guardas todas."),
        Linea(flag: "TREGUA_DE_LA_ESTEPA",
              texto: "La tregua de la estepa aguantó más que muchos tratados firmados con lacre. Nadie la escribió nunca."),
        Linea(flag: "CLANES_DE_LA_ESTEPA",
              texto: "Los clanes de la estepa te cuentan entre las pocas personas del sur que dijeron lo que iba a hacer y luego lo hizo."),
        Linea(flag: "ORDEN_DIVIDIDA_CONOCIDA",
              texto: "Supiste antes que la propia Orden que la Orden estaba partida en dos. Tardaron años en admitir en voz alta lo que tú viste en una tarde."),
        Linea(flag: "LISTA_DEL_CENSO",
              texto: "La lista del Censo acabó copiada, repartida y leída en sitios donde no debía leerse. Ya no hay forma de volver a esconder esos nombres."),
        Linea(flag: "CIEN_NOMBRES",
              texto: "Cien nombres. Los leíste todos en voz alta porque alguien tenía que hacerlo, y porque leerlos deprisa habría sido otra forma de perderlos."),
        Linea(flag: "LISTA_DE_NOMBRES",
              texto: "Guardaste la lista de nombres hasta el final. No servía para nada. Servía para no olvidar para qué habías ido."),
        Linea(flag: "VERDAD_ANTE_LAS_CASAS",
              texto: "Dijiste la verdad delante de las Cinco Casas, en su salón, con sus guardias en la puerta. No te lo han perdonado y no hacía falta que lo hicieran."),
        Linea(flag: "REPUTACION_EN_LOS_MUELLES",
              texto: "En los muelles de Cárdenas tu nombre todavía abre puertas y cierra conversaciones, según quién esté escuchando."),
        Linea(flag: "CONTACTO_CON_SERA",
              texto: "Sera nunca te dio las gracias. Te dio algo mejor: siguió pasándote información cuando ya no tenía ningún motivo para hacerlo."),
        Linea(flag: "CONTACTO_CON_VAAS",
              texto: "Vaas cumplió su parte. Cobrarla le costó más de lo que había calculado, y aun así la cumplió."),
        Linea(flag: "DENNA_ESCUCHADA",
              texto: "Escuchaste a Denna hasta el final, sin interrumpirla. Fue la primera persona que lo hizo en once años."),
        Linea(flag: "VERDAD_DEL_LIGAMEN",
              texto: "Aprendiste qué es de verdad un Ligamen. Hay conocimientos que no se pueden devolver."),
        Linea(flag: "DOCE_VOLUNTARIOS",
              texto: "Fueron doce los que levantaron la mano sabiendo lo que había abajo. Sus nombres están en el diario de la Cuarta, con la letra apretada del final."),
        Linea(flag: "VOLUNTARIOS_DEL_VALLE",
              texto: "La gente del valle se ofreció sin que nadie se lo pidiera. Es lo que más te costó aceptar de todo el viaje."),
        Linea(flag: "MARCADOS_CONSULTADOS",
              texto: "Preguntaste a los Marcados antes de decidir por ellos. Parece poca cosa. En trescientos años nadie lo había hecho."),
        Linea(flag: "MARCADOS_DEL_VALLE",
              texto: "Los Marcados del valle dejaron de esconder la muñeca. No todos, no en todas partes, pero empezaron."),
        Linea(flag: "LA_COLUMNA_CRUZO",
              texto: "La columna cruzó. Tardó tres días más de lo previsto y llegó entera, que era lo único que importaba."),
        Linea(flag: "EXPEDICION_UNIDA",
              texto: "La expedición no se rompió por dentro, que era la forma en que se rompían todas las anteriores."),
        Linea(flag: "CANCION_VARDA",
              texto: "Alguien silbó la canción varda en el descenso, donde no debía sonar nada. Aquello os sostuvo más que las cuerdas."),
        Linea(flag: "ILENA_ALIADA",
              texto: "Ilena dejó de vigilarte en algún punto del camino y empezó a caminar a tu lado. Nunca comentasteis el cambio."),
        Linea(flag: "CONDICIONES_A_ILENA",
              texto: "Le pusiste condiciones a Ilena y las aceptó. Las cumplió incluso cuando dejaste de estar en posición de exigirlas."),
        Linea(flag: "DIARIO_DE_LA_CUARTA",
              texto: "El diario de la Cuarta Expedición volvió a la superficie contigo. Se lee mal, se entiende peor y es el documento más honesto que existe sobre la Grieta."),
        Linea(flag: "CUARTA_OPCION_PLANTEADA",
              texto: "Plantéaste una cuarta salida cuando todo el mundo daba por hechas que solo había tres. Que funcionara o no es otra discusión: la planteaste."),
        Linea(flag: "SEGUNDA_RESPONDIDA",
              texto: "Respondiste a la segunda pregunta. La primera la responde cualquiera; la segunda solo se responde sabiendo lo que cuesta."),
        Linea(flag: "ASHKELEN_NOMBRADO",
              texto: "Nombraste a Ashkelen en voz alta. Los nombres, abajo, no son una formalidad."),
        Linea(flag: "RASTRO_DE_ASHKELEN",
              texto: "Seguiste el rastro de Ashkelen hasta donde el rastro dejaba de ser un rastro y pasaba a ser una invitación."),
        Linea(flag: "POSTURA_REFORJAR",
              texto: "Bajaste convencida de que la Cadena podía reforjarse. Lo que viste abajo no te hizo cambiar de idea, y eso también hay que sostenerlo."),
        Linea(flag: "POSTURA_ROMPER",
              texto: "Bajaste convencida de que la Cadena tenía que romperse. Nadie que estuviera allí puede decir que no te avisaron."),
        Linea(flag: "POSTURA_PREGUNTAR",
              texto: "Bajaste sin decidir nada, dispuesta a preguntar primero. Fue la postura menos heroica y la única que dejó sitio a lo que encontraste."),
        Linea(flag: "MAPA_DE_LAS_FAUCES",
              texto: "El mapa de las Fauces sigue doblado en cuatro, con tus correcciones al margen. Alguien lo usará después de ti y le salvará la vida sin saber a quién."),
        Linea(flag: "TABLILLA_DE_ARCILLA_RUNICA",
              texto: "La tablilla rúnica está en manos de gente que sabe leerla. Discuten sobre ella. Discutir sobre ella ya es mejor que lo que había antes."),
        Linea(flag: "LAS_FAUCES_ROTAS",
              texto: "Las Fauces quedaron rotas a tu paso. La ruta del norte volvió a ser una ruta y no una emboscada con nombre propio."),
        Linea(flag: "RECONOCIDO_POR_LA_ORDEN",
              texto: "La Orden de la Ceniza acabó reconociéndote. Tarde, a regañadientes y por escrito, que es como reconoce la Orden."),
        Linea(flag: "AGENTE_DE_LA_ORDEN",
              texto: "Trabajaste para la Orden. Cargar con eso resultó ser más complicado que cargar con la Marca."),
        Linea(flag: "ALIADA_INDEPENDIENTE_DE_LA_ORDEN",
              texto: "Ayudaste a la Orden sin pertenecer a ella. Nunca supieron dónde ponerte, y esa fue exactamente tu ventaja."),
        Linea(flag: "PACTO_CON_SERA",
              texto: "Le prometiste a Sera que la avisarías antes de usar la lista, y la avisaste. En El Refugio aún se cuenta que hubo tiempo de sacar a la gente porque alguien de fuera cumplió su palabra."),
        Linea(flag: "EVIDENCIA_SIN_ATADURAS",
              texto: "No le prometiste a Sera lo que no pensabas cumplir. Usaste la lista cuando hizo falta, sin permiso de nadie. Salvó la votación; no salvó a todo el mundo."),
        Linea(flag: "REFUGIO_PROTEGIDO",
              texto: "El Refugio nunca salió de tu boca. Sigue sin aparecer en ningún registro, ningún informe y ninguna crónica oficial: existe porque tú no lo nombraste."),
        Linea(flag: "REFUGIO_COMO_BAZA",
              texto: "Te reservaste el derecho de enseñar El Refugio si hacía falta, y Sera te dejó marchar sabiéndolo. Esa honestidad incómoda es lo único que le impidió sentirse traicionada después."),
        Linea(flag: "ENCARGO_SIN_PREGUNTAS",
              texto: "Aceptaste el encargo de Casa Vaas sin preguntar de qué se trataba. Corvina lo contó durante años como la prueba de que se podía confiar en ti; nunca supo lo cerca que estuvo de costarte la vida."),
        Linea(flag: "ENCARGO_CON_CONDICIONES",
              texto: "Antes de trabajar para Casa Vaas exigiste saber en qué te metías. Corvina no estaba acostumbrada a que le preguntaran, y acabó tratando contigo de igual a igual por eso."),
        Linea(flag: "NOCHE_DE_BALANCE",
              texto: "Pasaste tu última noche libre caminando sola por Cárdenas, poniendo en orden lo que sabías. Entraste en el palacio sin haber dormido y sin una sola duda."),
        Linea(flag: "NOCHE_EN_VELA",
              texto: "No pegaste ojo la víspera de la Convocatoria. Las piezas sueltas te tuvieron despierta hasta el amanecer, y por eso las tenías todas a mano cuando hizo falta."),
        Linea(flag: "ULTIMO_CONSEJO_DE_CORVINA",
              texto: "Esperaste despierta y Corvina apareció, como sospechabas. «No dejes que decidan por ti cuál de las dos eres.» Fue lo último que te dijo, y lo único que recordaste dentro del palacio."),
        Linea(flag: "ENTRADA_ANUNCIADA",
              texto: "Entraste en el monasterio por la puerta principal, a plena luz y con el salvoconducto por delante. Nadie pudo decir nunca que te hubieras colado; todos supieron desde el primer minuto que estabas allí."),
        Linea(flag: "ALA_ESTE_VISTA_DE_CERCA",
              texto: "Rodeaste el monasterio antes de anunciarte y viste el ala este por tu cuenta: los andamios que no reparaban nada, la piedra vidriada, el camino de carro que bajaba desde la portezuela de servicio. Supiste que estaban vaciando aquel sitio mucho antes de que nadie te lo contara."),
    ]

    private static let indice: [String: String] = Dictionary(uniqueKeysWithValues: lineas.map { ($0.flag, $0.texto) })

    /// Las líneas de epílogo ganadas, en orden de lectura.
    static func para(_ flags: Set<String>, maximo: Int = maximoDeLineas) -> [String] {
        var resultado: [String] = []
        for linea in lineas where flags.contains(linea.flag) {
            resultado.append(linea.texto)
            if resultado.count >= maximo { break }
        }
        return resultado
    }

    static func linea(para flag: String) -> String? { indice[flag] }
}
