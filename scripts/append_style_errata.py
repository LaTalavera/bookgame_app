"""Anade al final del libro impreso la fe de erratas de estilo.

El cuerpo del PDF ilustrado no se genera desde saga.json y solo admite
anadidos. La revision de estilo toco 49 secciones, pero casi siempre con un
cambio de una o dos palabras: reimprimir las secciones enteras (como hace
append_expansion_booklet.py con las que ganan una decision nueva) daria
decenas de paginas para corregir frases sueltas. Por eso estas correcciones
se publican en el formato clasico de fe de erratas: "donde dice X, lee Y".

Las entradas viven en scripts/errata_estilo.json, generado comparando la
version anterior de saga.json con la actual, de modo que el papel no puede
divergir de lo que leen la web y la app movil.

IMPORTANTE: este cuadernillo va despues del apendice de secciones revisadas,
y aquel se regenera truncando todo lo que tenga detras. Ejecuta siempre los
dos en orden a traves de ./scripts/build_rules_pdf.sh.

Uso:  ./scripts/build_rules_pdf.sh
      python scripts/append_style_errata.py
"""
import json
import re
import sys
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.platypus import BaseDocTemplate, Frame, PageTemplate, Paragraph, Spacer

from fix_rules_section import (  # noqa: E402
    ASH, HEAD_GRAY, PART_WINE, TEXT_BLACK, decorated_page,
)

WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
ROOT = WORKSPACE_ROOT.parent / "Libro"
LIBRO = ROOT / "CenizaYCorona_SAGA_ILUSTRADA_EDICION_EQUILIBRADA.pdf"
ERRATAS = Path(__file__).resolve().parent / "errata_estilo.json"
TEMPORAL = ROOT / "output" / "pdf" / "_erratas_tmp.pdf"

MARCA = "FE DE ERRATAS"
TITULO = "AP\u00c9NDICE \u2014 FE DE ERRATAS"

INTRO = (
    "Esta revisi\u00f3n corrige el modo en que el libro se dirige a quien lo lee. La aventura "
    "se cuenta en segunda persona, pero varias frases fijaban el g\u00e9nero de tu personaje "
    "\u2014unas en masculino, otras en femenino, y algunas secciones se contradec\u00edan entre "
    "s\u00ed\u2014. Ahora la narraci\u00f3n no decide qui\u00e9n eres: eso te corresponde a ti. "
    "Se han retirado adem\u00e1s los comentarios en los que la voz del autor se dirig\u00eda al "
    "jugador por encima de la historia, y las menciones a otras partidas o a otros libros "
    "que romp\u00edan la ficci\u00f3n."
)

AVISO = (
    "Ninguna de estas correcciones cambia una sola regla, tirada, palabra clave ni destino: "
    "el juego se comporta exactamente igual. Donde el texto impreso diga lo primero, lee lo "
    "segundo."
)


def estilos():
    base = getSampleStyleSheet()
    return {
        "parte": ParagraphStyle("parte", parent=base["Title"], fontName="Caladea-Bold",
                                fontSize=18, leading=23, textColor=PART_WINE,
                                spaceBefore=0, spaceAfter=16),
        "titulo": ParagraphStyle("titulo", parent=base["Heading2"], fontName="Caladea-Bold",
                                 fontSize=12.5, leading=16, textColor=HEAD_GRAY,
                                 spaceBefore=12, spaceAfter=5),
        "cuerpo": ParagraphStyle("cuerpo", parent=base["BodyText"], fontName="DejaVuSerif",
                                 fontSize=12, leading=16.5, textColor=TEXT_BLACK,
                                 spaceAfter=9, alignment=4),
        "nota": ParagraphStyle("nota", parent=base["BodyText"], fontName="DejaVuSerif-Italic",
                               fontSize=10.5, leading=14.5, textColor=ASH,
                               spaceAfter=9, alignment=4),
        "antes": ParagraphStyle("antes", parent=base["BodyText"], fontName="DejaVuSerif-Italic",
                                fontSize=11, leading=15, textColor=ASH,
                                leftIndent=16, spaceAfter=3),
        "ahora": ParagraphStyle("ahora", parent=base["BodyText"], fontName="DejaVuSerif",
                                fontSize=11, leading=15, textColor=TEXT_BLACK,
                                leftIndent=16, spaceAfter=8),
    }


def a_html(texto):
    """La prosa usa el mismo marcado ligero que leen la web y la app."""
    t = (texto.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
    t = re.sub(r"\*(.+?)\*", r"<i>\1</i>", t)
    t = re.sub(r"`(.+?)`", r"<b>\1</b>", t)
    return t


def construir(erratas, st):
    piezas = [Paragraph(TITULO, st["parte"]),
              Paragraph(INTRO, st["cuerpo"]),
              Paragraph(AVISO, st["nota"]),
              Spacer(1, 10)]
    for entrada in sorted(erratas, key=lambda e: e["id"]):
        piezas.append(Paragraph("Secci\u00f3n %d" % entrada["id"], st["titulo"]))
        if entrada["antes"]:
            piezas.append(Paragraph("Donde dice: \u00ab%s\u00bb" % a_html(entrada["antes"]), st["antes"]))
        else:
            piezas.append(Paragraph("A\u00f1ade este texto:", st["antes"]))
        if entrada["despues"]:
            piezas.append(Paragraph("Lee: \u00ab%s\u00bb" % a_html(entrada["despues"]), st["ahora"]))
        else:
            piezas.append(Paragraph("Suprime esa frase.", st["ahora"]))
    return piezas


def generar_cuadernillo(erratas):
    TEMPORAL.parent.mkdir(parents=True, exist_ok=True)
    doc = BaseDocTemplate(str(TEMPORAL), pagesize=letter,
                          leftMargin=86, rightMargin=86, topMargin=96, bottomMargin=92)
    marco = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="cuerpo")
    doc.addPageTemplates([PageTemplate(id="pergamino", frames=[marco], onPage=decorated_page)])
    doc.build(construir(erratas, estilos()))
    return PdfReader(str(TEMPORAL))


def primera_pagina_del_apendice(libro):
    """Permite repetir la ejecucion sin acumular cuadernillos."""
    for i, pagina in enumerate(libro.pages):
        try:
            texto = pagina.extract_text() or ""
        except Exception:
            continue
        if MARCA in texto.upper():
            return i
    return None


def main():
    erratas = json.loads(ERRATAS.read_text(encoding="utf-8"))
    if not erratas:
        print("no hay erratas que publicar")
        return 0

    libro = PdfReader(str(LIBRO))
    corte = primera_pagina_del_apendice(libro)
    conservadas = corte if corte is not None else len(libro.pages)

    cuadernillo = generar_cuadernillo(erratas)
    escritor = PdfWriter()
    for pagina in libro.pages[:conservadas]:
        escritor.add_page(pagina)
    for pagina in cuadernillo.pages:
        escritor.add_page(pagina)
    with open(LIBRO, "wb") as f:
        escritor.write(f)
    TEMPORAL.unlink(missing_ok=True)

    secciones = len({e["id"] for e in erratas})
    print("libro sin la fe de erratas: %d paginas" % conservadas)
    print("fe de erratas: %d paginas (%d correcciones en %d secciones)"
          % (len(cuadernillo.pages), len(erratas), secciones))
    print("total: %d paginas -> %s" % (conservadas + len(cuadernillo.pages), LIBRO.name))
    return 0


if __name__ == "__main__":
    sys.exit(main())
