# Bbl — Besluit bouwwerken leefomgeving

Brondata en importscript voor de Bbl-toets in GRiDS en Leja (quest-157; ontwerp in leja-brain
`documents/ontwerpen/2026-11-02-ontwerp-bbl-toets.md`).

## Bron

| | |
|---|---|
| Regeling | Besluit bouwwerken leefomgeving (Bbl), AMvB onder de Omgevingswet |
| BWB-id | BWBR0041297 |
| Toestand | geldend vanaf 2026-09-24 (`bwb-ng-vast-deel`: `http://wetten.overheid.nl/id/BWBR0041297/2026-09-24/0`) |
| Formaat | BWB-toestand XML, schema `toestand_2016-1.xsd` (repository.officiele-overheidspublicaties.nl) |
| Gedownload | 2026-11-02 door Martijn, van wetten.overheid.nl |
| Auteursrecht | Wet- en regelgeving is vrij van auteursrecht (Auteurswet art. 11); daarom in deze publieke repo |

## Opbouw van de toestand (telling 2026-09-24)

| Element | Aantal |
|---|---|
| hoofdstuk | 9 |
| afdeling | 32 |
| paragraaf | 111 |
| artikel | 612 |
| lid | 1207 |
| alinea (`al`) | 21357 |

Afbeeldingen in `bron/.../images/` zijn de twee figuren die de toestand bevat (tabellen in beeldvorm).

## Mappen

- `bron/BWBR0041297_<datum>/` — de onbewerkte toestand zoals gedownload, één map per versie. Nooit bewerken.
- `import/bbl_import.py` — zet de XML om naar graph-nodes in een GRiDS-compliance-structuur en schrijft ze via de neo4j-driver (quest-157 stap 02 in leja-brain).

## Import (`import/bbl_import.py`)

Alleen de standaardbibliotheek plus het pakket `neo4j`. Verbindingsgegevens komen uit omgevingsvariabelen
(`NEO4J_URI`, `NEO4J_USERNAME`, `NEO4J_PASSWORD`) of anders uit de MCP-serverconfiguratie van Claude Desktop
(`%APPDATA%\Claude\claude_desktop_config.json`, `mcpServers[<server>]`), net als `tools/pion/apply_object_template.py`
in leja-brain. Er staan geen wachtwoorden in de repo of op de commandoregel.

```bash
cd bbl/import
python bbl_import.py ../bron/BWBR0041297_2026-09-24/BWBR0041297_2026-09-24_0.xml --dry-run --dump bbl.json
python bbl_import.py ../bron/BWBR0041297_2026-09-24/BWBR0041297_2026-09-24_0.xml
python bbl_import.py ../bron/BWBR0041297_2026-09-24/BWBR0041297_2026-09-24_0.xml --validate
```

| Optie | Werking |
|---|---|
| `--dry-run` | alleen parsen: telling, lijst van afwijkingen in de XML, geen verbinding |
| `--dump <pad>` | het geparste model als JSON (nodes en relaties) |
| `--server` | `neo4j-leja` (standaard, de sandbox) of `neo4j-grids-tst-v3` |
| `--department-bfguid` | Department waarvan de `Frameworks`-container de `LegalFramework` krijgt (standaard de sandbox ZGEM / Technisch Beheer) |
| `--validate` | tellingen tegen de XML, steekproeven tabel 4.179 en 4.162, gebruiksfuncties tegen de PropertyTemplate `Gebruiksfunctie` |
| `--no-write` | verbinden en de diff tonen, niets schrijven |
| `--prune` | nodes en relaties van deze toestand verwijderen die niet meer in de XML staan |

Het script is **herhaalbaar en deterministisch**: elke node krijgt een id uit de toestand en het nummer
(`bbl-2026-09-24-art-4.180-lid-1`, `bbl-2026-09-24-tabel-4.179-rij-8`) en een `bfguid` als uuid5 van dat id.
Vóór het schrijven leest het de bestaande stand en schrijft het alleen nieuwe of gewijzigde nodes en relaties;
een tweede run op dezelfde toestand meldt `0 nieuw, 0 gewijzigd`. Een nieuwe toestand is een nieuwe map onder
`bron/` en een nieuwe `FrameworkSet` naast de oude.

### Wat er ontstaat

