#!/usr/bin/env python3
"""Inserta las reglas de viaje, combate y equilibrio en el libro principal."""

from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory

from PIL import Image
from pypdf import PdfReader, PdfWriter
from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas
from reportlab.platypus import BaseDocTemplate, Frame, PageBreak, PageTemplate, Paragraph, Spacer, Table, TableStyle

WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
ROOT = WORKSPACE_ROOT.parent / "Libro"
SOURCE = ROOT / "CenizaYCorona_SAGA_ILUSTRADA.pdf"
OUTPUT = ROOT / "output" / "pdf" / "CenizaYCorona_SAGA_ILUSTRADA_EDICION_EQUILIBRADA.pdf"
ORNAMENTED_BACKGROUND = ROOT / "output" / "imagegen" / "ceniza-corona-parchment-template.png"
ORNAMENTAL_FRAME = ROOT / "output" / "imagegen" / "ceniza-corona-ornamental-frame.png"
PARCHMENT_FILL = ROOT / "output" / "imagegen" / "ceniza-corona-parchment-fill.png"
INSERT_AFTER_PAGE = 15  # Parte II termina aquí; la Parte III comienza en la página física 16.

INK, WINE, GOLD, ASH, PARCHMENT, MOSS = (HexColor(c) for c in ("#25191a", "#6c1729", "#a47732", "#675c52", "#f5eddb", "#4d6750"))


def p(text, style):
    return Paragraph(text, style)


def decorated_page(canvas, _doc):
    """Aplica el mismo pergamino y marco de las páginas narrativas del libro."""
    canvas.saveState()
    canvas.drawImage(str(PARCHMENT_FILL), 0, 0, width=letter[0], height=letter[1], mask="auto")
    canvas.restoreState()


def decorated_frame(canvas, _doc):
    """Redibuja el marco al final para que ninguna plantilla lo oculte."""
    canvas.saveState()
    canvas.drawImage(str(ORNAMENTAL_FRAME), 0, 0, width=letter[0], height=letter[1], mask="auto")
    canvas.restoreState()


def frame_overlay(path):
    """Crea un marco transparente para superponerlo al final del ensamblado."""
    pdf = canvas.Canvas(str(path), pagesize=letter)
    pdf.drawImage(str(ORNAMENTAL_FRAME), 0, 0, width=letter[0], height=letter[1], mask="auto")
    pdf.save()


