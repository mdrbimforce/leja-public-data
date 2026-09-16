# Pion IFC5 (ifcx) testbestanden

Publiek toegankelijke testbestanden voor de officiële buildingSMART IFC5-viewer
(https://ifc5.technical.buildingsmart.org/viewer/, "url"-veld), zodat een export
uit `tools/pion/export_ifc5.py` (leja-brain-repo) getest kan worden zonder eerst
een lokaal bestand te uploaden. Bewust hier gepubliceerd (geen persoonsgegevens
of bedrijfsgeheimen — gegenereerde CrossCube-putten op basis van publieke
productafmetingen), niet als permanente distributie maar als test-fixture.

**Let op — welke URL-vorm gebruiken**: de "url"-invoer van de viewer verwacht de
*raw* inhoud, geen GitHub-webpagina. Gebruik dus
`https://raw.githubusercontent.com/mdrbimforce/leja-public-data/main/pion/ifc5-testfiles/<bestand>`,
niet een `github.com/.../blob/...`-link (die geeft HTML terug, geen JSON, en de
viewer meldt dan "Failed to fetch"). Na een verse push kan de raw-CDN een paar
minuten achterlopen; bij twijfel een `?<willekeurig>=1`-querystring toevoegen of
de commit-SHA i.p.v. `main` in het pad gebruiken.

## Bestanden (16, één per testrun in `documents/references/pion/testrun-*`)

Alle 16 exports uit `tools/pion/export_ifc5.py`, ná de drie schemafixes van
2026-09-16 (`pion::prop::`-namespace, `bsi::ifc::material`, `gltf::material` —
zie `tools/pion/export_ifc5.py` docstring en
`documents/references/pion/instantiatie-en-export.md`):

- `testrun-20260824-213211.leja-ifc5.ifcx`
- `testrun-20260910-A.leja-ifc5.ifcx`
- `testrun-20260910-B.leja-ifc5.ifcx`
- `testrun-20260910-C.leja-ifc5.ifcx`
- `testrun-20260913-V01.leja-ifc5.ifcx` t/m `testrun-20260913-V12.leja-ifc5.ifcx`

Elk bestand komt 1-op-1 overeen met de gelijknamige map onder
`documents/references/pion/` in leja-brain (bevat ook de bron-changedata en de
IFC2X3/IFC4-varianten van dezelfde aanvraag).

## Bijwerken

Bij een volgende exporter-wijziging: regenereer de bestanden in leja-brain
(`documents/references/pion/testrun-*/*.leja-ifc5.ifcx`) en kopieer ze hierheen
onder dezelfde naam (overschrijven, geen versienummers in de bestandsnaam).
