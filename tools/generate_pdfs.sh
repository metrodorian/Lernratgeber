#!/usr/bin/env bash
# generate_pdfs.sh — Erzeugt PDFs aller Kapitel und eine Gesamtdatei.
#
# Verwendung:
#   ./tools/generate_pdfs.sh                           # live-Site (Standard)
#   ./tools/generate_pdfs.sh http://localhost:4000     # lokaler Jekyll-Server
#
# Was passiert:
#   1. all.md wird neu gebaut (Einleitung + alle Kapitel, Anker-Links)
#   2. all.md wird gepusht und GitHub Pages Deploy abgewartet
#   3. Einzel-PDFs für alle 12 Kapitel werden generiert
#   4. Gesamtdatei wird aus all.html generiert (interne Links funktionieren)
#   5. Danach: git add pdfs/ && git commit -m 'PDFs aktualisiert' && git push
#
# Voraussetzungen: Google Chrome (macOS), Python 3 + pypdf

set -euo pipefail

BASE_URL="${1:-https://metrodorian.github.io/Lernratgeber}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$REPO_ROOT/pdfs"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

if [ ! -x "$CHROME" ]; then
  echo "Fehler: Google Chrome nicht gefunden unter: $CHROME" >&2; exit 1
fi

mkdir -p "$OUT_DIR"

# ── 1. all.md aufbauen ────────────────────────────────────────────────────────
echo "Baue all.md …"
python3 "$REPO_ROOT/tools/build_all.py"

# ── 2. all.md pushen und Deploy abwarten ──────────────────────────────────────
cd "$REPO_ROOT"
if git diff --quiet HEAD -- all.md 2>/dev/null && git ls-files --error-unmatch all.md &>/dev/null; then
  echo "all.md unverändert, überspringe Push."
else
  echo "Pushe all.md …"
  git add all.md
  git commit -m "all.md aktualisiert (generiert)"
  git push
  echo "Warte auf GitHub Pages Deploy …"
  until curl -sf "$BASE_URL/all.html" | grep -q "kapitel-1"; do sleep 8; done
  echo "Deploy fertig."
fi
echo ""

# ── 3. Einzel-PDFs ────────────────────────────────────────────────────────────
PAGES=(
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

for page in "${PAGES[@]}"; do
  echo "  → $page.pdf"
  "$CHROME" \
    --headless=new --disable-gpu \
    --no-pdf-header-footer \
    --print-to-pdf="$OUT_DIR/$page.pdf" \
    --run-all-compositor-stages-before-draw \
    --virtual-time-budget=3000 \
    "$BASE_URL/$page.html" 2>/dev/null
done

# ── 4. Gesamtdatei aus all.html ───────────────────────────────────────────────
echo ""
echo "Erstelle Gesamtdatei aus all.html …"
"$CHROME" \
  --headless=new --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="$OUT_DIR/Lernratgeber_komplett.pdf" \
  --run-all-compositor-stages-before-draw \
  --virtual-time-budget=8000 \
  "$BASE_URL/all.html" 2>/dev/null

# Seitenzahl ausgeben
python3 - "$OUT_DIR/Lernratgeber_komplett.pdf" <<'PYEOF'
import sys
from pypdf import PdfReader
r = PdfReader(sys.argv[1])
print(f"  → Lernratgeber_komplett.pdf ({len(r.pages)} Seiten)")
PYEOF

echo ""
echo "Fertig. Jetzt committen:"
echo "  git add pdfs/ && git commit -m 'PDFs aktualisiert' && git push"