| Node | Uit de XML | Belangrijkste velden |
|---|---|---|
| `LegalFramework` (id `legalframework-bbl`) | `citeertitel`, `bwb-id` | `name`, `bwb_id`, `url` |
| `FrameworkSet` (id `bbl-<toestand>`) | `toestand@inwerkingtreding` | `toestand`, `bwb_ng_vast_deel`, tellingen |
| `Framework` niveau `hoofdstuk`, `afdeling`, `paragraaf` | `kop/nr`, `kop/titel` | `niveau`, `nummer`, `titel`, `volgorde`, `bwb_pad` |
| `Framework` niveau `artikel` | `artikel/kop` | `titel` (tekst tussen haakjes), `aansturingsartikel`, `aantal_leden`, `tekst` (alleen zonder leden), `tabellen`, `gebruiksfuncties` |
| `Framework` niveau `lid` | `lid` | `nummer`, `artikel`, `tekst` (platte tekst, zonder tabel), `normen` (NEN, NEN-EN, NTA, NPR), `heeft_tabel`, `heeft_figuur` |
| `Gebruiksfunctierij` | rij in een aansturingstabel | `tabel`, `code` (`1a`, `8`, `overige`), `gebruiksfunctie`, `gf_nummer`, `subcategorie`, `restrij` |

Relaties: `HAS_FRAMEWORKSET`, `HAS_FRAMEWORK` (de hele boom), `HAS_GEBRUIKSFUNCTIERIJ` (aansturingsartikel → rij)
en per cel `STUURT_AAN {kolomnr, kolomtitel, lid_kop, cel, grenswaarde, eenheid, grenswaarde_num}` van rij naar lid
(of naar het artikel als de kop `*` zegt). Alle nodes dragen `src: 'bbl-import'`, `version: '<toestand>'`,
`domein: '*'`, `domain: 'grids'`. Hoe dit in de sandbox hangt en voorbeeldqueries: leja-brain
`skills/grids/references/bbl-structuur.md`.

### Afwijkingen in de toestand 2026-09-24

Het script meldt ze bij elke run (`afwijkingen (26)`); dit zijn de soorten:

- **16 tabellen zijn geen aansturingstabel** (geen kopregels `artikel` en `lid`): waardentabellen zoals 3.12a/b en
  4.17a/b (brandwerendheid), 3.20 en 4.26 (afmetingen trap), 3.97, 4.15b.1/2 (golfhoogte), 4.104 (luchtvaartlawaai),
  4.138 (verdunningsfactoren), 4.141 (rookdoorlatendheid), 4.248, 5.21, 7.17 en 7.39. Ze worden overgeslagen; het lid
  krijgt `heeft_tabel: true`. Hun inhoud is werk voor de curatie (stap 04).
- **Tabel 4.148A** heeft in de waardenkolommen artikel `4` in de kop in plaats van `4.149`; herleid via de gelijke
  kolomtitel `bijna energieneutraal`.
- **Tabel 4.225** schrijft `4,228`, `4,229` en `4,230` met komma; gelezen als `4.228` enzovoort.
- **Tabel 4.117** noemt lid 1 van artikel 4.119, dat geen leden heeft; de relatie wijst naar het artikel.
- **Tabel 4.24** gebruikt de letter `c` twee keer onder bijeenkomstfunctie (`voor alcoholgebruik` en `andere
  bijeenkomstfunctie`); de tweede rij krijgt het volgnummer achter het id (`...-rij-2c-7`).
- **Tabel 5.8B** heeft in rij 7b de celwaarde `2` onder de lid-kop `1`; de kop wint, de cel staat op de relatie.
- **Lege artikelcellen in de kop** (tabel 3.83, 4.49, 5.8a en meer) horen bij het artikel links ervan; het script
  vult ze door zolang de lidregel een lidnummer heeft.
- **Restrij** `Alle niet hierboven genoemde gebruiksfuncties` (hoofdstuk 3 en tabel 4.11) wordt een rij met
  `code: 'overige'` en `restrij: true`; hij staat niet in de lijst van twaalf gebruiksfuncties.
- **Subcategorie over twee regels** (tabel 4.179: `voor het aanschouwen van sport, voor film,` / `voor muziek of voor
  theater`) wordt samengevoegd.
- **Eenheden** staan per tabel op een andere plek (kopregel onder `lid`, losse regel, of de gebruiksfunctieregel zoals
  `[m]` bij Woonfunctie in 4.179); overal herkend aan de vierkante haken.
- **Meerdere waardenkolommen voor één lid** (tabel 3.30 en 4.42: drie brandklassen per lid, per zijde) krijgen elk een
  eigen `STUURT_AAN`-relatie; één waardenkolom per lid komt op de lidrelatie zelf.

## Versiebeheer

Het Bbl wijzigt meerdere keren per jaar. Een nieuwe toestand komt als nieuwe map onder `bron/` met de
inwerkingtredingsdatum in de naam; nodes in de graph dragen `src` en `version` met diezelfde datum.
