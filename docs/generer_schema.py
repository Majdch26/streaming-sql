"""Génère le schéma relationnel (docs/schema.svg et docs/schema.drawio)
à partir d'une description des tables. Lancer : python3 docs/generer_schema.py"""

from pathlib import Path
from xml.sax.saxutils import escape

LARGEUR, LIGNE, TITRE = 210, 24, 30
COLONNES = {"A": 30, "B": 330, "C": 630, "D": 930}

# (nom, colonne, y, [(marque, champ)], couleur d'en-tête)
TABLES = [
    ("utilisateur", "A", 30, [("PK", "id"), ("", "nom"), ("UQ", "email"), ("", "mot_de_passe_hash"),
                               ("", "sel"), ("", "date_creation")], "#dae8fc"),
    ("abonnement", "A", 260, [("PK", "id"), ("FK", "id_utilisateur"), ("FK", "id_offre"), ("", "date_debut"),
                              ("", "date_fin"), ("", "prix_mensuel")], "#dae8fc"),
    ("offre", "A", 490, [("PK", "id"), ("UQ", "nom"), ("", "prix_mensuel"), ("", "nb_profils_max"),
                         ("", "qualite_max"), ("", "disponible")], "#dae8fc"),
    ("profils", "B", 60, [("PK", "id"), ("FK", "id_utilisateur"), ("", "nom"), ("", "age"), ("", "avatar")], "#d5e8d4"),
    ("favoris", "B", 250, [("PK,FK", "id_profil"), ("PK,FK", "id_video"), ("", "date_ajout")], "#d5e8d4"),
    ("video", "C", 30, [("PK", "id"), ("", "titre"), ("", "type"), ("", "description"), ("", "date_publication"),
                        ("", "langue_originale"), ("", "image"), ("", "age_minimum")], "#ffe6cc"),
    ("video_categorie", "C", 290, [("PK,FK", "id_video"), ("PK,FK", "id_categorie")], "#ffe6cc"),
    ("categorie", "C", 410, [("PK", "id"), ("UQ", "nom")], "#ffe6cc"),
    ("visionnage", "C", 530, [("PK", "id"), ("FK", "id_profil"), ("FK", "id_film"), ("FK", "id_episode"),
                              ("", "date_visionnage"), ("", "minutes_vues")], "#d5e8d4"),
    ("film", "D", 30, [("PK,FK", "id_video"), ("", "duree"), ("UQ", "url_video")], "#ffe6cc"),
    ("serie", "D", 170, [("PK,FK", "id_video"), ("", "terminee")], "#ffe6cc"),
    ("episode", "D", 290, [("PK", "id"), ("FK", "id_serie"), ("", "numero_saison"), ("", "numero_episode"),
                           ("", "titre"), ("", "description"), ("", "duree"), ("UQ", "url_video"),
                           ("", "image_episode")], "#ffe6cc"),
    ("soustitre", "D", 600, [("PK", "id"), ("FK", "id_film"), ("FK", "id_episode"), ("", "langue"),
                             ("UQ", "url_fichier")], "#ffe6cc"),
]

# (table, champ, table cible, champ cible, x du couloir vertical)
LIENS = [
    ("abonnement", "id_utilisateur", "utilisateur", "id", 18),
    ("abonnement", "id_offre", "offre", "id", 10),
    ("profils", "id_utilisateur", "utilisateur", "id", 280),
    ("favoris", "id_profil", "profils", "id", 300),
    ("visionnage", "id_profil", "profils", "id", 310),
    ("favoris", "id_video", "video", "id", 580),
    ("video_categorie", "id_video", "video", "id", 618),
    ("video_categorie", "id_categorie", "categorie", "id", 610),
    ("film", "id_video", "video", "id", 880),
    ("serie", "id_video", "video", "id", 890),
    ("visionnage", "id_film", "film", "id_video", 900),
    ("visionnage", "id_episode", "episode", "id", 910),
    ("episode", "id_serie", "serie", "id_video", 918),
    ("soustitre", "id_film", "film", "id_video", 1160),
    ("soustitre", "id_episode", "episode", "id", 1170),
]

