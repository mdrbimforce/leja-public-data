"""Importeer een BWB-toestand van het Besluit bouwwerken leefomgeving (Bbl) als graph (quest-157 stap 02).

Leest de toestand-XML (schema toestand_2016-1) en schrijft de wettekst als GRiDS-compliance-structuur:

    Frameworks -[:HAS_LEGALFRAMEWORK]-> LegalFramework "Bbl"
      -[:HAS_FRAMEWORKSET]-> FrameworkSet per toestand (quest-113 W6: de specifieke norm)
        -[:HAS_FRAMEWORK]-> Framework niveau hoofdstuk
          -[:HAS_FRAMEWORK]-> Framework niveau afdeling
            -[:HAS_FRAMEWORK]-> Framework niveau paragraaf
              -[:HAS_FRAMEWORK]-> Framework niveau artikel
                -[:HAS_FRAMEWORK]-> Framework niveau lid
    aansturingsartikel -[:HAS_GEBRUIKSFUNCTIERIJ]-> Gebruiksfunctierij
    Gebruiksfunctierij -[:STUURT_AAN {kolomnr, kolomtitel, grenswaarde, eenheid}]-> Framework (lid of artikel)

Artikelen die rechtstreeks onder een hoofdstuk of afdeling staan, hangen daar aan (de boom volgt de XML).
Alle nodes dragen `id` (deterministisch, bv. `bbl-2026-09-24-art-4.180-lid-1`), `bfguid` (uuid5 van het id),
`src: 'bbl-import'`, `version: <toestand>`, `domein: '*'`. Een tweede run op dezelfde toestand wijzigt niets:
het script leest eerst de bestaande stand en schrijft alleen nieuwe of gewijzigde nodes en relaties.

Gebruik:
    python bbl_import.py <toestand.xml> --dry-run [--dump out.json]     telling, afwijkingen, JSON-dump
    python bbl_import.py <toestand.xml>                                 import op neo4j-leja (sandbox)
    python bbl_import.py <toestand.xml> --server neo4j-grids-tst-v3 --department-bfguid <guid>
    python bbl_import.py <toestand.xml> --validate                      tellingen en steekproeven tegen de graph
    python bbl_import.py <toestand.xml> --prune                         verwijdert nodes van deze toestand die niet meer in de XML staan

Verbindingsgegevens zoals leja-brain `tools/pion/apply_object_template.py`: eerst omgevingsvariabelen
(NEO4J_URI/NEO4J_USERNAME/NEO4J_PASSWORD), anders de MCP-serverconfiguratie van Claude Desktop
(%APPDATA%/Claude/claude_desktop_config.json, mcpServers[<server>]). Geen externe dependencies behalve `neo4j`.
"""
import argparse
import datetime as dt
import json
import os
import re
import sys
import uuid
import xml.etree.ElementTree as ET
from collections import Counter, OrderedDict

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

SRC = "bbl-import"
BFGUID_NS = uuid.uuid5(uuid.NAMESPACE_URL, "https://bimforce.com/leja/bbl")
# Department "Technisch Beheer" van Company ZGEM: de GRiDS-sandbox in neo4j-leja (skills/grids/SKILL.md).
DEFAULT_DEPARTMENT_BFGUID = "c644ecb9-9fd1-41e3-94fe-05e1f84c7075"
NIVEAUS = ("hoofdstuk", "afdeling", "paragraaf", "artikel", "lid")
STREEP = {"–", "—", "-", "−"}
LID_HEADER_RE = re.compile(r"^(\d+)([a-z])?$")
NORM_RE = re.compile(
    r"\b(NEN(?:-EN(?:-ISO|-IEC)?|-ISO|-IEC)?\s?\d{3,5}(?:-\d{1,2})?|NTA\s?\d{4}|NPR\s?\d{4})\b"
)
GEBRUIKSFUNCTIES_BBL = [
    "Woonfunctie", "Bijeenkomstfunctie", "Celfunctie", "Gezondheidszorgfunctie", "Industriefunctie",
    "Kantoorfunctie", "Logiesfunctie", "Onderwijsfunctie", "Sportfunctie", "Winkelfunctie",
    "Overige gebruiksfunctie", "Bouwwerk geen gebouw zijnde",
]


# --------------------------------------------------------------------------- verbinding

def load_conn(server):
    envmap = {
        "neo4j-leja": ("NEO4J_URI", "NEO4J_USERNAME", "NEO4J_PASSWORD", "NEO4J_DATABASE"),
        "neo4j-grids-tst-v3": ("GRIDS_TST_URI", "GRIDS_TST_USER", "GRIDS_TST_PASSWORD", "GRIDS_TST_DATABASE"),
    }
    if server in envmap:
        u, us, pw_, dbn = (os.environ.get(k) for k in envmap[server])
        if u and us and pw_:
            return u, us, pw_, dbn or "neo4j"
    cfg_path = os.path.join(os.environ.get("APPDATA", ""), "Claude", "claude_desktop_config.json")
    if not os.path.exists(cfg_path):
        sys.exit(f"Geen verbindingsgegevens voor '{server}' (geen omgevingsvariabelen, geen {cfg_path})")
    cfg = json.load(open(cfg_path, encoding="utf-8"))
    srv = cfg["mcpServers"][server]
    args = srv.get("args", [])
    env = srv.get("env", {})
    url = user = pw = db = None
    for i, a in enumerate(args):
        if a in ("--db-url", "--url") and i + 1 < len(args):
            url = args[i + 1]
        elif a in ("--username", "--user") and i + 1 < len(args):
            user = args[i + 1]
        elif a == "--password" and i + 1 < len(args):
            pw = args[i + 1]
        elif a == "--database" and i + 1 < len(args):
            db = args[i + 1]
    if url and (user is None or pw is None):
        j = args.index(url)
        rest = [a for a in args[j + 1:] if not a.startswith("--")]
        if user is None and rest:
            user = rest[0]
        if pw is None and len(rest) > 1:
            pw = rest[1]
        if db is None and len(rest) > 2:
            db = rest[2]
    url = url or env.get("NEO4J_URI") or env.get("NEO4J_URL")
    user = user or env.get("NEO4J_USERNAME") or env.get("NEO4J_USER")
    pw = pw or env.get("NEO4J_PASSWORD")
    db = db or env.get("NEO4J_DATABASE") or "neo4j"
    if not (url and user and pw):
        sys.exit(f"Geen volledige verbindingsgegevens voor '{server}' in {cfg_path}")
    return url, user, pw, db


