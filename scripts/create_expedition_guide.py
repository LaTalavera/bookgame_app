#!/usr/bin/env python3
"""Genera el suplemento imprimible de viaje y combate de Ceniza y Corona."""

from pathlib import Path

from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageBreak, PageTemplate, Paragraph, Spacer, Table,
    TableStyle,
)

WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
OUT = WORKSPACE_ROOT.parent / "Libro" / "output" / "pdf" / "CenizaYCorona_Guia_de_Expedicion_y_Combate.pdf"

INK = HexColor("#25191a")
WINE = HexColor("#6c1729")
GOLD = HexColor("#a47732")
PARCHMENT = HexColor("#f5eddb")
ASH = HexColor("#675c52")
MOSS = HexColor("#4d6750")


def para(text, style):
    return Paragraph(text, style)


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(GOLD)
    canvas.setLineWidth(0.5)
    canvas.line(0.7 * inch, 0.58 * inch, 7.8 * inch, 0.58 * inch)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(ASH)
    canvas.drawString(0.7 * inch, 0.39 * inch, "CENIZA Y CORONA · GUÍA DE EXPEDICIÓN")
    canvas.drawRightString(7.8 * inch, 0.39 * inch, f"{doc.page}")
    canvas.restoreState()


def build():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc = BaseDocTemplate(
        str(OUT), pagesize=letter,
        leftMargin=0.7 * inch, rightMargin=0.7 * inch,
        topMargin=0.62 * inch, bottomMargin=0.78 * inch,
    )
    doc.addPageTemplates([PageTemplate(
        id="guide", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height)], onPage=footer,
    )])

    styles = getSampleStyleSheet()
    title = ParagraphStyle("title", parent=styles["Title"], fontName="Times-Bold", fontSize=27,
                           leading=30, textColor=WINE, alignment=TA_CENTER, spaceAfter=7)
    kicker = ParagraphStyle("kicker", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=9,
                            leading=12, textColor=GOLD, alignment=TA_CENTER, spaceAfter=11)
    lead = ParagraphStyle("lead", parent=styles["BodyText"], fontName="Times-Italic", fontSize=12,
                          leading=17, textColor=ASH, alignment=TA_CENTER, spaceAfter=18)
    h = ParagraphStyle("h", parent=styles["Heading2"], fontName="Times-Bold", fontSize=16,
                       leading=20, textColor=WINE, spaceBefore=13, spaceAfter=7)
    body = ParagraphStyle("body", parent=styles["BodyText"], fontName="Times-Roman", fontSize=10.5,
                          leading=14.5, textColor=INK, spaceAfter=7)
    small = ParagraphStyle("small", parent=body, fontName="Helvetica", fontSize=8.8, leading=12, textColor=ASH)
    card = ParagraphStyle("card", parent=body, fontName="Times-Roman", fontSize=10, leading=13, textColor=INK)
    cardhead = ParagraphStyle("cardhead", parent=card, fontName="Helvetica-Bold", fontSize=10.2,
                              leading=13, textColor=WINE)

    story = [
        Spacer(1, 0.14 * inch),
        para("SUPLEMENTO DE REGLAS NARRATIVAS", kicker),
        para("Guía de expedición<br/>y combate", title),
        para("Para las personas que caminan entre la ceniza: una ayuda para leer el viaje, comprender el peligro y mantener abiertas todas las historias.", lead),
    ]
    intro = Table([[para("<b>Principio de esta guía.</b> Las decisiones de viaje nunca gastan recursos, nunca cambian una palabra clave y nunca sustituyen una elección de la sección. Preparan el próximo peligro; no deciden la historia por ti.", body)]], colWidths=[7.0 * inch])
    intro.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), PARCHMENT), ("BOX", (0, 0), (-1, -1), 0.8, GOLD),
        ("LEFTPADDING", (0, 0), (-1, -1), 14), ("RIGHTPADDING", (0, 0), (-1, -1), 14),
        ("TOPPADDING", (0, 0), (-1, -1), 12), ("BOTTOMPADDING", (0, 0), (-1, -1), 12),
    ]))
    story += [intro, Spacer(1, 0.17 * inch), para("En el Punto de Descanso", h),
              para("Una hoguera es un lugar para recuperar el aliento, pero también para decidir cómo sigue el grupo. Tras descansar —o en vez de hacerlo— elige uno de estos preparativos. Puedes cambiarlo en el siguiente punto de descanso.", body)]
    cards = [
        [para("VIGILAR LA RUTA", cardhead), para("Distribuyes guardias, señalas una retirada y estudias el terreno. <b>El primer ataque enemigo del próximo combate recibe −2.</b> Si el rival cae antes de atacar, la vigilancia permanece preparada.", card)],
        [para("LEER EL CAMINO", cardhead), para("Repasas huellas, silencios y señales. <b>La próxima prueba con dados recibe +2.</b> Los dones que dan éxito automático no la consumen: el grupo guarda su atención para cuando realmente tenga que elegir.", card)],
    ]
    table = Table(cards, colWidths=[3.45 * inch, 3.45 * inch], hAlign="CENTER")
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), HexColor("#fbf6e9")), ("BOX", (0, 0), (-1, -1), 0.7, GOLD),
        ("INNERGRID", (0, 0), (-1, -1), 0.5, HexColor("#d2bb8a")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 12),
        ("RIGHTPADDING", (0, 0), (-1, -1), 12), ("TOPPADDING", (0, 0), (-1, -1), 11),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 11),
    ]))
    story += [table, Spacer(1, 0.12 * inch), para("En las apps, el preparativo activo aparece en la ficha del personaje. Se borra solo al producirse el efecto, para que la crónica muestre con claridad qué ayudó y cuándo.", small)]
    story += [PageBreak(), para("El combate tiene un propósito", h),
              para("Cada encuentro muestra dos líneas antes de tirar los dados. No son reglas nuevas: traducen a una intención legible las condiciones especiales que ya estaban en el texto.", body)]
    combat_rows = [
        [para("OBJETIVO", cardhead), para("Lo que puedes conseguir esta vez: abrir paso, resistir el primer asalto, encadenar rondas limpias, hacer que el enemigo se retire o evitar la lucha.", card)],
        [para("INTENCIÓN", cardhead), para("La forma en que el rival intenta ganar: desgastarte, proteger su territorio, romper tu vínculo con la Sangre Vieja o impedir que llegues al otro lado.", card)],
    ]
    combat_table = Table(combat_rows, colWidths=[1.35 * inch, 5.55 * inch])
    combat_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (0, -1), HexColor("#eee0bd")), ("BACKGROUND", (1, 0), (1, -1), HexColor("#fbf6e9")),
        ("BOX", (0, 0), (-1, -1), 0.7, GOLD), ("INNERGRID", (0, 0), (-1, -1), 0.5, HexColor("#d2bb8a")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 12),
        ("RIGHTPADDING", (0, 0), (-1, -1), 12), ("TOPPADDING", (0, 0), (-1, -1), 10),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
    ]))
    story += [combat_table, para("Lee ambas líneas antes de escoger arma, hechizo o salida. Un combate no siempre premia hacer más daño; algunas criaturas huyen, otras pueden ser convencidas, y ciertas salidas existen antes del primer golpe.", body),
              para("<b>Ritmo de escena.</b> Tras cada asalto, la crónica conserva los últimos acontecimientos: quién tomó la iniciativa, qué don se usó, qué daño fue absorbido y qué condición está más cerca de cumplirse. Así el azar conserva tensión sin ocultar la información importante.", body)]
    story += [PageBreak(), para("Cuatro vocaciones, cuatro formas de llegar", h),
              para("El equilibrio no significa que todos ataquen igual. Significa que cada vocación empieza con recursos, un modo de actuar y al menos una ruta válida hasta un final; ninguna decisión del grafo exige una vocación concreta.", body)]
    vocations = [
        ["CUCHILLA DE CENIZA", "Resiste el intercambio directo y obtiene una repetición de ataque por combate. Su fuerza hace que las rutas frontales sean consistentes."],
        ["VIGÍA ERRANTE", "22 Vida, cuero reforzado, arco de daño 3 y una venda. Marca el ritmo con AGI, abre salidas de sigilo y convierte el terreno en ventaja."],
        ["VIDENTE ROTA", "22 Vida, 5 Ecos, foco protector, Chispa Negra de daño 4 y una venda. Resuelve pruebas de VOL sin quedar obligada a pelear de frente."],
        ["PENITENTE", "24 Vida, escudo, maza de daño 4 y una venda. Combina defensa, Ecos y Muro de Voto para sostener un combate largo."],
    ]
    voc_table = Table([[para(f"{name}<br/><font color='#675c52'>{copy}</font>", card)] for name, copy in vocations], colWidths=[7.0 * inch])
    voc_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), HexColor("#fbf6e9")), ("BOX", (0, 0), (-1, -1), 0.7, GOLD),
        ("INNERGRID", (0, 0), (-1, -1), 0.45, HexColor("#d2bb8a")), ("LEFTPADDING", (0, 0), (-1, -1), 12),
        ("RIGHTPADDING", (0, 0), (-1, -1), 12), ("TOPPADDING", (0, 0), (-1, -1), 10),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
    ]))
    guarantee = Table([[para("<b>Garantía verificable.</b> La web y la app iOS recorren el grafo narrativo para exigir 24/24 finales, 494/494 decisiones y 4/4 vocaciones con al menos una ruta a un final. Los preparativos se prueban como efectos consumibles: no pueden dejar una sección sin transición válida.", body)]], colWidths=[7.0 * inch])
    guarantee.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), HexColor("#e8f0e3")), ("BOX", (0, 0), (-1, -1), 0.8, MOSS),
        ("LEFTPADDING", (0, 0), (-1, -1), 14), ("RIGHTPADDING", (0, 0), (-1, -1), 14),
        ("TOPPADDING", (0, 0), (-1, -1), 12), ("BOTTOMPADDING", (0, 0), (-1, -1), 12),
    ]))
    story += [voc_table, Spacer(1, 0.18 * inch), guarantee, Spacer(1, 0.15 * inch),
              para("Compatibilidad: este suplemento acompaña a la edición ilustrada; no sustituye ninguna sección ni cambia los finales. Las partidas guardadas anteriores siguen siendo válidas.", small)]
    doc.build(story)
    print(OUT)


if __name__ == "__main__":
    build()