positions = {}
for nom, col, y, champs, _ in TABLES:
    x = COLONNES[col]
    for i, (_, champ) in enumerate(champs):
        positions[(nom, champ)] = (x, y + TITRE + i * LIGNE + LIGNE / 2)
    positions[nom] = (x, y, len(champs))


# Une ligne qui est à la fois source et cible d'un lien : on décale
# la sortie vers le bas et l'entrée vers le haut pour ne pas confondre les traits.
SOURCES = {(s, c) for s, c, _, _, _ in LIENS}
CIBLES = {(d, c) for _, _, d, c, _ in LIENS}
DECALAGE = 5


def trajet(src, champ, dst, champ_dst, couloir):
    xs, ys = positions[(src, champ)]
    xd, yd = positions[(dst, champ_dst)]
    if (src, champ) in CIBLES:
        ys += DECALAGE
    if (dst, champ_dst) in SOURCES:
        yd -= DECALAGE
    sort_gauche = couloir < xs
    entre_gauche = couloir < xd
    x1 = xs if sort_gauche else xs + LARGEUR
    x2 = xd if entre_gauche else xd + LARGEUR
    return [(x1, ys), (couloir, ys), (couloir, yd), (x2, yd)], sort_gauche, entre_gauche


# ---------- SVG ----------
largeur_svg = COLONNES["D"] + LARGEUR + 60
hauteur_svg = max(y + TITRE + len(c) * LIGNE for _, _, y, c, _ in TABLES) + 40
svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{largeur_svg}" height="{hauteur_svg}" '
       f'viewBox="0 0 {largeur_svg} {hauteur_svg}" font-family="Helvetica, Arial, sans-serif" font-size="13">',
       '<defs><marker id="fleche" viewBox="0 0 10 10" refX="10" refY="5" markerWidth="8" markerHeight="8" '
       'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#555"/></marker></defs>',
       f'<rect width="{largeur_svg}" height="{hauteur_svg}" fill="#ffffff"/>']

for src, champ, dst, champ_dst, couloir in LIENS:
    pts, _, _ = trajet(src, champ, dst, champ_dst, couloir)
    d = " ".join(f"{x},{y}" for x, y in pts)
    svg.append(f'<polyline points="{d}" fill="none" stroke="#555" stroke-width="1.3" marker-end="url(#fleche)"/>')

for nom, col, y, champs, couleur in TABLES:
    x = COLONNES[col]
    h = TITRE + len(champs) * LIGNE
    svg.append(f'<rect x="{x}" y="{y}" width="{LARGEUR}" height="{h}" fill="#fff" stroke="#333" stroke-width="1.2"/>')
    svg.append(f'<rect x="{x}" y="{y}" width="{LARGEUR}" height="{TITRE}" fill="{couleur}" stroke="#333" stroke-width="1.2"/>')
    svg.append(f'<text x="{x + LARGEUR / 2}" y="{y + 20}" text-anchor="middle" font-weight="bold">{escape(nom)}</text>')
    svg.append(f'<line x1="{x + 46}" y1="{y + TITRE}" x2="{x + 46}" y2="{y + h}" stroke="#ccc"/>')
    for i, (marque, champ) in enumerate(champs):
        ty = y + TITRE + i * LIGNE + 16
        poids = ' font-weight="bold"' if "PK" in marque else ""
        souligne = ' text-decoration="underline"' if "PK" in marque else ""
        svg.append(f'<text x="{x + 6}" y="{ty}" font-size="10" fill="#666">{marque}</text>')
        svg.append(f'<text x="{x + 54}" y="{ty}"{poids}{souligne}>{escape(champ)}</text>')

svg.append("</svg>")
Path(__file__).with_name("schema.svg").write_text("\n".join(svg), encoding="utf-8")