# --------------------------------------------------------------------------- xml-hulpfuncties

def plain(el, skip=("meta-data", "table")):
    """Platte tekst van een element, zonder meta-data en tabellen; lijst-items met hun nummer."""
    parts = []

    def walk(e):
        if e.tag in skip:
            return
        if e.text:
            parts.append(e.text)
        for c in e:
            walk(c)
            if c.tail:
                parts.append(c.tail)

    walk(el)
    return " ".join("".join(parts).split())


def cell_text(entry):
    return plain(entry, skip=("meta-data",))


def kop(el):
    k = el.find("kop")
    if k is None:
        return "", "", ""
    return (k.findtext("label") or "").strip(), (k.findtext("nr") or "").strip(), (k.findtext("titel") or "").strip()


def artikel_titel(titel):
    """'(vrije doorgang)' -> 'vrije doorgang'."""
    t = titel.strip()
    if t.startswith("(") and t.endswith(")"):
        t = t[1:-1]
    return t.strip()


def normen(text):
    out = set()
    for m in NORM_RE.findall(text):
        out.add(re.sub(r"\s+", " ", m.replace("NEN", "NEN ").replace("  ", " ")).replace("NEN -", "NEN-").strip())
    # 'NEN 6068' en 'NEN6068' worden dezelfde
    return sorted({re.sub(r"(?<=[A-Z])\s?(?=\d)", " ", n) for n in out})


def getal(s):
    """Nederlandse notatie naar float: '2,1' -> 2.1, '1.000' -> 1000. None als het geen getal is."""
    t = s.strip()
    if re.fullmatch(r"\d{1,3}(\.\d{3})+(,\d+)?", t):
        t = t.replace(".", "").replace(",", ".")
    elif re.fullmatch(r"\d+(,\d+)?", t):
        t = t.replace(",", ".")
    else:
        return None
    try:
        return float(t)
    except ValueError:
        return None


def bfguid(id_):
    return str(uuid.uuid5(BFGUID_NS, id_))


# --------------------------------------------------------------------------- model

class Model:
    def __init__(self, toestand):
        self.toestand = toestand
        self.nodes = OrderedDict()      # id -> {"label": str, "props": dict}
        self.rels = OrderedDict()       # (from, type, to, key) -> props
        self.afwijkingen = []           # tekstregels, voor het rapport
        self.tabel_stats = Counter()

    def node(self, label, id_, **props):
        if id_ in self.nodes:
            self.afwijkingen.append(f"dubbel id {id_}")
            return self.nodes[id_]
        props = {k: v for k, v in props.items() if v is not None and v != "" and v != []}
        props.update(id=id_, bfguid=bfguid(id_), src=SRC, version=self.toestand, domein="*", domain="grids")
        self.nodes[id_] = {"label": label, "props": props}
        return self.nodes[id_]

    def rel(self, a, typ, b, key=None, **props):
        k = (a, typ, b, key)
        props = {kk: v for kk, v in props.items() if v is not None and v != ""}
        if k in self.rels:
            self.rels[k].update(props)
        else:
            self.rels[k] = props
        return self.rels[k]

    def afwijking(self, msg):
        self.afwijkingen.append(msg)


# --------------------------------------------------------------------------- parser wettekst

