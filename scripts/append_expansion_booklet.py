"""Anade al final del libro impreso el cuadernillo de secciones revisadas.

El cuerpo del PDF ilustrado no se genera desde saga.json: son 261 paginas de
prosa maquetada e ilustrada que solo admiten anadidos, nunca ediciones. Por
eso las secciones que ganan una decision nueva no pueden reescribirse en su
sitio; se reimprimen enteras al final, y una nota al principio del cuadernillo
avisa de que estas versiones sustituyen a las del cuerpo.

El texto se toma siempre de saga.json, la misma fuente que leen la web y la
app movil, de modo que los tres soportes no pueden decir cosas distintas.

Uso:  ./scripts/build_rules_pdf.sh  (resuelve el venv; python3 del sistema
      no trae reportlab ni pypdf)
      python scripts/append_expansion_booklet.py
"""
import json
import re
import sys
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.platypus import BaseDocTemplate, Frame, PageBreak, PageTemplate, Paragraph, Spacer

# Reutiliza el registro de fuentes, los colores y el marco ornamental del
# bloque de reglas: importar el modulo ya deja las fuentes registradas.
from fix_rules_section import (  # noqa: E402
    ASH, HEAD_GRAY, PART_WINE, TEXT_BLACK, decorated_page,
)

ROOT = Path(__file__).resolve().parents[2]
LIBRO = ROOT / "CenizaYCorona_SAGA_ILUSTRADA_EDICION_EQUILIBRADA.pdf"
SAGA = ROOT / "ceniza-y-corona-app" / "public" / "data" / "saga.json"
TEMPORAL = ROOT / "output" / "pdf" / "_cuadernillo_tmp.pdf"

MARCA = "SECCIONES REVISADAS"
TITULO = "AP\u00c9NDICE \u2014 SECCIONES REVISADAS"

# Secciones que el cuadernillo reimprime. Las que ya existian en el libro
# cambian de contenido; las nuevas no estaban impresas en ningun sitio.
REVISADAS = [3, 4, 16, 33, 42, 50, 53, 89, 96, 102, 114, 115, 133,
             1001, 1025, 1030, 1054, 1055, 1057, 1065, 1066, 1079, 1080, 1081,
             1110, 1133, 1136, 1145, 2001, 2014, 2150]
NUEVAS = [447, 448, 449, 450, 451, 452, 453, 1500, 1501, 1502, 1503, 1504, 1505, 2907]

INTRO = (
    "Las secciones que siguen sustituyen a las del cuerpo del libro con el mismo n\u00famero. "
    "En la edici\u00f3n anterior, varios momentos del Libro Segundo planteaban una decisi\u00f3n "
    "\u2014la condici\u00f3n de Sera, el silencio sobre El Refugio, el encargo de Casa Vaas, la "
    "\u00faltima noche antes del palacio, la llegada al monasterio\u2014 y la resolv\u00edan por ti "
    "en la secci\u00f3n siguiente. Aqu\u00ed vuelven a ser tuyas."
)

AVISO = (
    "Cuando una secci\u00f3n de este ap\u00e9ndice repita un n\u00famero que ya existe en el libro, "
    "usa siempre la versi\u00f3n de aqu\u00ed. Las secciones 1500 a 1505 son nuevas y solo "
    "aparecen en este ap\u00e9ndice."
)