# ---------- draw.io ----------
cellules = ['<mxCell id="0"/>', '<mxCell id="1" parent="0"/>']
for nom, col, y, champs, couleur in TABLES:
    x = COLONNES[col]
    h = TITRE + len(champs) * LIGNE
    cellules.append(
        f'<mxCell id="{nom}" value="{nom}" style="shape=table;startSize={TITRE};container=1;collapsible=1;'
        f'childLayout=tableLayout;fixedRows=1;rowLines=0;fontStyle=1;align=center;resizeLast=1;html=1;'
        f'fillColor={couleur};" vertex="1" parent="1"><mxGeometry x="{x}" y="{y}" width="{LARGEUR}" '
        f'height="{h}" as="geometry"/></mxCell>')
    for i, (marque, champ) in enumerate(champs):
        rid = f"{nom}.{champ}"
        style_champ = "fontStyle=5;" if "PK" in marque else ""
        cellules.append(
            f'<mxCell id="{rid}" value="" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;'
            f'swimlaneBody=0;fillColor=none;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];'
            f'portConstraint=eastwest;top=0;left=0;right=0;bottom={1 if i == 0 else 0};" vertex="1" '
            f'parent="{nom}"><mxGeometry y="{TITRE + i * LIGNE}" width="{LARGEUR}" height="{LIGNE}" '
            f'as="geometry"/></mxCell>')
        cellules.append(
            f'<mxCell id="{rid}.m" value="{marque}" style="shape=partialRectangle;connectable=0;fillColor=none;'
            f'top=0;left=0;bottom=0;right=0;fontStyle=1;overflow=hidden;html=1;fontSize=10;" vertex="1" '
            f'parent="{rid}"><mxGeometry width="46" height="{LIGNE}" as="geometry"/></mxCell>')
        cellules.append(
            f'<mxCell id="{rid}.n" value="{champ}" style="shape=partialRectangle;connectable=0;fillColor=none;'
            f'top=0;left=0;bottom=0;right=0;align=left;spacingLeft=6;overflow=hidden;html=1;{style_champ}" '
            f'vertex="1" parent="{rid}"><mxGeometry x="46" width="{LARGEUR - 46}" height="{LIGNE}" '
            f'as="geometry"/></mxCell>')

for k, (src, champ, dst, champ_dst, couloir) in enumerate(LIENS):
    pts, sort_gauche, entre_gauche = trajet(src, champ, dst, champ_dst, couloir)
    points = "".join(f'<mxPoint x="{x}" y="{y}"/>' for x, y in pts[1:3])
    cellules.append(
        f'<mxCell id="lien{k}" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;'
        f'exitX={0 if sort_gauche else 1};exitY={0.5 + (DECALAGE / LIGNE if (src, champ) in CIBLES else 0):.3f};'
        f'exitDx=0;exitDy=0;entryX={0 if entre_gauche else 1};'
        f'entryY={0.5 - (DECALAGE / LIGNE if (dst, champ_dst) in SOURCES else 0):.3f};entryDx=0;entryDy=0;" '
        f'edge="1" parent="1" '
        f'source="{src}.{champ}" target="{dst}.{champ_dst}"><mxGeometry relative="1" as="geometry">'
        f'<Array as="points">{points}</Array></mxGeometry></mxCell>')

drawio = ('<mxfile host="app.diagrams.net"><diagram name="Schéma relationnel" id="schema">'
          f'<mxGraphModel dx="1400" dy="900" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" '
          f'arrows="1" fold="1" page="1" pageScale="1" pageWidth="{largeur_svg}" pageHeight="{hauteur_svg}" '
          f'math="0" shadow="0"><root>' + "\n".join(cellules) + '</root></mxGraphModel></diagram></mxfile>\n')
Path(__file__).with_name("schema.drawio").write_text(drawio, encoding="utf-8")
print("docs/schema.svg et docs/schema.drawio générés")
