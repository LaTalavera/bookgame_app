#!/usr/bin/env bash
# Regenera el capitulo de reglas del PDF con sus dependencias resueltas.
#
# fix_rules_section.py necesita pypdf, reportlab y pillow, que no estan en el
# python3 del sistema. Hasta ahora eso se resolvia a mano con un venv temporal
# en /tmp, que desaparecia entre sesiones. Este script crea (o reutiliza) un
# venv estable en scripts/.venv y ejecuta el generador dentro de el.
#
#   ./scripts/build_rules_pdf.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="$SCRIPT_DIR/.venv"
STAMP="$VENV/.requirements-stamp"
REQS="$SCRIPT_DIR/requirements.txt"

if [ ! -x "$VENV/bin/python" ]; then
	echo "==> Creando entorno virtual en $VENV"
	python3 -m venv "$VENV"
fi

# Solo reinstalamos si requirements.txt cambio desde la ultima vez.
CURRENT_HASH="$(shasum -a 256 "$REQS" | cut -d' ' -f1)"
if [ ! -f "$STAMP" ] || [ "$(cat "$STAMP")" != "$CURRENT_HASH" ]; then
	echo "==> Instalando dependencias"
	"$VENV/bin/pip" install --quiet --upgrade pip
	"$VENV/bin/pip" install --quiet -r "$REQS"
	echo "$CURRENT_HASH" > "$STAMP"
fi

echo "==> Regenerando el capitulo de reglas"
"$VENV/bin/python" "$SCRIPT_DIR/fix_rules_section.py" "$@"

# El cuerpo ilustrado del libro no se genera desde saga.json y solo admite
# anadidos, asi que las secciones que ganan una decision nueva se reimprimen
# en un apendice al final. Es idempotente: repetirlo no acumula cuadernillos.
echo "==> Anadiendo el cuadernillo de secciones revisadas"
"$VENV/bin/python" "$SCRIPT_DIR/append_expansion_booklet.py"

# El cuadernillo anterior se regenera truncando todo lo que tenga detras, asi
# que la fe de erratas debe reponerse siempre despues de el. Este es el orden
# que deja el PDF completo: cuerpo + secciones revisadas + erratas.
echo "==> Anadiendo la fe de erratas de estilo"
exec "$VENV/bin/python" "$SCRIPT_DIR/append_style_errata.py"
