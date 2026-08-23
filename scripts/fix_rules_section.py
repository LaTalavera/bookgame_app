#!/usr/bin/env python3
"""Reconstruye las páginas 12-22 (Parte II final + Parte III) del libro final.

Corrige, sin renumerar nada fuera del rango afectado:
  - §13 Combate quedaba cortado a mitad de la iniciativa porque la página 12
    fue sustituida por el equipo en vez de continuar con Tirada de ataque /
    Daño / Réplica / Defensa base. Se restaura ese texto (verificado contra
    el PDF anterior a la integración) y NO se renumera nada.
  - "19 bis", "18 bis", "19 ter" y "19 quater" eran apartados sueltos,
    insertados con un título a tamaño de Parte (25pt) y luego aplanados a
    imagen de 200dpi, lo que introducía artefactos de kerning ("pr opósito",
    "Equilibr io") y los hacía leer como capítulos aparte. Se pliegan como
    subapartados con estilo de cuerpo dentro de §13 (Salidas de vocación,
    El propósito del combate) y §18 (Decisiones de expedición), sin crear
    números nuevos, así ninguna referencia cruzada del resto del libro
    (p. ej. "Revisa la sección 16" en la página 11) se rompe.
  - "19 quater. Equilibrio de las vocaciones" era una nota de QA/desarrollo
    ("Las dos aplicaciones verifican 24/24 finales...") dirigida al autor,
    no al jugador; se retira del texto jugable.
  - La Hoja de Personaje (§23) solo mostraba Nombre/Vocación/atributos/
    Vida/Defensa/Ecos/Corrupción: le faltaban Reputación, Equipo en mano,
    Mochila (6 espacios) y Palabras clave, pese a que las reglas del propio
    libro piden anotarlos. Se restaura la ficha completa.

Todo el contenido se compone como un único flujo (Platypus) para que la
paginación salga sola: nada de saltos de página adivinados a mano.
"""

from pathlib import Path

from pypdf import PdfReader, PdfWriter
from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageBreak, PageTemplate, Paragraph, Spacer,
    Table, TableStyle,
)

ROOT = Path(__file__).resolve().parents[2]
FONTS = Path(__file__).resolve().parent / "fonts"

# El resto del libro compone el cuerpo en DejaVu Serif y los títulos
# numerados en Caladea Bold — se extrajeron los nombres exactos con
# `page.get_text("dict")` sobre páginas nativas (no tocadas por ningún
# script). Los subconjuntos que trae el propio PDF no sirven para volver a
# componer texto (cmap solo Mac Roman); se usan aquí las fuentes completas:
# DejaVu Serif tal cual la distribuye matplotlib, y Caladea desde su
# repositorio oficial (googlefonts/caladea, SIL OFL).
pdfmetrics.registerFont(TTFont("DejaVuSerif", str(FONTS / "DejaVuSerif.ttf")))
pdfmetrics.registerFont(TTFont("DejaVuSerif-Bold", str(FONTS / "DejaVuSerif-Bold.ttf")))
pdfmetrics.registerFont(TTFont("DejaVuSerif-Italic", str(FONTS / "DejaVuSerif-Italic.ttf")))
pdfmetrics.registerFont(TTFont("DejaVuSerif-BoldItalic", str(FONTS / "DejaVuSerif-BoldItalic.ttf")))
pdfmetrics.registerFontFamily(
    "DejaVuSerif", normal="DejaVuSerif", bold="DejaVuSerif-Bold",
    italic="DejaVuSerif-Italic", boldItalic="DejaVuSerif-BoldItalic",
)
pdfmetrics.registerFont(TTFont("Caladea-Bold", str(FONTS / "Caladea-Bold.ttf")))
pdfmetrics.registerFont(TTFont("Caladea-BoldItalic", str(FONTS / "Caladea-BoldItalic.ttf")))
# Única copia que queda del libro: 261 páginas, ya con el bloque de reglas
# en su sitio (12-16) — cada ejecución vuelve a tejer solo esas 5 páginas
# con estilo corregido y conserva el resto del PDF byte a byte.
SOURCE = ROOT / "CenizaYCorona_SAGA_ILUSTRADA_EDICION_EQUILIBRADA.pdf"
OUTPUT = SOURCE
PARCHMENT_FILL = ROOT / "output" / "imagegen" / "ceniza-corona-parchment-fill.png"
ORNAMENTAL_FRAME = ROOT / "output" / "imagegen" / "ceniza-corona-ornamental-frame.png"