def rasterize_with_frame(source, destination, temp, name):
    """Aplana las páginas nuevas con su marco, evitando conflictos de capas PDF."""
    prefix = temp / name
    subprocess.run(["pdftoppm", "-png", "-r", "200", str(source), str(prefix)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    pages = sorted(temp.glob(f"{name}-*.png"))
    frame = Image.open(ORNAMENTAL_FRAME).convert("RGBA")
    writer = PdfWriter()
    for index, page in enumerate(pages, start=1):
        image = Image.open(page).convert("RGBA")
        overlay = frame.resize(image.size, Image.Resampling.LANCZOS)
        image.alpha_composite(overlay)
        composed = temp / f"{page.stem}-framed.png"
        image.convert("RGB").save(composed, "PNG")
        single = temp / f"{name}-framed-{index}.pdf"
        pdf = canvas.Canvas(str(single), pagesize=letter)
        pdf.drawImage(str(composed), 0, 0, width=letter[0], height=letter[1])
        pdf.save()
        writer.add_page(PdfReader(single).pages[0])
    with destination.open("wb") as output:
        writer.write(output)


def rule_pages(path):
    if not ORNAMENTED_BACKGROUND.exists() or not ORNAMENTAL_FRAME.exists() or not PARCHMENT_FILL.exists():
        raise FileNotFoundError("Falta la plantilla ornamental de páginas")
    doc = BaseDocTemplate(str(path), pagesize=letter, leftMargin=.7*inch, rightMargin=.7*inch, topMargin=.62*inch, bottomMargin=.78*inch)
    doc.addPageTemplates([PageTemplate(id="rules", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)], onPage=decorated_page)])
    base = getSampleStyleSheet()
    title = ParagraphStyle("title", parent=base["Title"], fontName="Times-Bold", fontSize=25, leading=29, textColor=WINE, spaceAfter=8)
    h = ParagraphStyle("h", parent=base["Heading2"], fontName="Times-Bold", fontSize=16, leading=20, textColor=WINE, spaceBefore=11, spaceAfter=7)
    body = ParagraphStyle("body", parent=base["BodyText"], fontName="Times-Roman", fontSize=10.7, leading=14.5, textColor=INK, spaceAfter=8)
    card = ParagraphStyle("card", parent=body, fontSize=10, leading=13)
    label = ParagraphStyle("label", parent=card, fontName="Helvetica-Bold", fontSize=10.2, leading=13, textColor=WINE)
    note = ParagraphStyle("note", parent=body, fontName="Helvetica", fontSize=9, leading=12, textColor=ASH)

    intro = Table([[p("<b>Estas reglas forman parte de la Parte II.</b> Aclaran el viaje y el combate sin alterar ninguna sección, palabra clave, reputación ni condición de final. Un preparativo acompaña al grupo hasta que realmente interviene.", body)]], colWidths=[7*inch])
    intro.setStyle(TableStyle([("BACKGROUND", (0,0), (-1,-1), PARCHMENT), ("BOX", (0,0), (-1,-1), .8, GOLD), ("LEFTPADDING", (0,0), (-1,-1), 14), ("RIGHTPADDING", (0,0), (-1,-1), 14), ("TOPPADDING", (0,0), (-1,-1), 11), ("BOTTOMPADDING", (0,0), (-1,-1), 11)]))
    travel = Table([
        [p("VIGILAR LA RUTA", label), p("En un Punto de Descanso puedes distribuir guardias, señalar una retirada y estudiar el terreno. <b>El primer ataque enemigo del próximo combate recibe −2.</b> Si el rival cae antes de atacar, la vigilancia permanece preparada.", card)],
        [p("LEER EL CAMINO", label), p("En un Punto de Descanso puedes repasar huellas, silencios y señales. <b>La próxima prueba con dados recibe +2.</b> Los dones de éxito automático no la consumen.", card)],
    ], colWidths=[1.75*inch, 5.25*inch])
    travel.setStyle(TableStyle([("BACKGROUND", (0,0), (0,-1), HexColor("#eee0bd")), ("BACKGROUND", (1,0), (1,-1), HexColor("#fbf6e9")), ("BOX", (0,0), (-1,-1), .7, GOLD), ("INNERGRID", (0,0), (-1,-1), .45, HexColor("#d2bb8a")), ("VALIGN", (0,0), (-1,-1), "TOP"), ("LEFTPADDING", (0,0), (-1,-1), 12), ("RIGHTPADDING", (0,0), (-1,-1), 12), ("TOPPADDING", (0,0), (-1,-1), 10), ("BOTTOMPADDING", (0,0), (-1,-1), 10)]))
    story = [p("18 bis. Decisiones de expedición", title), intro, Spacer(1, .16*inch), p("Cuando la ruta deja al grupo un respiro, no solo puedes recuperar Vida y Ecos: puedes decidir cómo afrontar el siguiente peligro. Elige un solo preparativo; es gratuito y puede sustituirse en el siguiente descanso.", body), travel, Spacer(1, .1*inch), p("No se pierde una opción al hacer este preparativo. El viaje sigue obedeciendo a las elecciones de cada sección; la decisión solo concede información, posición o tiempo.", note), PageBreak()]

    tactics = Table([
        [p("OBJETIVO", label), p("Lo que puedes conseguir esta vez: abrir paso, resistir el primer asalto, encadenar rondas limpias, hacer que el enemigo se retire o evitar la lucha.", card)],
        [p("INTENCIÓN", label), p("La forma en que el rival intenta imponerse: desgastarte, proteger su territorio, romper tu vínculo con la Sangre Vieja o impedir que llegues al otro lado.", card)],
    ], colWidths=[1.45*inch, 5.55*inch])
    tactics.setStyle(TableStyle([("BACKGROUND", (0,0), (0,-1), HexColor("#eee0bd")), ("BACKGROUND", (1,0), (1,-1), HexColor("#fbf6e9")), ("BOX", (0,0), (-1,-1), .7, GOLD), ("INNERGRID", (0,0), (-1,-1), .45, HexColor("#d2bb8a")), ("VALIGN", (0,0), (-1,-1), "TOP"), ("LEFTPADDING", (0,0), (-1,-1), 12), ("RIGHTPADDING", (0,0), (-1,-1), 12), ("TOPPADDING", (0,0), (-1,-1), 10), ("BOTTOMPADDING", (0,0), (-1,-1), 10)]))
    story += [p("19 ter. El propósito del combate", title), p("Antes de tirar los dados, lee el objetivo del encuentro y la intención de tu adversario. Estas dos líneas no reemplazan las reglas especiales: las convierten en una táctica visible.", body), tactics, p("Un combate no siempre premia hacer más daño. Algunas criaturas huyen, otras se rinden si no consiguen tocarte y ciertas salidas existen antes del primer golpe. Tras cada asalto, la crónica recuerda la iniciativa, los dones y la condición que está más cerca de cumplirse.", body), PageBreak()]

    balance = Table([
        [p("CUCHILLA DE CENIZA", label), p("24 Vida, Defensa 10, espada larga de daño 4 y Furia de Forjagrís: la referencia para el intercambio directo.", card)],
        [p("VIGÍA ERRANTE", label), p("22 Vida, cuero reforzado, arco corto de daño 3 y una venda. Conserva sus salidas de sigilo y su iniciativa inicial.", card)],
        [p("VIDENTE ROTA", label), p("22 Vida, 5 Ecos, foco protector, Chispa Negra de daño 4 y una venda. Puede asumir retos de VOL sin pagar con una fragilidad excesiva.", card)],
        [p("PENITENTE", label), p("24 Vida, escudo, maza de daño 4 y una venda. Muro de Voto y sus Ecos sostienen el margen de error del grupo.", card)],
    ], colWidths=[1.75*inch, 5.25*inch])
    balance.setStyle(TableStyle([("BACKGROUND", (0,0), (0,-1), HexColor("#eee0bd")), ("BACKGROUND", (1,0), (1,-1), HexColor("#fbf6e9")), ("BOX", (0,0), (-1,-1), .7, GOLD), ("INNERGRID", (0,0), (-1,-1), .45, HexColor("#d2bb8a")), ("VALIGN", (0,0), (-1,-1), "TOP"), ("LEFTPADDING", (0,0), (-1,-1), 12), ("RIGHTPADDING", (0,0), (-1,-1), 12), ("TOPPADDING", (0,0), (-1,-1), 9), ("BOTTOMPADDING", (0,0), (-1,-1), 9)]))
    guarantee = Table([[p("<b>Garantía de la edición.</b> Las dos aplicaciones verifican 24/24 finales, 494/494 decisiones y 4/4 vocaciones con una ruta a un final. Los preparativos son consumibles y no pueden dejar una sección sin transición válida.", body)]], colWidths=[7*inch])
    guarantee.setStyle(TableStyle([("BACKGROUND", (0,0), (-1,-1), HexColor("#e8f0e3")), ("BOX", (0,0), (-1,-1), .8, MOSS), ("LEFTPADDING", (0,0), (-1,-1), 14), ("RIGHTPADDING", (0,0), (-1,-1), 14), ("TOPPADDING", (0,0), (-1,-1), 11), ("BOTTOMPADDING", (0,0), (-1,-1), 11)]))
    story += [p("19 quater. Equilibrio de las vocaciones", title), p("Cada vocación conserva una manera distinta de vencer. El equilibrio asegura que ninguna empiece sin defensa, recursos o daño suficientes para completar la historia.", body), balance, Spacer(1, .15*inch), guarantee]
    doc.build(story)