def parse(path, department_bfguid):
    root = ET.parse(path).getroot()
    toestand = root.get("inwerkingtreding")
    bwb_id = root.get("bwb-id")
    m = Model(toestand)
    wet = root.find("wetgeving")
    citeertitel = plain(wet.find("citeertitel")) if wet.find("citeertitel") is not None else "Besluit bouwwerken leefomgeving"
    intitule = plain(wet.find("intitule")) if wet.find("intitule") is not None else ""

    lf_id = "legalframework-bbl"
    m.node("LegalFramework", lf_id, name=citeertitel, bwb_id=bwb_id, type="wet", referentie=bwb_id,
           intitule=intitule, soort=wet.get("soort"), url=f"https://wetten.overheid.nl/{bwb_id}")
    fs_id = f"bbl-{toestand}"
    m.node("FrameworkSet", fs_id, name=f"{citeertitel}, toestand {toestand}", toestand=toestand,
           inwerkingtreding=toestand, bwb_id=bwb_id, bwb_ng_vast_deel=root.get("bwb-ng-vast-deel"),
           bron_bestand=os.path.basename(path), aantal_artikelen=0, aantal_leden=0)
    m.rel(lf_id, "HAS_FRAMEWORKSET", fs_id)
    m.department_bfguid = department_bfguid
    m.legalframework_id = lf_id
    m.frameworkset_id = fs_id

    prefix = {"hoofdstuk": "h", "afdeling": "afd", "paragraaf": "par", "artikel": "art"}
    counts = Counter()
    artikel_index = {}   # nr -> id
    lid_index = {}       # (artnr, lidnr) -> id
    tabellen = []        # (table-element, artikel-id, artikel-nr, hoofdstuk-nr)

    def walk(el, parent_id, pad, hoofdstuk_nr, volgorde):
        label, nr, titel = kop(el)
        niveau = el.tag
        id_ = f"bbl-{toestand}-{prefix[niveau]}-{nr}"
        counts[niveau] += 1
        if niveau == "hoofdstuk":
            hoofdstuk_nr = nr
        props = dict(niveau=niveau, nummer=nr, volgorde=volgorde, kop_label=label or niveau.capitalize(),
                     bwb_pad=el.get("bwb-ng-variabel-deel"), hoofdstuk=hoofdstuk_nr)
        if niveau == "artikel":
            t = artikel_titel(titel)
            props.update(titel=t, name=f"Artikel {nr}" + (f" ({t})" if t else ""),
                         aansturingsartikel=("aansturingsartikel" in t.lower()),
                         inwerking=el.get("inwerking"))
            leden = el.findall("lid")
            if not leden:
                tekst = plain(el)
                tekst = re.sub(rf"^Artikel\s+{re.escape(nr)}\s*(\([^)]*\))?\s*", "", tekst).strip()
                props.update(tekst=tekst, normen=normen(tekst), aantal_leden=0)
            else:
                props.update(aantal_leden=len(leden))
            if el.find("table") is not None:
                props["heeft_tabel"] = True
            m.node("Framework", id_, **props)
            m.rel(parent_id, "HAS_FRAMEWORK", id_)
            artikel_index[nr] = id_
            for tb in el.findall("table"):
                tabellen.append((tb, id_, nr, hoofdstuk_nr, None))
            for i, lid in enumerate(leden, start=1):
                lidnr = (lid.findtext("lidnr") or str(i)).strip()
                lid_id = f"{id_}-lid-{lidnr}"
                tekst = plain(lid)
                tekst = re.sub(rf"^{re.escape(lidnr)}\s+", "", tekst)
                lprops = dict(niveau="lid", nummer=lidnr, artikel=nr, kop_label="Lid", volgorde=i,
                              name=f"Artikel {nr}, lid {lidnr}", tekst=tekst, normen=normen(tekst),
                              bwb_pad=lid.get("bwb-ng-variabel-deel"), hoofdstuk=hoofdstuk_nr)
                if lid.find("table") is not None:
                    lprops["heeft_tabel"] = True
                if lid.find("plaatje") is not None:
                    lprops["heeft_figuur"] = True
                m.node("Framework", lid_id, **lprops)
                m.rel(id_, "HAS_FRAMEWORK", lid_id)
                lid_index[(nr, lidnr)] = lid_id
                counts["lid"] += 1
                for tb in lid.findall("table"):
                    tabellen.append((tb, id_, nr, hoofdstuk_nr, lidnr))
            return
        props.update(titel=titel, name=f"{label} {nr} {titel}".strip())
        m.node("Framework", id_, **props)
        m.rel(parent_id, "HAS_FRAMEWORK", id_)
        v = 0
        for child in el:
            if child.tag in NIVEAUS:
                v += 1
                walk(child, id_, pad + [nr], hoofdstuk_nr, v)

    wettekst = wet.find("wet-besluit/wettekst")
    v = 0
    for child in wettekst:
        if child.tag == "hoofdstuk":
            v += 1
            walk(child, fs_id, [], None, v)
        elif child.tag in NIVEAUS:
            m.afwijking(f"{child.tag} rechtstreeks onder wettekst: {kop(child)[1]}")

    m.nodes[fs_id]["props"].update(aantal_artikelen=counts["artikel"], aantal_leden=counts["lid"],
                                    aantal_hoofdstukken=counts["hoofdstuk"], aantal_afdelingen=counts["afdeling"],
                                    aantal_paragrafen=counts["paragraaf"])
    m.counts = counts
    m.tabellen_totaal = tabellen
    for tb, art_id, art_nr, h_nr, lidnr in tabellen:
        parse_tabel(m, tb, art_id, art_nr, h_nr, lidnr, artikel_index, lid_index)
    # tabellen buiten artikelen (bijlagen) alleen tellen
    alle = sum(1 for _ in root.iter("table"))
    m.tabel_stats["tabellen_in_xml"] = alle
    m.tabel_stats["tabellen_in_artikelen"] = len(tabellen)
    return m


# --------------------------------------------------------------------------- parser aansturingstabellen

def colrange(entry, colnum):
    """Kolomnummers die een entry beslaat."""
    if entry.get("namest") and entry.get("nameend"):
        return list(range(colnum[entry.get("namest")], colnum[entry.get("nameend")] + 1))
    cn = entry.get("colname") or entry.get("namest")
    if cn in colnum:
        return [colnum[cn]]
    return []