# Primera página física (1-based) que se sustituye. Dónde termina el bloque
# se calcula solo: se busca "PARTE IV — BESTIARIO DE VAELGARD" a partir de
# aquí (ver rebuild_pdf), así una repetición nunca deja huérfano ni
# duplicado ningún tramo aunque el bloque cambie de tamaño.
FIRST_REPLACED_PAGE = 12

# Colores verificados con page.get_text("dict") sobre páginas nativas:
# títulos de Parte en #6e1423, números de sección en #3d3d3d, cuerpo en
# negro puro. GOLD/PARCHMENT quedan solo para el fondo de las tablas.
PART_WINE, HEAD_GRAY, TEXT_BLACK = HexColor("#6e1423"), HexColor("#3d3d3d"), HexColor("#000000")
GOLD, ASH = HexColor("#a47732"), HexColor("#675c52")
HEAD_BG, ROW_BG, GRID = HexColor("#eee0bd"), HexColor("#fbf6e9"), HexColor("#d2bb8a")


def p(text, style):
    return Paragraph(text, style)


def decorated_page(canvas_, _doc):
    """Mismo pergamino + marco que usan las páginas narrativas del libro,
    dibujados como imágenes vectoriales normales (sin aplanar a raster),
    para que el texto salga tan nítido como en el resto del libro."""
    canvas_.saveState()
    canvas_.drawImage(str(PARCHMENT_FILL), 0, 0, width=letter[0], height=letter[1], mask="auto")
    canvas_.drawImage(str(ORNAMENTAL_FRAME), 0, 0, width=letter[0], height=letter[1], mask="auto")
    canvas_.restoreState()


