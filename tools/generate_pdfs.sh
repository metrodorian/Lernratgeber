#!/usr/bin/env bash
# generate_pdfs.sh — Erzeugt PDFs aller Kapitel und eine Gesamtdatei.
#
# Verwendung:
#   ./tools/generate_pdfs.sh                           # live-Site (Standard)
#   ./tools/generate_pdfs.sh http://localhost:4000     # lokaler Jekyll-Server
#
# Voraussetzungen: Google Chrome (macOS), Python 3 + pypdf
# PDF-Ausgabe: pdfs/<kapitel>.pdf + pdfs/Lernratgeber_komplett.pdf
# Nach der Erzeugung die PDFs committen: git add pdfs/ && git commit -m "PDFs aktualisiert"

set -euo pipefail

BASE_URL="${1:-https://metrodorian.github.io/Lernratgeber}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$REPO_ROOT/pdfs"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

if [ ! -x "$CHROME" ]; then
  echo "Fehler: Google Chrome nicht gefunden unter: $CHROME" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Alle Seiten: Dateiname (ohne .html) → URL-Pfad
declare -a PAGES=(
  "01_Wie_Gedaechtnis_funktioniert"
  "02_Die_zwei_Koenigstechniken"
  "03_Tief_verstehen"
  "04_Freude_am_Lernen"
  "05_Gedaechtniskunst"
  "06_Notizen_und_Texte"
  "07_Fokus_und_Motivation"
  "08_Der_Koerper_lernt_mit"
  "09_Kopf_und_Einstellung"
  "10_Als_Hochbegabte_lernen"
  "11_Mythen"
  "12_Kuenstliche_Intelligenz"
)

echo "Basis-URL: $BASE_URL"
echo "Ausgabe:   $OUT_DIR"
echo ""

CHAPTER_PDFS=()

for page in "${PAGES[@]}"; do
  url="$BASE_URL/$page.html"
  out="$OUT_DIR/$page.pdf"
  echo "  → $page.pdf"
  "$CHROME" \
    --headless=new \
    --disable-gpu \
    --no-pdf-header-footer \
    --print-to-pdf="$out" \
    --run-all-compositor-stages-before-draw \
    --virtual-time-budget=3000 \
    "$url" 2>/dev/null
  CHAPTER_PDFS+=("$out")
done

echo ""
echo "Erstelle Gesamtdatei …"

# Kapitel-PDFs zusammenführen
python3 - "${CHAPTER_PDFS[@]}" "$OUT_DIR/Lernratgeber_komplett.pdf" <<'PYEOF'
import sys
from pypdf import PdfWriter

inputs = sys.argv[1:-1]
output = sys.argv[-1]

writer = PdfWriter()
for path in inputs:
    writer.append(path)

with open(output, "wb") as f:
    writer.write(f)

print(f"  → Lernratgeber_komplett.pdf ({len(inputs)} Kapitel, {len(writer.pages)} Seiten)")
PYEOF

echo ""
echo "Fertig. Jetzt committen:"
echo "  git add pdfs/ && git commit -m 'PDFs aktualisiert' && git push"