def parse_tabel(m, tb, art_id, art_nr, h_nr, lidnr, artikel_index, lid_index):
    title = (tb.findtext("title") or "").strip()
    tnr = re.sub(r"^[Tt]abel\s+", "", title).split(" ")[0] if title else art_nr
    waar = f"tabel {tnr} (artikel {art_nr}" + (f" lid {lidnr}" if lidnr else "") + ")"
    tg = tb.find("tgroup")
    colnum = {cs.get("colname"): int(cs.get("colnum")) for cs in tg.findall("colspec")}
    ncols = int(tg.get("cols"))
    thead, tbody = tg.find("thead"), tg.find("tbody")
    if thead is None or tbody is None:
        m.afwijking(f"{waar}: geen aansturingstabel (geen thead/tbody), overgeslagen")
        m.tabel_stats["overig"] += 1
        return

    def rows_of(section):
        out = []
        for r in section.findall("row"):
            cells = {}
            for e in r.findall("entry"):
                cols = colrange(e, colnum)
                if not cols:
                    continue
                cells[tuple(cols)] = cell_text(e)
            out.append(cells)
        return out

    hrows, brows = rows_of(thead), rows_of(tbody)

    def row_has(cells, word):
        return any(t.strip().lower() == word for t in cells.values())

    ai = next((i for i, r in enumerate(hrows) if row_has(r, "artikel")), None)
    li = next((i for i, r in enumerate(hrows) if row_has(r, "lid")), None)
    if ai is None or li is None:
        m.afwijking(f"{waar}: geen aansturingstabel ('{title}', geen artikel/lid-kopregel), overgeslagen")
        m.tabel_stats["overig"] += 1
        return
    m.tabel_stats["aansturingstabellen"] += 1
    if h_nr == "4":
        m.tabel_stats["aansturingstabellen_h4"] += 1

    # gebruiksfunctie-kolommen: de kopcel 'gebruiksfunctie' in de eerste kopregel
    gf_cols = None
    for cols, t in hrows[0].items():
        if t.strip().lower() == "gebruiksfunctie":
            gf_cols = set(cols)
    if gf_cols is None:
        # terugvallen op de kolommen links van de eerste artikelcel
        first_art = min(c for cols, t in hrows[ai].items() if t.strip() and t.strip().lower() != "artikel" for c in cols)
        gf_cols = set(range(1, first_art))
        m.afwijking(f"{waar}: geen kopcel 'gebruiksfunctie', gebruiksfunctiekolommen afgeleid: 1..{first_art - 1}")
    data_cols = [c for c in range(1, ncols + 1) if c not in gf_cols]
    waarde_group = set()
    for cols, t in hrows[0].items():
        if t.strip().lower().startswith("waarde"):
            waarde_group.update(cols)

    # per datakolom: artikel, lid-kop, titel (alle kopregels boven de artikelregel), eenheid
    kol = {c: dict(artikel=None, lid=None, titels=[], eenheid=None, kolomnr=c) for c in data_cols}
    for i, r in enumerate(hrows):
        for cols, t in r.items():
            t = t.strip()
            for c in cols:
                if c not in kol:
                    continue
                if i == ai:
                    if t and t.lower() != "artikel":
                        kol[c]["artikel"] = t
                elif i == li:
                    if t and t.lower() != "lid":
                        kol[c]["lid"] = t
                elif i < ai:
                    if t and t.lower() not in ("leden van toepassing", "waarden", "gebruiksfunctie") and t not in kol[c]["titels"]:
                        kol[c]["titels"].append(t)
                else:  # kopregels onder de lid-regel: eenheden
                    if re.fullmatch(r"\[.*\]", t):
                        kol[c]["eenheid"] = t[1:-1]
                    elif t:
                        kol[c]["titels"].append(t)
    # een lege artikelcel in de kop hoort bij het artikel links ervan (tabel 3.83: '3.84' in kolom 4, kolom 5-11 leeg,
    # de lidregel telt door 1..8); doorvullen naar rechts zolang de lidregel een lidnummer heeft
    vorige = None
    for c in data_cols:
        k = kol[c]
        if k["artikel"]:
            vorige = k["artikel"]
        elif vorige and k["lid"]:
            k["artikel"] = vorige
            k["doorgevuld"] = True
    for c, k in kol.items():
        if k["artikel"] and "," in k["artikel"] and re.fullmatch(r"\d+,\d+[a-z]*", k["artikel"]):
            m.afwijking(f"{waar}: artikelnummer met komma in de kop ('{k['artikel']}'), gelezen als '{k['artikel'].replace(',', '.')}'")
            k["artikel"] = k["artikel"].replace(",", ".")

    def doelen(k):
        """Doel-nodes van een kolom: lijst (framework-id, onderdeel) of None als niet te herleiden."""
        a, l = k["artikel"], (k["lid"] or "").strip()
        if not a:
            return None
        art_id_ = artikel_index.get(a)
        if art_id_ is None:
            return None
        if l in ("*", ""):
            return [(art_id_, None)]
        out = []
        for deel in re.split(r"\s*(?:,|\ben\b|t/m)\s*", l):
            deel = deel.strip()
            if not deel:
                continue
            mm = LID_HEADER_RE.match(deel)
            if mm:
                lid_id = lid_index.get((a, mm.group(1)))
                if lid_id is None:
                    if m.nodes[art_id_]["props"].get("aantal_leden", 0) == 0:
                        # kop noemt een lid, maar het artikel heeft geen leden (tabel 4.117 kolom 4.119 lid 1): aan het artikel
                        k["lid_zonder_leden"] = True
                        return [(art_id_, None)]
                    return None
                out.append((lid_id, mm.group(2)))
            elif re.fullmatch(r"[a-z]", deel) and out:
                out[-1] = (out[-1][0], deel)      # '3, a' -> lid 3 onderdeel a
            else:
                return None
        return out or None

    for c, k in kol.items():
        k["titel"] = " / ".join(k["titels"])
    for c, k in kol.items():
        k["doelen"] = doelen(k)
        if k.get("lid_zonder_leden"):
            m.afwijking(f"{waar}: kolom {c} noemt lid '{k['lid']}' van artikel {k['artikel']}, dat geen leden heeft; gekoppeld aan het artikel")
        if k["doelen"] is None and k["artikel"] and c in waarde_group:
            # waardekolom met onherleidbaar artikel in de kop (tabel 4.148A: artikel '4'): zelfde kolomtitel als een lidkolom?
            kandidaten = {kk["artikel"] for cc, kk in kol.items() if cc not in waarde_group and kk["titel"] == k["titel"] and kk["artikel"] in artikel_index}
            if len(kandidaten) == 1:
                oud = k["artikel"]
                k["artikel"] = kandidaten.pop()
                k["doelen"] = doelen(k)
                m.afwijking(f"{waar}: waardekolom {c} met artikel '{oud}' in de kop herleid via de kolomtitel '{k['titel']}' naar artikel {k['artikel']}")
        if k["doelen"] is None and (k["artikel"] or k["lid"]):
            m.afwijking(f"{waar}: kolom {c} (artikel '{k['artikel']}', lid '{k['lid']}') niet te herleiden naar een lid of artikel")

    # body: gebruiksfunctierijen
    gf_sorted = sorted(gf_cols)
    rijen = []          # dicts: code, gebruiksfunctie, gf_nummer, subcategorie, sub_letter, cells{col: text}
    huidige_gf = None
    voetnoten = []
    kolomsubtitels = {}
    for ri, r in enumerate(brows):
        gcells = [(min(cols), t.strip()) for cols, t in r.items() if set(cols) <= gf_cols and t.strip()]
        gcells.sort()
        dcells = {}
        for cols, t in r.items():
            for c in cols:
                if c in kol:
                    dcells[c] = t.strip()
        # een eenheid tussen vierkante haken hoort bij de kolom, waar hij ook staat (kopregel, losse regel of de
        # gebruiksfunctieregel zoals '[m]' bij Woonfunctie in tabel 4.179)
        for c, t in list(dcells.items()):
            if re.fullmatch(r"\[.*\]", t):
                kol[c]["eenheid"] = t[1:-1]
                dcells[c] = ""
        nonempty_d = {c: t for c, t in dcells.items() if t}
        # voetnoot-regel of kolomsubtitels zonder gebruiksfunctie
        if not gcells:
            if nonempty_d and all(re.match(r"^\(\d+\)\s", t) for t in nonempty_d.values()):
                voetnoten.extend(nonempty_d.values())
                continue
            if nonempty_d and not rijen:
                for c, t in nonempty_d.items():
                    kolomsubtitels[c] = t
                    kol[c]["titels"].append(t)
                    kol[c]["titel"] = " / ".join(kol[c]["titels"])
                continue
            if not nonempty_d:
                continue
            m.afwijking(f"{waar}: regel {ri + 1} zonder gebruiksfunctie met inhoud {list(nonempty_d.values())[:3]}, overgeslagen")
            continue
        # gebruiksfunctie / subcategorie herkennen
        first_col, first = gcells[0]
        rest = [t for _, t in gcells[1:]]
        mm_num = re.fullmatch(r"(\d{1,2})(?:\s+(.+))?", first)
        mm_sub = re.fullmatch(r"([a-z])\.?(?:\s+(.+))?", first)
        if mm_num and (mm_num.group(2) or rest):
            naam = mm_num.group(2) or rest[0]
            huidige_gf = dict(nummer=int(mm_num.group(1)), naam=naam)
            sub = " ".join(rest[1:]) if mm_num.group(2) is None and len(rest) > 1 else ""
            if sub:
                m.afwijking(f"{waar}: gebruiksfunctieregel {naam!r} met extra cel {sub!r}")
            if not nonempty_d or all(t in STREEP for t in nonempty_d.values()) and False:
                continue
            if not nonempty_d:
                continue    # koprij boven subcategorieën
            rijen.append(dict(code=str(huidige_gf["nummer"]), gebruiksfunctie=naam, gf_nummer=huidige_gf["nummer"],
                              subcategorie=None, cells=dcells, volgorde=len(rijen) + 1))
        elif mm_sub and huidige_gf is not None:
            sub = mm_sub.group(2) or (" ".join(rest) if rest else "")
            if not sub:
                m.afwijking(f"{waar}: subcategorie {first!r} zonder omschrijving")
            rijen.append(dict(code=f"{huidige_gf['nummer']}{mm_sub.group(1)}", gebruiksfunctie=huidige_gf["naam"],
                              gf_nummer=huidige_gf["nummer"], subcategorie=sub, cells=dcells, volgorde=len(rijen) + 1))
        elif not rest and rijen and not nonempty_d and first_col == max(gf_sorted):
            # vervolgregel van een subcategorie-omschrijving ('voor het aanschouwen van sport, voor film,' / 'voor muziek of voor theater')
            rijen[-1]["subcategorie"] = (rijen[-1]["subcategorie"] or "") + " " + first
            rijen[-1]["subcategorie"] = rijen[-1]["subcategorie"].strip()
        elif not rest and nonempty_d and first.lower().startswith("alle niet hierboven genoemde"):
            # restrij (hoofdstuk 3 en tabel 4.11): geldt voor elke gebruiksfunctie die de tabel niet noemt
            huidige_gf = dict(nummer=None, naam=first)
            rijen.append(dict(code="overige", gebruiksfunctie=first, gf_nummer=None, subcategorie=None,
                              cells=dcells, volgorde=len(rijen) + 1, restrij=True))
        else:
            m.afwijking(f"{waar}: regel {ri + 1} niet herkend als gebruiksfunctie of subcategorie: {[t for _, t in gcells]}")

    # nodes en relaties
    tabel_props = dict(tabel=tnr, titel=title, aantal_rijen=len(rijen), aantal_kolommen=len(data_cols))
    art_node = m.nodes[art_id]["props"]
    art_node.setdefault("tabellen", [])
    if tnr not in art_node["tabellen"]:
        art_node["tabellen"].append(tnr)
    if voetnoten:
        art_node.setdefault("tabel_voetnoten", []).extend(f"{tnr}: {v}" for v in voetnoten)
    codes = Counter(r["code"] for r in rijen)
    for code, n in codes.items():
        if n > 1:
            m.afwijking(f"{waar}: rijcode {code} komt {n} keer voor (letter dubbel in de bron); tweede krijgt het volgnummer achter het id")
    gf_in_tabel = []
    for r in rijen:
        if r["gebruiksfunctie"] not in gf_in_tabel:
            gf_in_tabel.append(r["gebruiksfunctie"])
        rij_id = f"bbl-{m.toestand}-tabel-{tnr}-rij-{r['code']}"
        if rij_id in m.nodes:
            rij_id = f"{rij_id}-{r['volgorde']}"
        naam = r["gebruiksfunctie"] + (f": {r['subcategorie']}" if r["subcategorie"] else "")
        m.node("Gebruiksfunctierij", rij_id, name=f"Tabel {tnr} rij {r['code']} {naam}", tabel=tnr, artikel=art_nr,
               code=r["code"], gebruiksfunctie=r["gebruiksfunctie"], gf_nummer=r["gf_nummer"],
               subcategorie=r["subcategorie"], volgorde=r["volgorde"], hoofdstuk=h_nr,
               restrij=r.get("restrij"))
        m.rel(art_id, "HAS_GEBRUIKSFUNCTIERIJ", rij_id, tabel=tnr)
        # eerst de lid-cellen, dan de waarden
        per_doel = {}   # doel-id -> lijst van rel-keys voor deze rij
        waarde_cells = []
        for c in data_cols:
            t = r["cells"].get(c, "")
            k = kol[c]
            if not t or t in STREEP:
                continue
            is_lid_kolom = c not in waarde_group and (re.fullmatch(r"\d+[a-z]?|\*", t) is not None)
            if is_lid_kolom:
                if k["doelen"] is None:
                    m.afwijking(f"{waar}: cel kolom {c} rij {r['code']} ('{t}') zonder herleidbaar doel")
                    continue
                if t != "*" and k["lid"] and t not in re.split(r"\s*(?:,|\ben\b)\s*", k["lid"]) and t != k["lid"]:
                    m.afwijking(f"{waar}: celwaarde '{t}' in kolom {c} rij {r['code']} wijkt af van de lid-kop '{k['lid']}'")
                for doel_id, onderdeel in k["doelen"]:
                    props = dict(kolomnr=c, kolomtitel=k["titel"], lid_kop=k["lid"] or "*", cel=t, tabel=tnr)
                    if onderdeel:
                        props["onderdeel"] = onderdeel
                    m.rel(rij_id, "STUURT_AAN", doel_id, key=c, **props)
                    per_doel.setdefault(doel_id, []).append(c)
            else:
                waarde_cells.append((c, t))
        waarden_per_doel = Counter(doel_id for c, _ in waarde_cells if kol[c]["doelen"] for doel_id, _ in kol[c]["doelen"])
        for c, t in waarde_cells:
            k = kol[c]
            if k["doelen"] is None:
                m.afwijking(f"{waar}: waarde '{t}' in kolom {c} rij {r['code']} zonder herleidbaar artikel/lid ({k['artikel']} {k['lid']})")
                continue
            for doel_id, onderdeel in k["doelen"]:
                keys = per_doel.get(doel_id, [])
                # de waarde komt op de lid-relatie als de kolomtitels gelijk zijn (tabel 4.179: 'vrije doorgang: doorgang'),
                # of als dit de enige waardekolom voor dit lid is en er precies één lid-relatie is; anders (tabel 3.30:
                # drie brandklassen per lid) een eigen relatie per waardekolom
                match = [kc for kc in keys if kol[kc]["titel"] == k["titel"] and "grenswaarde" not in m.rels[(rij_id, "STUURT_AAN", doel_id, kc)]]
                if not match and waarden_per_doel[doel_id] == 1:
                    match = [kc for kc in keys if "grenswaarde" not in m.rels[(rij_id, "STUURT_AAN", doel_id, kc)]]
                    if len(match) != 1:
                        match = []
                props = dict(grenswaarde=t, eenheid=k["eenheid"], waardekolomnr=c, waardekolomtitel=k["titel"])
                g = getal(t)
                if g is not None:
                    props["grenswaarde_num"] = g
                if match:
                    m.rel(rij_id, "STUURT_AAN", doel_id, key=match[0], **props)
                else:
                    if not keys:
                        props["zonder_lidcel"] = True
                    props.update(kolomnr=c, kolomtitel=k["titel"], lid_kop=k["lid"] or "*", cel=t, tabel=tnr)
                    m.rel(rij_id, "STUURT_AAN", doel_id, key=c, **props)
    art_node.setdefault("gebruiksfuncties", [])
    for g in gf_in_tabel:
        if g not in art_node["gebruiksfuncties"]:
            art_node["gebruiksfuncties"].append(g)
    m.gebruiksfuncties = getattr(m, "gebruiksfuncties", Counter())
    m.gebruiksfuncties.update(gf_in_tabel)
    m.tabel_stats["rijen"] += len(rijen)