def revised_creation_pages(path):
    """Sustituye las tres páginas de creación y la entrada de Grimorio afectadas."""
    doc = BaseDocTemplate(str(path), pagesize=letter, leftMargin=.9*inch, rightMargin=.9*inch, topMargin=.62*inch, bottomMargin=.78*inch)
    doc.addPageTemplates([PageTemplate(id="creation", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)], onPage=decorated_page)])
    base = getSampleStyleSheet()
    title = ParagraphStyle("ctitle", parent=base["Title"], fontName="Times-Bold", fontSize=22, leading=26, textColor=WINE, spaceAfter=10)
    h = ParagraphStyle("ch", parent=base["Heading2"], fontName="Times-Bold", fontSize=14, leading=18, textColor=WINE, spaceBefore=8, spaceAfter=4)
    body = ParagraphStyle("cbody", parent=base["BodyText"], fontName="Times-Roman", fontSize=10.5, leading=13.5, textColor=INK, spaceAfter=5)
    label = ParagraphStyle("clabel", parent=body, fontName="Helvetica-Bold", fontSize=10.5, leading=13, textColor=WINE)
    def sheet(name, copy):
        return Table([[p(name, label), p(copy, body)]], colWidths=[1.7*inch, 4.6*inch], style=[("BACKGROUND", (0,0), (0,0), HexColor("#eee0bd")), ("BACKGROUND", (1,0), (1,0), HexColor("#fbf6e9")), ("BOX", (0,0), (-1,-1), .7, GOLD), ("VALIGN", (0,0), (-1,-1), "TOP"), ("LEFTPADDING", (0,0), (-1,-1), 10), ("RIGHTPADDING", (0,0), (-1,-1), 10), ("TOPPADDING", (0,0), (-1,-1), 9), ("BOTTOMPADDING", (0,0), (-1,-1), 9)])
    story = [p("PARTE III — CREACIÓN DE PERSONAJE", title), p("20. Tu personaje", h), p("Eres un Marcado de Valcenar. Elige una vocación: cada una representa una manera distinta de sobrevivir y de llegar al final de la historia.", body),
             sheet("CUCHILLA DE CENIZA", "FUE 7 · AGI 5 · VOL 3<br/><b>Vida 24 · Ecos 0 · Defensa 10.</b><br/>Espada larga (Daño 4), cuero reforzado, escudo, ración y venda. <b>Furia de Forjagrís:</b> una repetición de ataque fallido por combate."),
             sheet("VIGÍA ERRANTE", "FUE 5 · AGI 7 · VOL 3<br/><b>Vida 22 · Ecos 0 · Defensa 9.</b><br/>Arco corto (Daño 3; atacas primero en la primera ronda), daga, cuero reforzado, cuerda, yesca, ración y venda. <b>Ojo de Vardo:</b> repites una prueba de AGI fallida una vez por sección."), PageBreak(),
             p("PARTE III — CREACIÓN DE PERSONAJE", title),
             sheet("VIDENTE ROTA", "FUE 3 · AGI 4 · VOL 8<br/><b>Vida 22 · Ecos 5 · Defensa 10.</b><br/>Bastón (Daño 3), cuero reforzado, foco protector, grimorio menor, ración, tinta de Grieta y venda. Conoces <i>Chispa Negra</i> y <i>Susurro de Piel</i>. <b>Eco Profundo:</b> hasta dos veces por combate, +2 a un ataque mágico por 1 Corrupción."),
             sheet("PENITENTE", "FUE 6 · AGI 4 · VOL 6<br/><b>Vida 24 · Ecos 2 · Defensa 10.</b><br/>Maza (Daño 4), símbolo sagrado, armadura ligera, escudo, ración, vela bendita y venda. <b>Voto de Ceniza:</b> una vez por Acto, curas 1D6+2 Vida fuera de combate."),
             p("21. Personalización", h), p("Tienes 3 puntos para repartir entre FUE, AGI y VOL, con un máximo de +2 en un atributo. Por cada punto en VOL, aumenta Vida máxima en 1.", body), PageBreak(),
             p("22. Hechizos y dones mágicos iniciales", title),
             p("Si tu vocación te da acceso a magia, estos son tus hechizos de partida:", body),
             p("<b>Chispa Negra (Vidente)</b> — Coste: 1 Eco. Ataque mágico: 2D6 + VOL contra Defensa. <b>Daño 4.</b>", body),
             p("<b>Susurro de Piel (Vidente)</b> — Coste: 1 Eco. Fuera de combate: superas automáticamente una prueba de VOL Fácil o Media.", body),
             p("<b>Manos de Ceniza (Penitente)</b> — Coste: 1 Eco. Fuera de combate: curas 1D6 Vida a ti o a un aliado.", body),
             p("23. Hoja de Personaje", h), p("Copia esta ficha antes de empezar a jugar. Anota Vida, Defensa, Ecos, Corrupción, equipo y palabras clave; usa seis espacios para la mochila.", body),
             Table([[p("NOMBRE", label), p("_______________________________", body)], [p("VOCACIÓN", label), p("_______________________________", body)], [p("FUE · AGI · VOL", label), p("_____ · _____ · _____", body)], [p("VIDA · DEFENSA · ECOS", label), p("_____ / _____ · _____ · _____ / _____", body)], [p("CORRUPCIÓN", label), p("_____ / 10", body)]], colWidths=[2.2*inch, 4.1*inch], style=[("BACKGROUND", (0,0), (0,-1), HexColor("#eee0bd")), ("BACKGROUND", (1,0), (1,-1), HexColor("#fbf6e9")), ("BOX", (0,0), (-1,-1), .7, GOLD), ("INNERGRID", (0,0), (-1,-1), .4, HexColor("#d2bb8a")), ("LEFTPADDING", (0,0), (-1,-1), 10), ("RIGHTPADDING", (0,0), (-1,-1), 10), ("TOPPADDING", (0,0), (-1,-1), 8), ("BOTTOMPADDING", (0,0), (-1,-1), 8)]), PageBreak(),
             p("PARTE V — EL GRIMORIO DE LA SANGRE VIEJA", title), p("24. Hechizos de la Vidente Rota", h), p("Requieren bastón o grimorio en mano; el coste se paga en Ecos.", body),
             p("<b>Chispa Negra</b> — Coste 1 Eco. Ataque mágico en combate: 2D6 + VOL contra Defensa. <b>Daño 4.</b>", body), p("<b>Susurro de Piel</b> — Coste 1 Eco. Fuera de combate: superas automáticamente una prueba de VOL Fácil o Media.", body), p("<b>Grieta Menor</b> — Coste 2 Ecos. Ataque mágico: Daño 4; si acierta, el objetivo recibe −1 a su siguiente tirada de ataque.", body), p("<b>Ojo Ceniciento</b> — Coste 1 Eco. Busca resonancia de Sangre Vieja en una escena, objeto o persona.", body), p("<b>Velo Roto</b> — Coste 2 Ecos. +3 a una prueba de sigilo (AGI) inmediatamente posterior.", body), p("<b>Cadena de Eco</b> — Coste 3 Ecos. Ataque contra dos objetivos: Daño 3 a cada uno alcanzado.", body), p("25. Hechizos del Penitente", h), p("<b>Manos de Ceniza</b> — Coste 1 Eco. Curas 1D6 Vida. <b>Muro de Voto</b> — Coste 1 Eco. Reduce en 2 el daño recibido esa ronda. <b>Luz de Cadena Rota</b> — Coste 2 Ecos. Daño 5 contra Quebrados; Daño 2 contra el resto.", body), PageBreak(),
             p("PARTE II — CÓMO JUGAR", title), p("14. Objetos y equipo", h),
             p("El equipo inicial ya está incluido en cada vocación. Las armas usan su Daño al impactar; armaduras, escudos y focos suman Defensa.", body),
             Table([[p("ARMA", label), p("DAÑO", label), p("NOTA", label)],
                    [p("Daga", body), p("2", body), p("Ligera y discreta.", body)],
                    [p("Espada corta", body), p("3", body), p("Equilibrada.", body)],
                    [p("Espada larga / hacha", body), p("4", body), p("Arma de la Cuchilla.", body)],
                    [p("Maza", body), p("4", body), p("Arma del Penitente.", body)],
                    [p("Arco corto", body), p("3", body), p("El Vigía ataca primero en la primera ronda.", body)],
                    [p("Bastón", body), p("3", body), p("También permite canalizar hechizos.", body)]], colWidths=[2.0*inch, .8*inch, 3.5*inch], style=[("BACKGROUND", (0,0), (-1,0), HexColor("#eee0bd")), ("BACKGROUND", (0,1), (-1,-1), HexColor("#fbf6e9")), ("BOX", (0,0), (-1,-1), .7, GOLD), ("INNERGRID", (0,0), (-1,-1), .4, HexColor("#d2bb8a")), ("VALIGN", (0,0), (-1,-1), "TOP"), ("LEFTPADDING", (0,0), (-1,-1), 9), ("RIGHTPADDING", (0,0), (-1,-1), 9), ("TOPPADDING", (0,0), (-1,-1), 7), ("BOTTOMPADDING", (0,0), (-1,-1), 7)]),
             p("<b>Cuero reforzado:</b> +1 Defensa. <b>Armadura ligera:</b> +2 Defensa. <b>Escudo o foco protector:</b> +1 Defensa. Si recibes equipo nuevo, aplica sus modificadores y conserva el que la sección indique.", body),
             p("En combate, compara 2D6 + atributo o bonificador contra la Defensa del enemigo. Consulta siempre la sección del encuentro: sus reglas especiales pueden permitir escapar, rendir al rival o resolver el combate sin agotarlo.", body)]
    doc.build(story)