def build_story():
    base = getSampleStyleSheet()
    # Título de Parte: Caladea-Bold 18pt #6e1423 (idéntico a "PARTE II — CÓMO
    # JUGAR" en la página 10, nunca tocada por ningún script).
    part = ParagraphStyle("part", parent=base["Title"], fontName="Caladea-Bold", fontSize=18,
                           leading=22, textColor=PART_WINE, spaceBefore=14, spaceAfter=10,
                           keepWithNext=1)
    # Título de sección numerada: Caladea-Bold 14pt #3d3d3d (idéntico a
    # "9. Qué necesitas" / "17. Reputación" en páginas nativas).
    h = ParagraphStyle("h", parent=base["Heading2"], fontName="Caladea-Bold", fontSize=14,
                        leading=18, textColor=HEAD_GRAY, spaceBefore=14, spaceAfter=6,
                        keepWithNext=1)
    # Subapartado dentro de un capítulo (no existe en el libro original —
    # es donde se pliegan "Salidas de vocación" y "El propósito del
    # combate"): mismo Caladea-Bold, un escalón más pequeño que "h".
    sub = ParagraphStyle("sub", parent=base["Heading3"], fontName="Caladea-Bold", fontSize=12.5,
                          leading=16, textColor=HEAD_GRAY, spaceBefore=12, spaceAfter=4,
                          keepWithNext=1)
    # Cuerpo: DejaVu Serif 12pt negro puro, igual que cualquier otra página.
    body = ParagraphStyle("body", parent=base["BodyText"], fontName="DejaVuSerif", fontSize=12,
                           leading=15.5, textColor=TEXT_BLACK, spaceAfter=8)
    # Arranque en negrita dentro de un párrafo ("Ruptura:" en el glosario,
    # p. 9): DejaVu Serif Bold, mismo negro, no wine.
    label = ParagraphStyle("label", parent=body, fontName="DejaVuSerif-Bold", fontSize=12,
                            leading=15.5, textColor=TEXT_BLACK, spaceAfter=0)
    cell = ParagraphStyle("cell", parent=body, fontSize=11, leading=14.5, spaceAfter=0)
    note = ParagraphStyle("note", parent=body, fontName="DejaVuSerif-Italic", fontSize=10.5,
                           leading=13.5, textColor=ASH)

    def sheet_table(rows, col_widths=(1.7 * inch, 5.1 * inch)):
        t = Table(rows, colWidths=list(col_widths))
        t.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (0, -1), HEAD_BG), ("BACKGROUND", (1, 0), (1, -1), ROW_BG),
            ("BOX", (0, 0), (-1, -1), 0.7, GOLD), ("INNERGRID", (0, 0), (-1, -1), 0.4, GRID),
            ("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 10),
            ("RIGHTPADDING", (0, 0), (-1, -1), 10), ("TOPPADDING", (0, 0), (-1, -1), 7),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ]))
        return t

    story = []

    # ── §13 Combate — se restaura la mecánica que faltaba y se pliegan ──
    # ── "Salidas de vocación" y "El propósito del combate" como cierre ──
    story += [
        p("Tirada de ataque.", label),
        p("El atacante tira 2D6 y suma su Ataque (para ti: FUE si usas un arma cuerpo a cuerpo, "
          "AGI si usas un arma a distancia, VOL si lanzas un hechizo de ataque, más los bonos de "
          "tu equipo). Si el resultado iguala o supera la Defensa del objetivo, el golpe acierta.", body),
        p("Daño.", label),
        p("Si acierta, réstale al objetivo el Daño del arma o hechizo usado. Si tu atributo "
          "relevante es 7 o más, añade +1 de daño.", body),
        p("<b>Golpe de gracia.</b> Si tu tirada de ataque supera la Defensa del enemigo por 5 o "
          "más, duplica el daño del arma o hechizo, incluido el +1 por atributo alto. Las ventajas "
          "adicionales de la escena se suman después.", body),
        p("Réplica.", label),
        p("Ahora ataca el otro combatiente, repitiendo los pasos de tirada y daño.", body),
        p("El combate continúa, ronda tras ronda, hasta que la Vida de uno de los dos llegue a 0, "
          "hasta que el texto ofrezca una salida (huir, negociar, usar un objeto), o hasta que se "
          "cumpla la condición especial de la ficha.", body),
        p("Tu Defensa base es 8 + tu bono de armadura/escudo (indicado en tu Hoja de Personaje). "
          "Los enemigos atacan contra ese número.", body),
        p("Cuando derrotes a un enemigo o sobrevivas al combate, el texto te indicará a qué "
          "sección ir. Si tu Vida llega a 0, ve a la sección de derrota indicada en el propio "
          "combate; si no se indica ninguna, tu historia termina aquí — anota dónde has caído y, "
          "si quieres, empieza nueva partida con un personaje nuevo, como haría cualquier "
          "superviviente de Vaelgard.", body),

        p("Salidas de vocación", sub),
        p("No todo combate hay que ganarlo, y algunos no hay siquiera que empezarlos. Las cuatro "
          "vocaciones tienen encuentros donde su naturaleza abre una salida propia.", body),
        p("<b>Cuchilla de Ceniza — imponerse.</b> Ante rivales prudentes o mercenarios, tira una "
          "prueba de FUE para demostrar que el combate no les compensará.", body),
        p("<b>Vigía Errante — no ser vista.</b> Ante una bestia o una patrulla que todavía no te "
          "ha fijado, tira una prueba de AGI. Si la superas, el combate no ocurre y la historia "
          "sigue por donde seguiría si lo hubieras ganado.", body),
        p("<b>Vidente Rota — hablarle.</b> Ante un Quebrado, un Eco, un Ancla o una Cosa de "
          "Eslabón, tira una prueba de VOL. Si la superas, se aparta.", body),
        p("<b>Penitente — invocar tregua.</b> Ante enemigos que aún conserven fe o disciplina, "
          "tira una prueba de VOL para recordarles un juramento más antiguo.", body),
        p("En ambos casos: una sola tentativa, y solo antes de dar el primer golpe. Si fallas, el "
          "combate empieza con normalidad. Si tu vocación es otra puedes intentarlo igualmente, "
          "pero un peldaño de dificultad por encima del que figura en la sección: nada aquí te "
          "está vedado, solo te cuesta más. Las criaturas cuya ficha no menciona esta salida no "
          "la admiten: hay cosas en Vaelgard que no se esquivan y no escuchan.", body),

        p("Segunda vía", sub),
        p("Algunas pruebas de habilidad admiten una segunda forma de superarse: forzar donde otra persona se colaría, imponerse donde otra convencería. Cuando la sección la ofrece, indica el atributo y la dificultad — siempre un peldaño por encima de la vía principal, porque la escena no está pensada para resolverse así. Eliges una vía u otra antes de tirar, tiras una sola vez, y tanto el éxito como el fracaso llevan exactamente a donde llevarían por la vía principal: no abre camino propio, solo deja que cada personaje lo intente a su manera.", body),

        p("<b>Secciones con segunda vía.</b> Tres secciones de la Saga la usan, y sus páginas fueron compuestas antes que esta regla: §1072 — además de VOL (Media, 9+) para convencer al carretero, puedes presionarlo con FUE (Difícil, 11+); §1126 — además de AGI (Difícil, 11+) para colarte por el puesto de control, puedes imponerte con FUE (Heroica, 13+); §1133 — forzar las cadenas rituales es una prueba de FUE (Difícil, 11+), no de AGI: el texto describe un forcejeo, no un descuido. En los tres casos, el éxito y el fracaso llevan a las mismas secciones que ya indica su página.", body),

        p("El propósito del combate", sub),
        p("Antes de tirar los dados, lee el objetivo del encuentro y la intención de tu "
          "adversario si el texto los da: no reemplazan las reglas especiales de la ficha, las "
          "convierten en una táctica visible. Un combate no siempre premia hacer más daño — "
          "algunas criaturas huyen, otras se rinden si no consiguen tocarte, y ciertas salidas "
          "existen antes del primer golpe.", body),
        p("<b>Herido.</b> Cuando tu Vida baja a la mitad de su máximo o menos, anota Herido. Tu "
          "próxima prueba de FUE o AGI recibe −1. Borra la marca cuando recuperes más de la mitad "
          "de tu Vida; si ya sufriste la penalización, no vuelve hasta que te cures y seas herido "
          "de nuevo.", body),
        p("<b>Revés.</b> Perder un combate que el texto no marca como mortal no te mata: te "
          "retiras con 1 de Vida y quedas Herido. Cuenta siempre como herida nueva, así que la "
          "penalización de Herido vuelve a pesar aunque ya la hubieras gastado antes. Salir vivo "
          "de un combate perdido tiene precio; ese es todo el precio.", body),
        p("<b>Retirada.</b> Un enemigo que empiece con 16 o más de Vida abandona al quedar con un "
          "20% o menos, salvo que sea un adversario mayor o su ficha diga otra cosa.", body),

        p("Compañía", sub),
        p("En el descenso a la Grieta (Libro Tercero) eliges con quién bajas. Esa decisión no se "
          "gasta ni se gestiona: anótala una vez en tu Hoja de Personaje y aplícala mientras dure "
          "el descenso.", body),
        p("<b>Maestro Combe:</b> +1 al daño de tus ataques. <b>Orwyn:</b> +1 a tu Defensa. "
          "<b>Ilena Fos:</b> +1 a tus pruebas de VOL. <b>Bajas sola:</b> +1 a tus Ecos máximos — "
          "nadie te distrae y la Grieta se oye entera.", body),
    ]

    # ── §14 Objetos y equipo (sin cambios de número ni de cifras) ──
    story += [
        p("14. Objetos y equipo", h),
        p("El equipo inicial ya está incluido en cada vocación. Las armas usan su Daño al "
          "impactar; armaduras, escudos y focos suman Defensa.", body),
        sheet_table([
            [p("ARMA", label), p("DAÑO", label), p("NOTA", label)],
            [p("Daga", cell), p("2", cell), p("Ligera y discreta.", cell)],
            [p("Espada corta", cell), p("3", cell), p("Equilibrada.", cell)],
            [p("Espada larga / hacha", cell), p("4", cell), p("Arma de la Cuchilla.", cell)],
            [p("Maza", cell), p("4", cell), p("Arma del Penitente.", cell)],
            [p("Arco corto", cell), p("3", cell), p("El Vigía ataca primero en la primera ronda.", cell)],
            [p("Honda de Bren", cell), p("2", cell), p("Atacas primero en la primera ronda. Solo si la conservas.", cell)],
            [p("Bastón", cell), p("3", cell), p("También permite canalizar hechizos.", cell)],
        ], col_widths=(1.9 * inch, 1.0 * inch, 3.4 * inch)),
        p("Cuero reforzado: +1 Defensa. Cota de malla: +2 Defensa (requiere FUE 5+; −1 a pruebas "
          "de AGI). Armadura ligera: +2 Defensa. Escudo o foco protector: +1 Defensa. Si recibes "
          "equipo nuevo, aplica sus modificadores y conserva el que la sección indique.", body),
        p("Mochila. Tienes 6 espacios para objetos consumibles y tesoros (pociones, llaves, "
          "reliquias, provisiones). Los objetos de equipo (arma, arma secundaria, armadura, "
          "amuleto) no ocupan espacio de mochila; se llevan puestos.", body),

        p("Herramientas y recursos", sub),
        p("Algunos objetos no se usan: se llevan. Cuando una sección te pide una prueba y el texto "
          "menciona un objeto que llevas encima, ese objeto cambia la prueba de una de dos maneras, "
          "y nunca de una tercera:", body),
        p("<b>Una herramienta resuelve la prueba y no se gasta.</b> Las ganzúas del armero abren la "
          "cerradura sin tirar. Sigues teniéndolas después.", body),
        p("<b>Un recurso te deja repetir la prueba y se gasta en el intento.</b> Una cuerda amarrada a "
          "un descenso te da una segunda oportunidad y se queda allí; el frasco de tinta de Grieta "
          "compra una segunda tirada de VOL y se vacía. Decides después de ver el fallo.", body),
        p("<b>La oscuridad cobra un peldaño.</b> Bajo tierra, en el pozo del Libro Tercero, quien no "
          "lleve la lámpara de aceite pesado hace todas sus pruebas a un nivel más de dificultad "
          "(una Media se resuelve como Difícil). Encender una yesca sirve de luz improvisada para "
          "una sola prueba, y la gasta.", body),

        p("15. Palabras clave y decisiones que recuerdas", h),
        p("A lo largo del libro encontrarás instrucciones como <i>Anota la palabra clave: FAROL "
          "ROTO.</i> Anótala en tu Hoja de Personaje. Más adelante, alguna sección dirá: "
          "<i>Si tienes la palabra clave FAROL ROTO, ve a la sección 210. Si no, ve a la sección "
          "84.</i> Las palabras clave representan lo que tu personaje sabe, ha hecho o lleva "
          "consigo: no hace falta que recuerdes los detalles, solo que las tengas anotadas.", body),

        p("16. Corrupción y la Sangre Vieja", h),
        p("Como Marcado, en ciertos momentos el libro te ofrecerá la opción de forzar tu don — "
          "tirar de la Sangre Vieja más allá de lo prudente para conseguir una ventaja inmediata. "
          "Cada vez que lo hagas, sube tu Corrupción en 1.", body),
        p("El precio del don", sub),
        p("El don de tu vocación — la Furia de la Cuchilla, el Ojo del Vigía, el Eco de la Vidente, el Voto del Penitente — también es Sangre Vieja, y también se paga: cada vez que lo uses, sube tu Corrupción en 1. Siempre lo decides tú; ningún don salta solo. Y si tu Corrupción ya está en 10, no queda nada que llamar: el don no responde.", body),
        p("La Furia de Forjagrís se declara antes de golpear, pero solo se cobra si llega a repetir: si aciertas a la primera, no has llamado a nada.", body),
        p("<b>Corrupción 0–3</b> — Sin efecto aparente. Algunos Marcados y bestias sensibles a la "
          "Sangre Vieja pueden, aun así, «notarte».", body),
        p("<b>Corrupción 4–6</b> — Ciertas opciones oscuras se abren en el texto. Los animales te "
          "evitan. Algunos NPC perceptivos reaccionan con recelo.", body),
        p("<b>Corrupción 7–9</b> — Empiezas a mutar: pierdes permanentemente 1 punto de VOL y "
          "ganas 1 punto de FUE (anótalo). El texto empieza a llamarte, en ciertas secciones, "
          "«el Quebrado».", body),
        p("<b>Corrupción 10</b> — Te pierdes. Ve a la sección 950: no es necesariamente el final "
          "de tu historia, pero sí el final de quién eras.", body),
        p("La Corrupción no baja con el descanso. Solo ciertos rituales, ciertas personas y "
          "ciertas renuncias —que encontrarás en la historia— pueden reducirla. Piénsalo dos "
          "veces antes de forzar tu don.", body),
    ]

    # ── §17 Reputación, §18 Descanso (+ decisiones de expedición), §19 Muerte ──
    story += [
        p("17. Reputación", h),
        p("Tres facciones llevan la cuenta de lo que haces: la Orden de la Ceniza, la Secta de "
          "los Renacidos y Los Libres. Cada una tiene un marcador que va de −5 a +5, empezando en "
          "0. Ciertas decisiones lo modifican; el texto te avisará cuando ocurra («+1 Reputación "
          "con la Orden de la Ceniza»). Tu reputación determina qué puertas se abren —y cuáles se "
          "cierran— en los tramos finales del libro.", body),

        p("18. Descanso", h),
        p("Cuando el texto muestre el símbolo de la vela — Punto de Descanso —, puedes recuperar "
          "todos tus Ecos, recuperar la mitad de tu Vida máxima (redondeando hacia arriba) si no "
          "estás en "
          "peligro inmediato, y revisar tu Hoja de Personaje con calma. No puedes descansar en "
          "cualquier otro momento: en La Marca Rota, el peligro no espera a que te recuperes.", body),
        p("Además, cada Punto de Descanso te deja elegir un <b>preparativo</b> gratuito para el "
          "peligro que viene: es opcional, no cuesta recursos, no cierra ninguna ruta y puedes "
          "cambiarlo en el siguiente descanso.", body),
        p("<b>Vigilar la ruta.</b> Distribuyes guardias, señalas una retirada y estudias el "
          "terreno: el primer ataque enemigo del próximo combate recibe −2.", body),
        p("<b>Leer el camino.</b> Repasas huellas, silencios y señales: la próxima prueba con "
          "dados recibe +2. Un don de éxito automático no lo consume.", body),
        p("<b>Callar la Grieta.</b> Reduces tu Corrupción en 1, pero no podrás elegir preparativo "
          "en el siguiente Punto de Descanso. En el segundo descanso posterior vuelves a elegir "
          "con normalidad. Solo puede usarse una vez en cada Punto de Descanso.", body),
        p("Antes de partir, repasa también tus marcadores de Reputación en voz alta: Orden, Secta "
          "y Los Libres. Saber dónde estás evita descubrir demasiado tarde que te faltaba un solo "
          "punto para abrir una puerta.", body),

        p("19. Muerte y «callejones sin salida»", h),
        p("Este es un libro de fantasía oscura: algunas decisiones te matarán, y no todas te "
          "avisan primero. No es un error del libro — es el mundo de Vaelgard, y es parte de su "
          "honestidad. Si tu historia termina, has hecho lo que hace cualquier superviviente de "
          "una tierra rota: aprender de ello, y empezar de nuevo con los ojos un poco más "
          "abiertos.", body),
    ]

    # ── Parte III — Creación de personaje (números y cifras sin tocar) ──
    story += [
        p("PARTE III — CREACIÓN DE PERSONAJE", part),
        p("20. Tu personaje", h),
        p("Eres un Marcado de Valcenar. Elige una vocación: cada una representa una manera "
          "distinta de sobrevivir y de llegar al final de la historia.", body),
        sheet_table([
            [p("CUCHILLA DE CENIZA", label),
             p("FUE 7 · AGI 5 · VOL 3<br/><b>Vida 24 · Ecos 0 · Defensa 10.</b><br/>Espada larga "
               "(Daño 4), cuero reforzado, escudo, ración y venda. <b>Furia de Forjagrís:</b> una "
               "repetición de ataque fallido por combate.", cell)],
            [p("VIGÍA ERRANTE", label),
             p("FUE 5 · AGI 7 · VOL 3<br/><b>Vida 22 · Ecos 0 · Defensa 9.</b><br/>Arco corto "
               "(Daño 3; atacas primero en la primera ronda), daga, cuero reforzado, cuerda, "
               "yesca, ración y venda. <b>Ojo de Vardo:</b> repites una prueba de AGI fallida una "
               "vez por sección.", cell)],
            [p("VIDENTE ROTA", label),
             p("FUE 3 · AGI 4 · VOL 8<br/><b>Vida 22 · Ecos 5 · Defensa 10.</b><br/>Bastón (Daño "
               "3), cuero reforzado, foco protector, grimorio menor, ración, tinta de Grieta y "
               "venda. Conoces <i>Chispa Negra</i> y <i>Susurro de Piel</i>. <b>Eco Profundo:</b> "
               "hasta dos veces por combate, +2 a un ataque mágico por 1 Corrupción.", cell)],
            [p("PENITENTE", label),
             p("FUE 6 · AGI 4 · VOL 6<br/><b>Vida 24 · Ecos 2 · Defensa 10.</b><br/>Maza (Daño 4), "
               "símbolo sagrado, armadura ligera, escudo, ración, vela bendita y venda. <b>Voto de "
               "Ceniza:</b> una vez por Acto, curas 1D6+2 Vida fuera de combate.", cell)],
        ]),

        p("21. Personalización", h),
        p("Tienes 3 puntos para repartir entre FUE, AGI y VOL, con un máximo de +2 en un "
          "atributo. Por cada punto en VOL, aumenta Vida máxima en 1.", body),

        p("22. Hechizos y dones mágicos iniciales", h),
        p("Si tu vocación te da acceso a magia, estos son tus hechizos de partida:", body),
        p("<b>Chispa Negra</b> (Vidente) — Coste: 1 Eco. Ataque mágico: 2D6 + VOL contra Defensa. "
          "Daño 4.", body),
        p("<b>Susurro de Piel</b> (Vidente) — Coste: 1 Eco. Fuera de combate: superas "
          "automáticamente una prueba de VOL Fácil o Media.", body),
        p("<b>Manos de Ceniza</b> (Penitente) — Coste: 1 Eco. Fuera de combate: curas 1D6 Vida a "
          "ti o a un aliado.", body),
    ]

    # ── §23 Hoja de Personaje — ficha completa (Reputación, Equipo en mano, ──
    # ── Mochila y Palabras clave, que faltaban) ──────────────────────────
    story += [
        p("23. Hoja de Personaje", h),
        p("Copia esta ficha antes de empezar a jugar.", body),
        sheet_table([
            [p("NOMBRE", label), p("_______________________________  VOCACIÓN: ________________", cell)],
            [p("FUE · AGI · VOL", label), p("_____ · _____ · _____", cell)],
            [p("VIDA · DEFENSA", label), p("_____ / _____ · _____", cell)],
            [p("ECOS · CORRUPCIÓN", label), p("_____ / _____ · _____ / 10", cell)],
            [p("REPUTACIÓN", label),
             p("Orden de la Ceniza: _____   Secta de los Renacidos: _____   Los Libres: _____", cell)],
            [p("EQUIPO EN MANO", label),
             p("Arma principal: _______________ Daño: ___<br/>"
               "Arma secundaria / escudo: _______________ Bono: ___<br/>"
               "Armadura: _______________ Bono: ___ &nbsp;&nbsp; Amuleto / reliquia: _______________", cell)],
            [p("MOCHILA (6 espacios)", label),
             p("1. _________ 2. _________ 3. _________<br/>4. _________ 5. _________ 6. _________", cell)],
            [p("PALABRAS CLAVE", label), p("_______________________________________________", cell)],
            [p("DON DE VOCACIÓN", label), p("_____________________________  (usos: [ ] [ ] [ ])", cell)],
            [p("HECHIZOS CONOCIDOS", label), p("_______________________________________________", cell)],
        ], col_widths=(1.7 * inch, 5.1 * inch)),
        p("Cuando estés listo, con tu ficha rellenada y tus dados a mano, ve a la <b>sección 1</b> "
          "y comienza <i>La Marca Rota</i>.", body),
    ]

    return story