# --------------------------------------------------------------------------- graph

def existing_state(session, toestand):
    nodes = {}
    for label in ("LegalFramework", "FrameworkSet", "Framework", "Gebruiksfunctierij"):
        for rec in session.run(f"MATCH (n:{label} {{src: $src, version: $v}}) RETURN n.id AS id, properties(n) AS p",
                               src=SRC, v=toestand):
            nodes[rec["id"]] = dict(label=label, props=rec["p"])
    # de LegalFramework-node is toestand-onafhankelijk
    for rec in session.run("MATCH (n:LegalFramework {id: 'legalframework-bbl'}) RETURN n.id AS id, properties(n) AS p"):
        nodes.setdefault(rec["id"], dict(label="LegalFramework", props=rec["p"]))
    rels = {}
    for la, typ in (("LegalFramework", "HAS_FRAMEWORKSET"), ("FrameworkSet", "HAS_FRAMEWORK"), ("Framework", "HAS_FRAMEWORK"),
                    ("Framework", "HAS_GEBRUIKSFUNCTIERIJ"), ("Gebruiksfunctierij", "STUURT_AAN")):
        q = (f"MATCH (a:{la} {{src: $src}})-[r:{typ}]->(b {{src: $src, version: $v}}) "
             "WHERE a.version = $v OR a:LegalFramework "
             "RETURN a.id AS a, type(r) AS t, b.id AS b, properties(r) AS p")
        for rec in session.run(q, src=SRC, v=toestand):
            key = rec["p"].get("kolomnr") if rec["t"] == "STUURT_AAN" else None
            rels[(rec["a"], rec["t"], rec["b"], key)] = rec["p"]
    return nodes, rels