def integrate():
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory() as temp:
        insert = Path(temp) / "reglas-integradas.pdf"
        revised = Path(temp) / "creacion-revisada.pdf"
        framed_insert = Path(temp) / "reglas-integradas-con-marco.pdf"
        framed_revised = Path(temp) / "creacion-revisada-con-marco.pdf"
        rule_pages(insert)
        revised_creation_pages(revised)
        rasterize_with_frame(insert, framed_insert, Path(temp), "reglas")
        rasterize_with_frame(revised, framed_revised, Path(temp), "creacion")
        source_reader, insert_reader, revised_reader, writer = PdfReader(SOURCE), PdfReader(framed_insert), PdfReader(framed_revised), PdfWriter()
        for index, page in enumerate(source_reader.pages[:INSERT_AFTER_PAGE]):
            # La página de equipo es la única regla general previa a la inserción
            # que cambia daños iniciales; se sustituye para evitar contradicciones.
            writer.add_page(revised_reader.pages[4] if index == 11 else page)
        for page in insert_reader.pages: writer.add_page(page)
        for page in revised_reader.pages[:3]: writer.add_page(page)
        for index, page in enumerate(source_reader.pages[18:], start=18):
            if index == 25:
                writer.add_page(revised_reader.pages[3])
            else:
                writer.add_page(page)
        writer.add_metadata({"/Title": "Ceniza y Corona — Saga ilustrada · Edición equilibrada", "/Author": "Crónicas de Vaelgard"})
        with OUTPUT.open("wb") as out: writer.write(out)
    print(OUTPUT)


if __name__ == "__main__":
    integrate()