def rebuild_pdf():
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    tmp = ROOT / "output" / "pdf" / "_rules_block_tmp.pdf"
    doc = BaseDocTemplate(str(tmp), pagesize=letter, leftMargin=.7 * inch, rightMargin=.7 * inch,
                           topMargin=.62 * inch, bottomMargin=.78 * inch)
    doc.addPageTemplates([PageTemplate(
        id="rules", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)],
        onPage=decorated_page,
    )])
    doc.build(build_story())

    source_reader = PdfReader(SOURCE)
    block_reader = PdfReader(tmp)
    writer = PdfWriter()

    # El bloque nuevo no siempre ocupa el mismo número de páginas de una
    # ejecución a otra (cambia con la tipografía o el texto). En vez de
    # fijar dónde termina, se busca la página donde retoma el Bestiario:
    # así una repetición nunca deja huérfano ni duplicado ningún tramo.
    resume_at = None
    for index in range(FIRST_REPLACED_PAGE - 1, len(source_reader.pages)):
        if "BESTIARIO DE VAELGARD" in source_reader.pages[index].extract_text():
            resume_at = index
            break
    if resume_at is None:
        raise RuntimeError("No se encontró 'PARTE IV — BESTIARIO DE VAELGARD' tras la página "
                            f"{FIRST_REPLACED_PAGE}; no se puede saber dónde retomar el original.")

    for page in source_reader.pages[:FIRST_REPLACED_PAGE - 1]:
        writer.add_page(page)
    for page in block_reader.pages:
        writer.add_page(page)
    for page in source_reader.pages[resume_at:]:
        writer.add_page(page)

    writer.add_metadata({
        "/Title": "Ceniza y Corona — Saga ilustrada · Edición corregida",
        "/Author": "Crónicas de Vaelgard",
    })
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    # SOURCE y OUTPUT son el mismo archivo: se escribe a un temporal aparte y
    # se sustituye al final, para no truncar el PDF mientras pypdf todavía
    # pudiera necesitar leer de él.
    staged = OUTPUT.with_suffix(".new.pdf")
    with staged.open("wb") as f:
        writer.write(f)
    staged.replace(OUTPUT)
    tmp.unlink()
    print(f"Bloque nuevo: {len(block_reader.pages)} páginas "
          f"(sustituyen {FIRST_REPLACED_PAGE}-{resume_at}, retoma en {resume_at + 1})")
    print(f"Total del PDF corregido: {len(writer.pages)} páginas")
    print(OUTPUT)


if __name__ == "__main__":
    rebuild_pdf()