VOLATIEL = {"created_at", "createdon", "createdby", "updated_at", "updatedon", "updatedby"}


def diff(model, ex_nodes, ex_rels):
    nieuw, gewijzigd, zelfde = [], [], 0
    for id_, n in model.nodes.items():
        e = ex_nodes.get(id_)
        if e is None:
            nieuw.append(id_)
        else:
            a = {k: v for k, v in e["props"].items() if k not in VOLATIEL}
            if a != n["props"]:
                gewijzigd.append(id_)
            else:
                zelfde += 1
    verweesd = [id_ for id_ in ex_nodes if id_ not in model.nodes]
    r_nieuw, r_gewijzigd, r_zelfde = [], [], 0
    for k, p in model.rels.items():
        e = ex_rels.get(k)
        if e is None:
            r_nieuw.append(k)
        elif e != p:
            r_gewijzigd.append(k)
        else:
            r_zelfde += 1
    r_verweesd = [k for k in ex_rels if k not in model.rels]
    return dict(nieuw=nieuw, gewijzigd=gewijzigd, zelfde=zelfde, verweesd=verweesd,
                r_nieuw=r_nieuw, r_gewijzigd=r_gewijzigd, r_zelfde=r_zelfde, r_verweesd=r_verweesd)


def apply(session, model, d, prune, department_bfguid):
    now = dt.datetime.now().strftime("%Y%m%d.%H%M%S")
    for label in ("LegalFramework", "FrameworkSet", "Framework", "Gebruiksfunctierij"):
        session.run(f"CREATE INDEX bbl_{label.lower()}_id IF NOT EXISTS FOR (n:{label}) ON (n.id)")
    todo = d["nieuw"] + d["gewijzigd"]
    by_label = {}
    for id_ in todo:
        n = model.nodes[id_]
        by_label.setdefault(n["label"], []).append(dict(id=id_, props=n["props"]))
    for label, rows in by_label.items():
        for i in range(0, len(rows), 500):
            session.run(
                f"UNWIND $rows AS row MERGE (n:{label} {{id: row.id}}) "
                "WITH n, row, n.created_at AS ca, n.createdon AS co, n.createdby AS cb "
                "SET n = row.props "
                "SET n.created_at = coalesce(ca, datetime()), n.createdon = coalesce(co, $now), n.createdby = coalesce(cb, 'agent-coding')",
                rows=rows[i:i + 500], now=now)
    # verwijderde properties bij gewijzigde nodes: `n = props + {...}` vervangt alles, dus al afgedekt
    # labels in de MATCH, anders gebruikt Neo4j de id-index niet en scant hij per relatie de hele store
    groepen = {}
    for k in d["r_nieuw"] + d["r_gewijzigd"]:
        la, lb = model.nodes[k[0]]["label"], model.nodes[k[2]]["label"]
        groepen.setdefault((k[1], la, lb), []).append(dict(a=k[0], b=k[2], key=k[3], props=model.rels[k]))
    for (typ, la, lb), rows in groepen.items():
        for i in range(0, len(rows), 1000):
            if typ == "STUURT_AAN":
                session.run(
                    f"UNWIND $rows AS row MATCH (a:{la} {{id: row.a}}), (b:{lb} {{id: row.b}}) "
                    "MERGE (a)-[r:STUURT_AAN {kolomnr: row.key}]->(b) SET r = row.props",
                    rows=rows[i:i + 1000])
            else:
                session.run(
                    f"UNWIND $rows AS row MATCH (a:{la} {{id: row.a}}), (b:{lb} {{id: row.b}}) "
                    f"MERGE (a)-[r:{typ}]->(b) SET r = row.props",
                    rows=rows[i:i + 1000])
    # verwijzing vanuit de Frameworks-container van het department
    rec = session.run(
        "MATCH (d:Department {bfguid: $dep})-[:HAS_FRAMEWORKS]->(f:Frameworks) "
        "MATCH (lf:LegalFramework {id: $lf}) MERGE (f)-[:HAS_LEGALFRAMEWORK]->(lf) RETURN f.bfguid AS f",
        dep=department_bfguid, lf=model.legalframework_id).single()
    if rec is None:
        print(f"LET OP: geen Frameworks-container gevonden voor Department {department_bfguid}; LegalFramework hangt los")
    if prune:
        for k in d["r_verweesd"]:
            if k[1] == "STUURT_AAN":
                session.run("MATCH (a:Gebruiksfunctierij {id: $a})-[r:STUURT_AAN {kolomnr: $key}]->(b:Framework {id: $b}) DELETE r",
                            a=k[0], b=k[2], key=k[3])
            else:
                session.run(f"MATCH (a {{id: $a, src: $src}})-[r:{k[1]}]->(b {{id: $b, src: $src}}) DELETE r", a=k[0], b=k[2], src=SRC)
        for label in ("Framework", "Gebruiksfunctierij", "FrameworkSet"):
            session.run(f"UNWIND $ids AS id MATCH (n:{label} {{id: id, src: $src}}) DETACH DELETE n", ids=d["verweesd"], src=SRC)


