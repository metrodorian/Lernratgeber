#!/usr/bin/env python3
"""
build_all.py — Erzeugt all.md: Einleitung + alle 12 Kapitel in einer Seite.
  - Inhaltsverzeichnis-Links werden zu Anker-Links (#kapitel-N)
  - Vor jedem Kapitel steht ein <div id="kapitel-N"> → funktioniert als
    interner PDF-Link wenn Chrome headless die Seite druckt
Aufruf: python3 tools/build_all.py
"""
from pathlib import Path

REPO = Path(__file__).parent.parent

CHAPTERS = [
    "01_Wie_Gedaechtnis_funktioniert",
    "02_Die_zwei_Koenigstechniken",
    "03_Tief_verstehen",
    "04_Freude_am_Lernen",
    "05_Gedaechtniskunst",
    "06_Notizen_und_Texte",
    "07_Fokus_und_Motivation",
    "08_Der_Koerper_lernt_mit",
    "09_Kopf_und_Einstellung",
    "10_Als_Hochbegabte_lernen",
    "11_Mythen",
    "12_Kuenstliche_Intelligenz",
]

# Alte Datei-Links → Anker-Links im kombinierten Dokument
LINK_MAP = {}
for i, slug in enumerate(CHAPTERS, 1):
    LINK_MAP[f"{slug}.md"]   = f"#kapitel-{i}"
    LINK_MAP[f"{slug}.html"] = f"#kapitel-{i}"

def update_links(text):
    for old, new in LINK_MAP.items():
        text = text.replace(f"]({old})", f"]({new})")
    return text

parts = [
    "---",
    "layout: default",
    'title: "Lernratgeber — Vollständige Ausgabe"',
    "---",
    "",
]

# Einleitung (README)
readme = (REPO / "README.md").read_text(encoding="utf-8")
readme = update_links(readme)
parts.append(readme)

# Kapitel
for i, slug in enumerate(CHAPTERS, 1):
    chapter = (REPO / f"{slug}.md").read_text(encoding="utf-8")
    # Anker-Div mit Seitenumbruch; unsichtbar auf der Website
    parts.append(f'\n<div class="chapter-break" id="kapitel-{i}"></div>\n')
    parts.append(chapter)

content = "\n".join(parts)
out = REPO / "all.md"
out.write_text(content, encoding="utf-8")
print(f"all.md geschrieben ({out.stat().st_size // 1024} KB, {len(CHAPTERS)} Kapitel)")