def estilos():
    base = getSampleStyleSheet()
    return {
        "parte": ParagraphStyle("parte", parent=base["Title"], fontName="Caladea-Bold",
                                fontSize=18, leading=23, textColor=PART_WINE,
                                spaceBefore=0, spaceAfter=16),
        "titulo": ParagraphStyle("titulo", parent=base["Heading2"], fontName="Caladea-Bold",
                                 fontSize=13.5, leading=18, textColor=HEAD_GRAY,
                                 spaceBefore=14, spaceAfter=7),
        "cuerpo": ParagraphStyle("cuerpo", parent=base["BodyText"], fontName="DejaVuSerif",
                                 fontSize=12, leading=16.5, textColor=TEXT_BLACK,
                                 spaceAfter=9, alignment=4),
        "nota": ParagraphStyle("nota", parent=base["BodyText"], fontName="DejaVuSerif-Italic",
                               fontSize=10.5, leading=14.5, textColor=ASH,
                               spaceAfter=9, alignment=4),
        "opcion": ParagraphStyle("opcion", parent=base["BodyText"], fontName="DejaVuSerif",
                                 fontSize=11.5, leading=15.5, textColor=TEXT_BLACK,
                                 leftIndent=16, spaceAfter=5),
    }


def a_html(texto):
    """La prosa usa el mismo marcado ligero que leen la web y la app."""
    t = (texto.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
    t = re.sub(r"\*(.+?)\*", r"<i>\1</i>", t)
    t = re.sub(r"`(.+?)`", r"<b>\1</b>", t)
    return t


def construir(saga, st):
    piezas = [Paragraph(TITULO, st["parte"]),
              Paragraph(INTRO, st["cuerpo"]),
              Paragraph(AVISO, st["nota"]),
              Spacer(1, 10)]

    for sid in REVISADAS + NUEVAS:
        s = saga[str(sid)]
        nueva = sid in NUEVAS
        etiqueta = "secci\u00f3n nueva" if nueva else "sustituye a la del cuerpo del libro"
        piezas.append(Paragraph("%d. %s" % (sid, s["title"]), st["titulo"]))
        piezas.append(Paragraph("(%s)" % etiqueta, st["nota"]))
        for parrafo in [x for x in s["text"].split("\n\n") if x.strip()]:
            piezas.append(Paragraph(a_html(parrafo.strip()), st["cuerpo"]))
        opciones = [c for c in (s.get("choices") or []) if c.get("text")]
        if opciones:
            piezas.append(Paragraph("Elige una:", st["cuerpo"]))
            for c in opciones:
                piezas.append(Paragraph("\u2014 %s \u2192 ve a la secci\u00f3n <b>%d</b>."
                                        % (a_html(c["text"]), c["target"]), st["opcion"]))
    return piezas


def generar_cuadernillo(saga):
    TEMPORAL.parent.mkdir(parents=True, exist_ok=True)
    doc = BaseDocTemplate(str(TEMPORAL), pagesize=letter,
                          leftMargin=86, rightMargin=86, topMargin=96, bottomMargin=92)
    marco = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="cuerpo")
    doc.addPageTemplates([PageTemplate(id="pergamino", frames=[marco], onPage=decorated_page)])
    doc.build(construir(saga, estilos()))
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
    saga = json.loads(SAGA.read_text(encoding="utf-8"))
    for sid in REVISADAS + NUEVAS:
        if str(sid) not in saga:
            raise SystemExit("la seccion %d no existe en saga.json" % sid)

    libro = PdfReader(str(LIBRO))
    corte = primera_pagina_del_apendice(libro)
    conservadas = corte if corte is not None else len(libro.pages)

    cuadernillo = generar_cuadernillo(saga)
    escritor = PdfWriter()
    for pagina in libro.pages[:conservadas]:
        escritor.add_page(pagina)
    for pagina in cuadernillo.pages:
        escritor.add_page(pagina)
    with open(LIBRO, "wb") as f:
        escritor.write(f)
    TEMPORAL.unlink(missing_ok=True)

    print("cuerpo del libro: %d paginas" % conservadas)
    print("cuadernillo: %d paginas (%d revisadas + %d nuevas)"
          % (len(cuadernillo.pages), len(REVISADAS), len(NUEVAS)))
    print("total: %d paginas -> %s" % (conservadas + len(cuadernillo.pages), LIBRO.name))
    return 0


if __name__ == "__main__":
    sys.exit(main())