# --------------------------------------------------------------------------- validatie

def validate(session, model):
    v = model.toestand
    out = OrderedDict()
    rec = session.run(
        "MATCH (f:Framework {src: $src, version: $v}) RETURN f.niveau AS niveau, count(*) AS n", src=SRC, v=v)
    out["tellingen_graph"] = {r["niveau"]: r["n"] for r in rec}
    out["tellingen_xml"] = dict(model.counts)
    out["tellingen_gelijk"] = all(out["tellingen_graph"].get(k) == model.counts.get(k) for k in NIVEAUS)
    out["aansturingstabellen_h4_graph"] = session.run(
        "MATCH (a:Framework {src: $src, version: $v, niveau: 'artikel', hoofdstuk: '4'})-[:HAS_GEBRUIKSFUNCTIERIJ]->() "
        "RETURN count(DISTINCT a) AS n", src=SRC, v=v).single()["n"]
    out["artikelen_met_tabel_h4_graph"] = session.run(
        "MATCH (a:Framework {src: $src, version: $v, niveau: 'artikel', hoofdstuk: '4'}) WHERE a.heeft_tabel OR "
        "EXISTS { MATCH (a)-[:HAS_FRAMEWORK]->(l:Framework) WHERE l.heeft_tabel } RETURN count(a) AS n", src=SRC, v=v).single()["n"]
    out["rijen_graph"] = session.run("MATCH (r:Gebruiksfunctierij {src: $src, version: $v}) RETURN count(r) AS n", src=SRC, v=v).single()["n"]
    out["stuurt_aan_graph"] = session.run(
        "MATCH (:Gebruiksfunctierij {src: $src, version: $v})-[r:STUURT_AAN]->() RETURN count(r) AS n", src=SRC, v=v).single()["n"]

    def steekproef(tabel, gf, sub=None):
        q = ("MATCH (r:Gebruiksfunctierij {src: $src, version: $v, tabel: $t, gebruiksfunctie: $gf})"
             "-[s:STUURT_AAN]->(f:Framework) "
             "WHERE ($sub IS NULL AND r.subcategorie IS NULL) OR r.subcategorie = $sub "
             "RETURN f.name AS doel, s.kolomtitel AS kolom, s.grenswaarde AS grenswaarde, s.eenheid AS eenheid "
             "ORDER BY f.nummer, s.kolomnr")
        return [dict(r) for r in session.run(q, src=SRC, v=v, t=tabel, gf=gf, sub=sub)]

    out["steekproef_4.179_onderwijsfunctie"] = steekproef("4.179", "Onderwijsfunctie")
    out["steekproef_4.162_rijen"] = [dict(r) for r in session.run(
        "MATCH (r:Gebruiksfunctierij {src: $src, version: $v, tabel: '4.162'}) RETURN r.code AS code, "
        "r.gebruiksfunctie AS gf, r.subcategorie AS sub ORDER BY r.volgorde", src=SRC, v=v)]
    out["steekproef_4.162_andere_woonfunctie"] = steekproef("4.162", "Woonfunctie", "andere woonfunctie")
    # gebruiksfuncties tegen de PropertyTemplate-constraint uit quest-035
    gf_graph = [r["g"] for r in session.run(
        "MATCH (r:Gebruiksfunctierij {src: $src, version: $v}) RETURN DISTINCT r.gebruiksfunctie AS g ORDER BY g", src=SRC, v=v)]
    out["gebruiksfuncties_in_tabellen"] = gf_graph
    out["gebruiksfuncties_niet_in_bbl_lijst"] = sorted(set(gf_graph) - set(GEBRUIKSFUNCTIES_BBL))
    pt = [dict(r) for r in session.run(
        "MATCH (pt:PropertyTemplate) WHERE toLower(pt.name) = 'gebruiksfunctie' "
        "OPTIONAL MATCH (pt)-[:HAS_VALUE]->(val:Value) "
        "RETURN pt.bfguid AS bfguid, pt.src AS src, pt.version AS version, pt.enumeration AS pt_enum, "
        "val.enumeration AS val_enum, val.value AS val_value")]
    out["propertytemplate_gebruiksfunctie"] = pt
    enum = []
    for p in pt:
        for e in (p.get("pt_enum"), p.get("val_enum")):
            if isinstance(e, list):
                enum.extend(e)
            elif isinstance(e, str) and e:
                enum.extend(x.strip() for x in re.split(r"[;,|]", e) if x.strip())
    out["constraint_quest035_waarden"] = sorted(set(enum))
    if enum:
        out["constraint_quest035_verschil"] = dict(
            alleen_in_bbl=sorted(set(GEBRUIKSFUNCTIES_BBL) - {e for e in enum}),
            alleen_in_constraint=sorted({e for e in enum} - set(GEBRUIKSFUNCTIES_BBL)))
    else:
        out["constraint_quest035_verschil"] = "geen enumeratie gevonden op de PropertyTemplate Gebruiksfunctie (Value.value leeg, geen enumeration)"
    return out


# --------------------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("xml", help="BWB-toestand XML (bv. bron/BWBR0041297_2026-09-24/BWBR0041297_2026-09-24_0.xml)")
    ap.add_argument("--server", default="neo4j-leja")
    ap.add_argument("--department-bfguid", default=DEFAULT_DEPARTMENT_BFGUID,
                    help="Department waarvan de Frameworks-container de LegalFramework krijgt (default: sandbox ZGEM/Technisch Beheer)")
    ap.add_argument("--dry-run", action="store_true", help="alleen parsen: telling, afwijkingen, optioneel --dump")
    ap.add_argument("--dump", help="schrijf het geparste model als JSON naar dit pad")
    ap.add_argument("--validate", action="store_true", help="na de import (of los) tellingen en steekproeven tegen de graph")
    ap.add_argument("--prune", action="store_true", help="verwijder nodes/relaties van deze toestand die niet meer in de XML staan")
    ap.add_argument("--no-write", action="store_true", help="wel verbinden en de diff tonen, niets schrijven")
    a = ap.parse_args()

    model = parse(a.xml, a.department_bfguid)
    print(f"toestand {model.toestand}: " + ", ".join(f"{k} {model.counts[k]}" for k in NIVEAUS))
    print(f"nodes {len(model.nodes)} (LegalFramework 1, FrameworkSet 1, Framework "
          f"{sum(1 for n in model.nodes.values() if n['label'] == 'Framework')}, Gebruiksfunctierij "
          f"{sum(1 for n in model.nodes.values() if n['label'] == 'Gebruiksfunctierij')}), relaties {len(model.rels)} "
          f"(STUURT_AAN {sum(1 for k in model.rels if k[1] == 'STUURT_AAN')})")
    print("tabellen: " + ", ".join(f"{k} {v}" for k, v in sorted(model.tabel_stats.items())))
    print(f"gebruiksfuncties in tabellen: {sorted(getattr(model, 'gebruiksfuncties', Counter()))}")
    if model.afwijkingen:
        print(f"\nafwijkingen ({len(model.afwijkingen)}):")
        for x in model.afwijkingen:
            print("  - " + x)
    if a.dump:
        with open(a.dump, "w", encoding="utf-8") as fh:
            json.dump(dict(toestand=model.toestand, tellingen=dict(model.counts), tabellen=dict(model.tabel_stats),
                           afwijkingen=model.afwijkingen,
                           nodes=[dict(label=n["label"], **n["props"]) for n in model.nodes.values()],
                           relaties=[dict(van=k[0], type=k[1], naar=k[2], **p) for k, p in model.rels.items()]),
                      fh, ensure_ascii=False, indent=1)
        print(f"dump: {a.dump}")
    if a.dry_run:
        return

    from neo4j import GraphDatabase
    url, user, pw, db = load_conn(a.server)
    print(f"\nserver {a.server} -> {url} (db {db}, user {user})")
    with GraphDatabase.driver(url, auth=(user, pw)) as drv:
        with drv.session(database=db) as s:
            ex_nodes, ex_rels = existing_state(s, model.toestand)
            d = diff(model, ex_nodes, ex_rels)
            print(f"bestaand: {len(ex_nodes)} nodes, {len(ex_rels)} relaties")
            print(f"nodes: {len(d['nieuw'])} nieuw, {len(d['gewijzigd'])} gewijzigd, {d['zelfde']} ongewijzigd, {len(d['verweesd'])} verweesd")
            print(f"relaties: {len(d['r_nieuw'])} nieuw, {len(d['r_gewijzigd'])} gewijzigd, {d['r_zelfde']} ongewijzigd, {len(d['r_verweesd'])} verweesd")
            if d["gewijzigd"][:5]:
                print("  gewijzigd bv.: " + ", ".join(d["gewijzigd"][:5]))
            if d["verweesd"][:5]:
                print("  verweesd bv.: " + ", ".join(d["verweesd"][:5]) + ("" if a.prune else "  (--prune om te verwijderen)"))
            if not a.no_write and (d["nieuw"] or d["gewijzigd"] or d["r_nieuw"] or d["r_gewijzigd"] or (a.prune and (d["verweesd"] or d["r_verweesd"]))):
                apply(s, model, d, a.prune, a.department_bfguid)
                print("geschreven.")
            elif not a.no_write:
                # ook bij nul wijzigingen de containerkoppeling zekerstellen (idempotent)
                apply(s, model, dict(nieuw=[], gewijzigd=[], r_nieuw=[], r_gewijzigd=[], verweesd=[], r_verweesd=[]), False, a.department_bfguid)
                print("niets te schrijven.")
            if a.validate:
                print("\nvalidatie:")
                print(json.dumps(validate(s, model), ensure_ascii=False, indent=1, default=str))


if __name__ == "__main__":
    main()
