"""Design-stage sketches for 「數數小農場」 (number sense and early maths on a little Taiwanese farm, ages 3-6).

    python3 make_mockups.py          # writes docs/mockups/*.png (needs Node.js + Playwright's Chromium)
    python3 make_mockups.py 3        # only one page: 0 = style page, 1..9 = a screen, c = contact sheet

Every picture is drawn here as SVG by code: no outside pictures, no emoji. Words and numerals use the font
jf open 粉圓 2.1, taken from a sibling app's checkout. render.js turns each page into a PNG with Playwright's
Chromium at 390x844, device scale 2.

    0_畫風選擇.png     the same farm corner (coop, hen, three chicks, an egg tray, a guava tree, a number tile)
                       in three styles: A 木頭玩具風 (recommended), B 摺紙風, C 木刻版畫風. Screens 1-9 are drawn in A.
    1_農場.png         home: the farm with six places, the guide 牛牛 (a little water buffalo with a bamboo hat)
    2_餵小雞.png       one corn for each chick: one-to-one counting, the number tiles light up 1 2 3
    3_撿雞蛋.png       pack 7 eggs for 阿嬤: the egg tray is a ten-frame (two rows of five)
    4_摘水果.png       the sheep wants 4 guavas: a numeral with dots, pick them into the basket
    5_分點心.png       share six sweet potatoes between three piglets, one each in turn
    6_排排隊.png       the vegetable row pattern 高麗菜 紅蘿蔔 高麗菜 紅蘿蔔 ...: what comes next?
    7_去市場.png       (5-6) the little blue truck: 3 watermelons and 2 more, the truck bed is a ten-frame
    8_休息.png         the farm at dusk: 「換你去做了！」 and a 回真實生活 card (count the spoons at dinner)
    9_家長模式.png     parents' settings and what the child has played with
    contact_sheet.png  screens 1-9 small, with titles

All three styles use only what a flutter_svg file can draw (paths, linear/radial gradients, clipPath, opacity,
transforms; no filter, mask, pattern, style, text or image element):
「木頭玩具風」 (wood): each piece is a painted wooden cut-out. A darker copy of the shape moved 3 px down is the
sawn edge (the thickness); the face has a faint top-to-bottom gradient; a few thin wavy grain lines and a
bevel (the outline stroked again, moved 1 px, light on the top left and dark on the bottom right) are clipped
to the shape; a soft shadow is the shape again in translucent brown.
「摺紙風」 (origami): every shape is a polygon (circles become octagons). The fill is a gradient with a hard stop in
the middle, so one half is the lit side of a fold and the other half the shaded side; a thin light crease
line is clipped along the fold.
「木刻版畫風」 (woodcut): flat ink on cream paper; inside each shape a few paper-coloured slivers (thin
four-point polygons, all leaning the same way) are clipped in, like the marks of a carving gouge; a darker
ink edge.
"""
import hashlib
import math
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
FONT = next(iter(sorted(pathlib.Path("/home/user").glob("app_kids_*/app/assets/fonts/jf-openhuninn-2.1.ttf"))), None)
if FONT is None:
    sys.exit("font jf-openhuninn-2.1.ttf not found in a sibling app's checkout")
SCRATCH = pathlib.Path("/dev/shm") if pathlib.Path("/dev/shm").is_dir() else pathlib.Path(tempfile.gettempdir())
W, H = 390, 844

# ---------------------------------------------------------------- colours
INK = "#4B3A2C"
SOFT = "#8C7867"
CREAM = "#FFF8EA"
WHITE = "#FFFDF8"
SKY = "#CFE8F5"
GRASS = "#A9D47E"
SOIL = "#C99A68"
WOOD = "#EBCB9C"
WOOD2 = "#D9AE77"
WALNUT = "#9B6B45"
RED = "#E0604F"
YEL = "#F6C640"
ORA = "#F0914A"
BLUE = "#4E8FD6"
GRN = "#6DB65B"
PINK = "#F2A7B8"
TEAL = "#4FB8A8"
LILAC = "#B29CDB"
CHICK = "#FFD34A"
EGG = "#FFF0D2"
GUAVA = "#A6D46A"
PIG = "#F5B2BE"
POTATO = "#B5566E"
MELON = "#3E9650"
BUFF = "#9A95A3"
HAT = "#E8C77E"
CABBAGE = "#9ED07A"
CARROT = "#F08A3C"
DARK = "#3A2C26"
CHEEK = "#FFA8B4"
SKIN = "#FBE0CB"
GREY = "#D9D2C8"
PAPER = {"wood": "#F7EEDC", "origami": "#F3EEE6", "woodcut": "#F6EDD9"}
STYLE = "wood"       # A 木頭玩具風 (recommended). The other two candidates: "origami" (B) and "woodcut" (C)


# ---------------------------------------------------------------- defs registry and small maths
class Defs:
    def __init__(self):
        self.d = {}

    def add(self, key, svg):
        self.d.setdefault(key, svg)
        return key

    def svg(self):
        return "<defs>" + "".join(self.d.values()) + "</defs>"


D = Defs()


def _h(*parts):
    return hashlib.md5("|".join(map(str, parts)).encode()).hexdigest()[:10]


def _rand(seed, i):
    return int(hashlib.md5(f"{seed}|{i}".encode()).hexdigest()[:6], 16) / 0xFFFFFF


def _rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mixc(a, b, t):
    ra, rb = _rgb(a), _rgb(b)
    return "#%02X%02X%02X" % tuple(round(ra[i] + (rb[i] - ra[i]) * t) for i in range(3))


def darker(c, t=.25):
    return mixc(c, "#2A1A10", t)


def lighter(c, t=.35):
    return mixc(c, "#FFFFFF", t)


def lg(stops, x1=0, y1=0, x2=0, y2=1):
    k = "lg" + _h(stops, x1, y1, x2, y2)
    D.add(k, f'<linearGradient id="{k}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">' + "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops) + "</linearGradient>")
    return f"url(#{k})"


def rg(stops):
    k = "rg" + _h(stops)
    D.add(k, f'<radialGradient id="{k}">' + "".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops) + "</radialGradient>")
    return f"url(#{k})"


# ---------------------------------------------------------------- shapes: a path string with its bounding box
class Sh:
    def __init__(self, d, b):
        self.d, self.b = d, b


def poly(pts):
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return Sh("M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + "Z", (min(xs), min(ys), max(xs), max(ys)))


def npoly(cx, cy, rx, ry, n=8, rot=22.5):
    return poly([(cx + rx * math.cos(math.radians(rot + i * 360 / n)), cy + ry * math.sin(math.radians(rot + i * 360 / n))) for i in range(n)])


def rr(x, y, w, h, r=6):
    r = min(r, w / 2, h / 2)
    if STYLE == "origami":
        c = r * .8
        return poly([(x + c, y), (x + w - c, y), (x + w, y + c), (x + w, y + h - c), (x + w - c, y + h), (x + c, y + h), (x, y + h - c), (x, y + c)])
    d = (f"M{x + r:.1f},{y:.1f} h{w - 2 * r:.1f} a{r},{r} 0 0 1 {r},{r} v{h - 2 * r:.1f} a{r},{r} 0 0 1 {-r},{r} "
         f"h{-(w - 2 * r):.1f} a{r},{r} 0 0 1 {-r},{-r} v{-(h - 2 * r):.1f} a{r},{r} 0 0 1 {r},{-r}Z")
    return Sh(d, (x, y, x + w, y + h))


def circ(cx, cy, r):
    if STYLE == "origami":
        return npoly(cx, cy, r, r, 8 if r > 6 else 6)
    return Sh(f"M{cx - r:.1f},{cy:.1f} a{r},{r} 0 1 0 {2 * r},0 a{r},{r} 0 1 0 {-2 * r},0Z", (cx - r, cy - r, cx + r, cy + r))


def ell(cx, cy, rx, ry):
    if STYLE == "origami":
        return npoly(cx, cy, rx, ry, 8 if max(rx, ry) > 6 else 6)
    return Sh(f"M{cx - rx:.1f},{cy:.1f} a{rx},{ry} 0 1 0 {2 * rx},0 a{rx},{ry} 0 1 0 {-2 * rx},0Z", (cx - rx, cy - ry, cx + rx, cy + ry))


def smooth(pts, closed=True):
    """A closed smooth curve through points (Catmull-Rom as cubic beziers); straight edges in origami."""
    if STYLE == "origami" and closed:
        return poly(pts[::2] if len(pts) > 12 else pts)
    n = len(pts)
    out = [f"M{pts[0][0]:.1f},{pts[0][1]:.1f}"]
    for i in (range(n) if closed else range(n - 1)):
        p0, p1, p2, p3 = pts[(i - 1) % n], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        if not closed:
            p0, p3 = pts[max(i - 1, 0)], pts[min(i + 2, n - 1)]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        out.append(f"C{c1[0]:.1f},{c1[1]:.1f} {c2[0]:.1f},{c2[1]:.1f} {p2[0]:.1f},{p2[1]:.1f}")
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return Sh(" ".join(out) + ("Z" if closed else ""), (min(xs), min(ys), max(xs), max(ys)))


def blob(cx, cy, rx, ry, bumps=7, amp=.09, seed=0):
    pts = []
    for i in range(bumps * 2):
        a = 2 * math.pi * i / (bumps * 2)
        k = 1 + (amp if i % 2 == 0 else -amp * .4) + (_rand(seed, i) - .5) * .05
        pts.append((cx + rx * k * math.cos(a), cy + ry * k * math.sin(a)))
    return smooth(pts)


def _clip(sh):
    k = "cp" + _h(sh.d)
    D.add(k, f'<clipPath id="{k}"><path d="{sh.d}"/></clipPath>')
    return k


# ---------------------------------------------------------------- the three ways to draw one solid piece
def wood_piece(sh, col, shade=1, thick=True, extra=""):
    """木頭玩具: a painted wooden cut-out with a sawn edge, grain and a soft bevel."""
    x0, y0, x1, y1 = sh.b
    w, h = max(1, x1 - x0), max(1, y1 - y0)
    k = _clip(sh)
    o = []
    if shade:
        o.append(f'<path d="{sh.d}" fill="#5A3A1E" opacity=".13" transform="translate(2 {3 + 2.5 * shade})"{extra}/>')
    if thick:
        o.append(f'<path d="{sh.d}" fill="{darker(col, .32)}" transform="translate(0 3.6)"{extra}/>')
    o.append(f'<path d="{sh.d}" fill="{lg([(0, lighter(col, .1)), (1, darker(col, .05))])}"{extra}/>')
    g = [f'<g clip-path="url(#{k})"{extra}>']
    n = max(2, min(7, int(h / 10)))
    for i in range(n):
        y = y0 + (i + .5) * h / n + (_rand(sh.d, i) - .5) * 3
        a = 1.5 + _rand(sh.d, i + 9) * 2.5
        g.append(f'<path d="M{x0 - 4:.1f},{y:.1f} C{x0 + w * .33:.1f},{y - a:.1f} {x0 + w * .66:.1f},{y + a:.1f} {x1 + 4:.1f},{y + (_rand(sh.d, i + 20) - .5) * 4:.1f}" '
                 f'fill="none" stroke="{darker(col, .35)}" stroke-width=".9" opacity=".3"/>')
    g.append(f'<path d="{sh.d}" fill="none" stroke="#FFFFFF" stroke-width="3" opacity=".42" transform="translate(1.3 1.3)"/>')
    g.append(f'<path d="{sh.d}" fill="none" stroke="{darker(col, .45)}" stroke-width="3" opacity=".22" transform="translate(-1.3 -1.3)"/></g>')
    o.append("".join(g))
    o.append(f'<path d="{sh.d}" fill="none" stroke="{darker(col, .5)}" stroke-width="1" stroke-opacity=".55" stroke-linejoin="round"{extra}/>')
    return "".join(o)


def origami_piece(sh, col, shade=1, thick=True, extra=""):
    """摺紙: a polygon, half lit and half shaded along one fold, with a light crease."""
    x0, y0, x1, y1 = sh.b
    k = _clip(sh)
    o = []
    if shade:
        o.append(f'<path d="{sh.d}" fill="{darker(col, .55)}" opacity=".16" transform="translate(2 {2 + 2 * shade})"{extra}/>')
    fold = lg([(0, lighter(col, .22)), (.5, lighter(col, .14)), (.5, darker(col, .16)), (1, darker(col, .22))], 0, 0, 1, 1)
    o.append(f'<path d="{sh.d}" fill="{fold}"{extra}/>')
    o.append(f'<g clip-path="url(#{k})"{extra}><path d="M{x1:.1f},{y0:.1f} L{x0:.1f},{y1:.1f}" stroke="#FFFFFF" stroke-width="1.3" opacity=".8"/></g>')
    o.append(f'<path d="{sh.d}" fill="none" stroke="{darker(col, .3)}" stroke-width=".8" stroke-opacity=".5" stroke-linejoin="round"{extra}/>')
    return "".join(o)


def woodcut_piece(sh, col, shade=1, thick=True, extra=""):
    """木刻版畫: flat ink, paper-coloured gouge marks clipped inside, a darker ink edge."""
    x0, y0, x1, y1 = sh.b
    w, h = max(1, x1 - x0), max(1, y1 - y0)
    k = _clip(sh)
    col = mixc(col, "#6B4630", .14)
    o = [f'<path d="{sh.d}" fill="{col}"{extra}/>']
    n = int(max(3, min(16, w * h / 140)))
    g = [f'<g clip-path="url(#{k})"{extra}>']
    for i in range(n):
        px = x0 + w * (.4 + .55 * _rand(sh.d, i))
        py = y0 + h * (.45 + .5 * _rand(sh.d, i + 30))
        ln = min(w, h) * (.3 + .3 * _rand(sh.d, i + 60))
        a = math.radians(-28 + 14 * _rand(sh.d, i + 90))
        ex, ey = px + ln * math.cos(a), py + ln * math.sin(a)
        mx, my = px + (ex - px) * .4, py + (ey - py) * .4
        nx, ny = -math.sin(a) * max(.9, ln * .09), math.cos(a) * max(.9, ln * .09)
        g.append(f'<path d="M{px:.1f},{py:.1f} L{mx + nx:.1f},{my + ny:.1f} L{ex:.1f},{ey:.1f} L{mx - nx:.1f},{my - ny:.1f}Z" fill="{PAPER["woodcut"]}" opacity=".85"/>')
    g.append("</g>")
    o.append("".join(g))
    o.append(f'<path d="{sh.d}" fill="none" stroke="{darker(col, .6)}" stroke-width="2" stroke-linejoin="round"{extra}/>')
    return "".join(o)


def piece(sh, col, shade=1, thick=True, extra=""):
    return {"wood": wood_piece, "origami": origami_piece, "woodcut": woodcut_piece}[STYLE](sh, col, shade, thick, extra)


def flat(sh, col, extra=""):
    return f'<path d="{sh.d}" fill="{col}"{extra}/>'


def stroke(d, col, w, dash=None, op=1.0, cap="round"):
    da = f' stroke-dasharray="{dash[0]} {dash[1]}"' if dash else ""
    return f'<path d="{d}" fill="none" stroke="{col}" stroke-opacity="{op}" stroke-width="{w}" stroke-linecap="{cap}" stroke-linejoin="round"{da}/>'


def place(x, y, s, fn, *a, rot=0.0, flip=False, **kw):
    t = f"translate({x:.1f} {y:.1f})" + (f" rotate({rot})" if rot else "") + (f" scale({-s if flip else s} {s})" if (s != 1 or flip) else "")
    return f'<g transform="{t}">{fn(*a, **kw)}</g>'


# ---------------------------------------------------------------- words and numerals
def tx(x, y, s, size=16, color=INK, anchor="middle", extra=""):
    return f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" fill="{color}" text-anchor="{anchor}" font-family="Huninn, sans-serif" {extra}>{s}</text>'


def txo(x, y, s, size, color, ol="#FFFFFF", ow=6, anchor="middle"):
    return tx(x, y, s, size, color, anchor, f'stroke="{ol}" stroke-width="{ow}" stroke-linejoin="round" paint-order="stroke"')


def painted(x, y, s, size, col):
    """A numeral painted on a piece: white with a darker edge in wood, flat dark ink otherwise."""
    if STYLE == "wood":
        return tx(x, y, s, size, "#FFFFFF", extra=f'stroke="{darker(col, .5)}" stroke-width="{max(3.0, size * .08):.1f}" stroke-linejoin="round" paint-order="stroke"')
    if STYLE == "woodcut":
        return tx(x, y, s, size, PAPER["woodcut"], extra=f'stroke="{darker(col, .55)}" stroke-width="2" paint-order="stroke"')
    return tx(x, y, s, size, "#FFFFFF", extra=f'stroke="{darker(col, .35)}" stroke-width="2.5" paint-order="stroke"')


def card_num(x, y, s, size, col):
    """A numeral printed on a cream order card: coloured, with a white edge."""
    return tx(x, y, s, size, darker(col, .1), extra=f'stroke="#FFFFFF" stroke-width="5" stroke-linejoin="round" paint-order="stroke"')


def numtile(cx, cy, n, size=44, col=YEL, lit=True):
    c = col if lit else GREY
    o = piece(rr(cx - size / 2, cy - size / 2, size, size, size * .22), c, shade=1 if lit else 0)
    if lit:
        o += painted(cx, cy + size * .25, str(n), size * .68, c)
    else:
        o += tx(cx, cy + size * .25, str(n), size * .68, "#B5AA9C")
    return o


DIE = {1: [(0, 0)], 2: [(-1, -1), (1, 1)], 3: [(-1, -1), (0, 0), (1, 1)], 4: [(-1, -1), (1, -1), (-1, 1), (1, 1)],
       5: [(-1, -1), (1, -1), (0, 0), (-1, 1), (1, 1)], 6: [(-1, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (1, 1)]}


def dots(cx, cy, n, r=5.0, col=RED, gap=None):
    """Dots like a die for 1-6; a ten-frame (rows of five) above that."""
    gap = gap or r * 2.6
    o = []
    if n <= 6:
        pts = [(cx + dx * gap, cy + dy * gap) for dx, dy in DIE[n]]
    else:
        pts = [(cx + (i % 5 - 2) * gap, cy + (i // 5 - .5) * gap) for i in range(n)]
    for x, y in pts:
        o.append(piece(circ(x, y, r), col, shade=0, thick=False))
    return "".join(o)


# ---------------------------------------------------------------- faces
def eye(cx, cy, r):
    return (f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{DARK}"/>'
            f'<circle cx="{cx - r * .32:.1f}" cy="{cy - r * .32:.1f}" r="{r * .38:.1f}" fill="#FFFFFF"/>')


def happy_eye(cx, cy, r):
    return stroke(f"M{cx - r:.1f},{cy + r * .3:.1f} Q{cx:.1f},{cy - r * 1.1:.1f} {cx + r:.1f},{cy + r * .3:.1f}", DARK, 2)


def sleep_eye(cx, cy, r):
    return stroke(f"M{cx - r:.1f},{cy - r * .2:.1f} Q{cx:.1f},{cy + r:.1f} {cx + r:.1f},{cy - r * .2:.1f}", DARK, 1.8)


def cheeks(cx, cy, dx, r):
    return f'<circle cx="{cx - dx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{CHEEK}" opacity=".7"/><circle cx="{cx + dx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{CHEEK}" opacity=".7"/>'


def smile(cx, cy, w, open_=False):
    if open_:
        return f'<path d="M{cx - w:.1f},{cy:.1f} Q{cx:.1f},{cy + w * 1.6:.1f} {cx + w:.1f},{cy:.1f}Z" fill="#C9546A"/>'
    return stroke(f"M{cx - w:.1f},{cy:.1f} Q{cx:.1f},{cy + w:.1f} {cx + w:.1f},{cy:.1f}", DARK, 1.6)


def face(cx, cy, s=1.0, mood="smile"):
    if mood == "happy":
        o = happy_eye(cx - 5 * s, cy, 2.4 * s) + happy_eye(cx + 5 * s, cy, 2.4 * s) + smile(cx, cy + 3.5 * s, 3 * s, True)
    elif mood == "sleep":
        o = sleep_eye(cx - 5 * s, cy, 2.4 * s) + sleep_eye(cx + 5 * s, cy, 2.4 * s) + smile(cx, cy + 4 * s, 2 * s)
    else:
        o = eye(cx - 5 * s, cy, 2 * s) + eye(cx + 5 * s, cy, 2 * s) + smile(cx, cy + 4 * s, 2.6 * s)
    return o + cheeks(cx, cy + 4 * s, 9 * s, 2.1 * s)


# ---------------------------------------------------------------- farm animals (drawn round (0, 0) = where the feet stand)
def chick(mood="smile", fed=False):
    o = [stroke("M-5,-2 v3 M-5,1 l-3,2 M-5,1 l3,2 M5,-2 v3 M5,1 l-3,2 M5,1 l3,2", ORA, 1.6)]
    o.append(piece(circ(0, -17, 16), CHICK, shade=1))
    o.append(piece(ell(-10, -13, 6, 4.5), darker(CHICK, .08), shade=0, thick=False))
    o.append(stroke("M-1,-33 q-2,-6 2,-7 M1,-33 q3,-5 5,-3", darker(CHICK, .2), 1.6))
    o.append(face(1, -21, .85, mood))
    o.append(flat(poly([(-3, -16.5), (5, -16.5), (1, -11)]), ORA))
    return "".join(o)


def hen():
    o = [stroke("M-6,-4 v4 M-6,0 l-4,3 M-6,0 l3,3 M6,-4 v4 M6,0 l-3,3 M6,0 l4,3", ORA, 2)]
    o.append(piece(poly([(-24, -30), (-38, -50), (-30, -22)]), "#F2E7D8", shade=0))
    o.append(piece(ell(0, -23, 25, 20), WHITE, shade=1))
    o.append(piece(ell(-5, -22, 13, 8.5), "#EFE4D6", shade=0, thick=False))
    o.append(piece(circ(18, -40, 11), WHITE, shade=0))
    for dx in (-5, 0, 5):
        o.append(piece(circ(18 + dx, -52 + abs(dx) * .4, 4.2), RED, shade=0, thick=False))
    o.append(flat(poly([(28, -42), (36, -39), (28, -36)]), ORA))
    o.append(piece(ell(27, -32, 3, 4.5), RED, shade=0, thick=False))
    o.append(eye(21, -42, 2.2) + f'<circle cx="25" cy="-37" r="2" fill="{CHEEK}" opacity=".7"/>')
    return "".join(o)


def egg(cx, cy, s=1.0, col=EGG):
    return piece(ell(cx, cy, 9 * s, 11.5 * s), col, shade=1)


def nest(cx, cy, w=70):
    o = [piece(ell(cx, cy, w / 2, w * .2), "#D8B060", shade=1)]
    for i in range(6):
        x = cx - w * .4 + i * w * .16
        o.append(stroke(f"M{x:.1f},{cy - 3:.1f} q{w * .06:.1f},{6:.1f} {w * .14:.1f},{-1:.1f}", "#B88A3C", 1.4))
    return "".join(o)


def piglet(mood="smile"):
    o = [piece(rr(-14, -8, 9, 10, 4), darker(PIG, .1), shade=0), piece(rr(5, -8, 9, 10, 4), darker(PIG, .1), shade=0)]
    o.append(piece(poly([(-19, -40), (-15, -56), (-5, -44)]), PIG, shade=0))
    o.append(piece(poly([(19, -40), (15, -56), (5, -44)]), PIG, shade=0))
    o.append(piece(circ(0, -26, 22), PIG, shade=1))
    o.append(face(0, -31, 1.0, mood))
    o.append(piece(ell(0, -19, 8.5, 6), lighter(PIG, .25), shade=0, thick=False))
    o.append(f'<ellipse cx="-3" cy="-19" rx="1.6" ry="2.2" fill="{darker(PIG, .45)}"/><ellipse cx="3" cy="-19" rx="1.6" ry="2.2" fill="{darker(PIG, .45)}"/>')
    return "".join(o)


def sheep(mood="smile"):
    o = [piece(rr(-14, -12, 7, 14, 3), "#6F6360", shade=0), piece(rr(8, -12, 7, 14, 3), "#6F6360", shade=0)]
    o.append(piece(blob(0, -30, 26, 21, 8, .1, 3), WHITE, shade=1))
    o.append(piece(ell(-16, -45, 6, 3.5), "#E2D3C3", shade=0))
    o.append(piece(ell(16, -45, 6, 3.5), "#E2D3C3", shade=0))
    o.append(piece(ell(0, -38, 13, 15), "#EADCCB", shade=0))
    o.append(piece(blob(0, -52, 12, 6, 5, .15, 4), WHITE, shade=0, thick=False))
    o.append(face(0, -38, .95, mood))
    return "".join(o)


def buffalo(mood="smile", hat=True):
    """牛牛, the little water buffalo who shows the child round the farm, in a bamboo hat (斗笠)."""
    o = [piece(ell(-12, -4, 11, 6), darker(BUFF, .2), shade=0), piece(ell(12, -4, 11, 6), darker(BUFF, .2), shade=0)]
    o.append(piece(ell(0, -28, 28, 26), BUFF, shade=1))
    o.append(piece(ell(0, -22, 17, 15), lighter(BUFF, .3), shade=0, thick=False))
    o.append(piece(ell(-27, -30, 7, 12), BUFF, shade=0))
    o.append(piece(ell(27, -30, 7, 12), BUFF, shade=0))
    for sx in (-1, 1):
        o.append(piece(smooth([(sx * 14, -76), (sx * 30, -80), (sx * 44, -92), (sx * 40, -82), (sx * 26, -71), (sx * 14, -68)]), "#F0E4CA", shade=0))
        o.append(piece(ell(sx * 25, -66, 8, 4.5), darker(BUFF, .08), shade=0))
    o.append(piece(circ(0, -64, 22), BUFF, shade=0))
    o.append(face(0, -68, 1.15, mood))
    o.append(piece(ell(0, -52, 14, 8.5), "#CFC7D6", shade=0, thick=False))
    o.append(f'<ellipse cx="-5" cy="-52" rx="2" ry="2.6" fill="{darker(BUFF, .5)}"/><ellipse cx="5" cy="-52" rx="2" ry="2.6" fill="{darker(BUFF, .5)}"/>')
    if hat:
        o.append(piece(poly([(-36, -82), (0, -106), (36, -82)]) if STYLE != "wood" else
                       Sh("M-37,-82 Q-14,-92 -3,-104 Q0,-107 3,-104 Q14,-92 37,-82 Q0,-76 -37,-82Z", (-37, -107, 37, -78)), HAT, shade=1))
        o.append(stroke("M-20,-87 Q0,-82 20,-87", darker(HAT, .3), 1.4, op=.7))
    return "".join(o)


# ---------------------------------------------------------------- produce
def guava(cx, cy, r=11):
    return (piece(circ(cx, cy, r), GUAVA, shade=1) + stroke(f"M{cx},{cy - r + 1} v-4", WALNUT, 2)
            + piece(ell(cx + 5, cy - r - 3, 5, 2.6), GRN, shade=0, thick=False))


def sweet_potato(cx, cy, rot=-15, s=1.0):
    def sp():
        return piece(smooth([(-16, 0), (-9, -8), (4, -9), (15, -4), (17, 2), (8, 8), (-6, 8), (-14, 5)]), POTATO, shade=1) + stroke("M-6,-2 q3,2 6,0 M4,3 q3,2 6,0", darker(POTATO, .3), 1.1, op=.6)
    return place(cx, cy, s, sp, rot=rot)


def cabbage(cx, cy, r=17):
    o = [piece(circ(cx, cy, r), CABBAGE, shade=1)]
    o.append(stroke(f"M{cx - r * .6:.1f},{cy - r * .1:.1f} Q{cx - r * .1:.1f},{cy - r * .7:.1f} {cx + r * .5:.1f},{cy - r * .3:.1f} M{cx - r * .4:.1f},{cy + r * .4:.1f} Q{cx + r * .2:.1f},{cy - r * .05:.1f} {cx + r * .7:.1f},{cy + r * .3:.1f}", darker(CABBAGE, .3), 1.6, op=.7))
    return "".join(o)


def carrot(cx, cy, s=1.0):
    o = []
    for dx, rot in ((-5, -25), (0, 0), (5, 25)):
        o.append(place(cx + dx * s, cy - 15 * s, s, lambda: piece(ell(0, -8, 4, 9), GRN, shade=0), rot=rot))
    o.append(piece(smooth([(cx - 9 * s, cy - 14 * s), (cx + 9 * s, cy - 14 * s), (cx + 4 * s, cy + 6 * s), (cx, cy + 18 * s), (cx - 4 * s, cy + 6 * s)]), CARROT, shade=1))
    o.append(stroke(f"M{cx - 4 * s:.1f},{cy - 4 * s:.1f} h4 M{cx + 1 * s:.1f},{cy + 4 * s:.1f} h3", darker(CARROT, .3), 1.2, op=.7))
    return "".join(o)


def corn(cx, cy, s=1.0):
    o = [piece(ell(cx, cy, 9 * s, 17 * s), YEL, shade=1)]
    for i in range(5):
        o.append(stroke(f"M{cx - 6 * s:.1f},{cy + (i - 2) * 5.5 * s:.1f} h{12 * s:.1f}", darker(YEL, .25), 1, op=.5))
    o.append(piece(smooth([(cx - 3 * s, cy + 16 * s), (cx - 13 * s, cy + 2 * s), (cx - 10 * s, cy - 12 * s), (cx - 2 * s, cy + 4 * s)]), GRN, shade=0))
    o.append(piece(smooth([(cx + 3 * s, cy + 16 * s), (cx + 13 * s, cy + 2 * s), (cx + 10 * s, cy - 12 * s), (cx + 2 * s, cy + 4 * s)]), GRN, shade=0))
    return "".join(o)


def kernel(cx, cy, r=4.2):
    return piece(ell(cx, cy, r, r * 1.15), YEL, shade=0, thick=False) + f'<ellipse cx="{cx - r * .3:.1f}" cy="{cy - r * .4:.1f}" rx="{r * .35:.1f}" ry="{r * .25:.1f}" fill="#FFF" opacity=".7"/>'


def watermelon(cx, cy, r=12):
    o = [piece(circ(cx, cy, r), MELON, shade=1)]
    k = _clip(circ(cx, cy, r))
    o.append(f'<g clip-path="url(#{k})">' + stroke(f"M{cx - r * .5:.1f},{cy - r:.1f} q{-r * .25:.1f},{r:.1f} 0,{2 * r:.1f} M{cx:.1f},{cy - r:.1f} q{-r * .2:.1f},{r:.1f} 0,{2 * r:.1f} M{cx + r * .5:.1f},{cy - r:.1f} q{-r * .15:.1f},{r:.1f} 0,{2 * r:.1f}", "#2C6B39", 2.2, op=.8) + "</g>")
    return "".join(o)


def spoon(cx, cy, rot=0, s=1.0):
    def sp():
        return piece(rr(-2.5, -2, 5, 34, 2.5), "#C9CED6", shade=1) + piece(ell(0, -10, 8, 11), "#D6DAE1", shade=1)
    return place(cx, cy, s, sp, rot=rot)


# ---------------------------------------------------------------- farm things
def tree(cx, by, s=1.0, fruits=()):
    o = [piece(rr(cx - 9 * s, by - 70 * s, 18 * s, 72 * s, 6 * s), WALNUT, shade=1)]
    o.append(piece(blob(cx, by - 110 * s, 70 * s, 56 * s, 7, .1, 7), "#79BD5E", shade=2))
    for fx, fy in fruits:
        o.append(guava(cx + fx * s, by + fy * s, 11 * s))
    return "".join(o)


def coop(cx=0, by=0, s=1.0):
    o = [piece(rr(cx - 46 * s, by - 62 * s, 92 * s, 62 * s, 4 * s), WOOD2, shade=1)]
    for i in range(1, 4):
        o.append(stroke(f"M{cx - 46 * s:.1f},{by - 62 * s + i * 15.5 * s:.1f} h{92 * s:.1f}", darker(WOOD2, .3), 1, op=.5))
    o.append(piece(poly([(cx - 56 * s, by - 58 * s), (cx, by - 98 * s), (cx + 56 * s, by - 58 * s)]), RED, shade=1))
    o.append(piece(Sh(f"M{cx - 14 * s:.1f},{by:.1f} v{-26 * s:.1f} a{14 * s:.1f},{14 * s:.1f} 0 0 1 {28 * s:.1f},0 v{26 * s:.1f}Z", (cx - 14 * s, by - 40 * s, cx + 14 * s, by)), "#6E4A33", shade=0, thick=False))
    o.append(piece(circ(cx, by - 74 * s, 8 * s), CREAM, shade=0, thick=False))
    o.append(piece(poly([(cx + 14 * s, by), (cx + 46 * s, by + 8 * s), (cx + 46 * s, by + 3 * s), (cx + 14 * s, by - 6 * s)]), WOOD, shade=0))
    return "".join(o)


def fence(x0, x1, by, col=WOOD):
    o = [piece(rr(x0, by - 26, x1 - x0, 6, 3), col, shade=0), piece(rr(x0, by - 13, x1 - x0, 6, 3), col, shade=0)]
    x = x0 + 4
    while x < x1 - 8:
        o.append(piece(Sh(f"M{x:.1f},{by:.1f} v-30 l5,-6 l5,6 v30Z", (x, by - 36, x + 10, by)), col, shade=1))
        x += 26
    return "".join(o)


def basket(cx, cy, w=110, h=52, col="#D7A55E"):
    o = [stroke(f"M{cx - w * .36:.1f},{cy - h / 2:.1f} C{cx - w * .3:.1f},{cy - h * 1.5:.1f} {cx + w * .3:.1f},{cy - h * 1.5:.1f} {cx + w * .36:.1f},{cy - h / 2:.1f}", darker(col, .3), 6),
         stroke(f"M{cx - w * .36:.1f},{cy - h / 2:.1f} C{cx - w * .3:.1f},{cy - h * 1.5:.1f} {cx + w * .3:.1f},{cy - h * 1.5:.1f} {cx + w * .36:.1f},{cy - h / 2:.1f}", col, 3)]
    return "".join(o)


def basket_front(cx, cy, w=110, h=52, col="#D7A55E"):
    sh = Sh(f"M{cx - w / 2:.1f},{cy - h / 2:.1f} H{cx + w / 2:.1f} L{cx + w * .4:.1f},{cy + h / 2:.1f} H{cx - w * .4:.1f}Z", (cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2))
    o = [piece(sh, col, shade=2)]
    k = _clip(sh)
    o.append(f'<g clip-path="url(#{k})">' + "".join(stroke(f"M{cx - w / 2:.1f},{cy - h / 2 + i * h / 4:.1f} h{w:.1f}", darker(col, .3), 1.2, op=.55) for i in range(1, 4)) + "</g>")
    o.append(piece(rr(cx - w / 2 - 3, cy - h / 2 - 4, w + 6, 9, 4.5), darker(col, .08), shade=0))
    return "".join(o)


def bucket(cx, cy):
    o = [piece(Sh(f"M{cx - 34},{cy - 30} H{cx + 34} L{cx + 27},{cy + 26} H{cx - 27}Z", (cx - 34, cy - 30, cx + 34, cy + 26)), WOOD2, shade=2)]
    o.append(stroke(f"M{cx - 33},{cy - 18} H{cx + 33} M{cx - 29},{cy + 14} H{cx + 29}", "#8A8F9C", 3.2))
    for i in range(9):
        o.append(kernel(cx - 26 + (i % 5) * 13 + (i // 5) * 6, cy - 33 - (i // 5) * 6, 4.6))
    return "".join(o)


def egg_tray(cx, cy, eggs=0, w=300, col=WOOD, ghost=None):
    """The egg tray is a ten-frame: two rows of five cups."""
    h = w * .42
    o = [piece(rr(cx - w / 2, cy - h / 2, w, h, 16), col, shade=2)]
    sx = w / 5.4
    for i in range(10):
        x = cx + (i % 5 - 2) * sx
        y = cy + (i // 5 - .5) * h * .46
        o.append(piece(ell(x, y, sx * .38, sx * .34), darker(col, .2), shade=0, thick=False))
        if i < eggs:
            o.append(egg(x, y - 3, sx / 26))
        elif ghost is not None and i == ghost:
            o.append(f'<ellipse cx="{x:.1f}" cy="{y - 3:.1f}" rx="{9 * sx / 26:.1f}" ry="{11.5 * sx / 26:.1f}" fill="none" stroke="{ORA}" stroke-width="2.5" stroke-dasharray="4 4"/>')
    return "".join(o)


def truck(load=0, extra_melons=0):
    """The little blue truck (發財車). Its bed is a ten-frame: two rows of five hollows."""
    o = [piece(rr(-120, -34, 214, 14, 5), "#6B6F7A", shade=1)]
    o.append(piece(Sh("M30,-30 V-86 Q30,-96 40,-96 H70 Q80,-96 86,-84 L100,-56 Q104,-50 104,-42 V-30Z", (30, -96, 104, -30)), BLUE, shade=1))
    o.append(piece(Sh("M42,-84 H70 Q74,-84 77,-78 L88,-58 H42Z", (42, -84, 88, -58)), "#DCEFFA", shade=0, thick=False))
    o.append(piece(rr(92, -48, 10, 7, 3), YEL, shade=0, thick=False))
    o.append(piece(rr(-122, -90, 146, 34, 6), lighter(WOOD, .2), shade=0))
    for i in range(10):
        x = -104 + (i % 5) * 27.5
        y = -82 + (i // 5) * 14
        o.append(piece(ell(x, y, 11, 4.5), darker(WOOD, .22), shade=0, thick=False))
    melons = []
    for i in range(load + extra_melons):
        x = -104 + (i % 5) * 27.5
        y = -89 + (i // 5) * 14
        melons.append((i // 5, x, y, i >= load))
    for row in (0, 1):
        for r_, x, y, new in melons:
            if r_ == row:
                o.append(watermelon(x, y, 12))
                if new:
                    o.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="15.5" fill="none" stroke="{YEL}" stroke-width="3"/>')
    o.append(piece(rr(-124, -60, 150, 28, 6), BLUE, shade=1))
    o.append(stroke("M-118,-46 H20", darker(BLUE, .25), 1.6, op=.6))
    for wx in (-82, 64):
        o.append(piece(circ(wx, -18, 17), "#3E414B", shade=1))
        o.append(piece(circ(wx, -18, 7), "#C9CED6", shade=0, thick=False))
    return "".join(o)


def sun(cx, cy, r=22, mood="happy"):
    o = []
    for i in range(8):
        a = math.radians(i * 45)
        o.append(stroke(f"M{cx + (r + 7) * math.cos(a):.1f},{cy + (r + 7) * math.sin(a):.1f} l{7 * math.cos(a):.1f},{7 * math.sin(a):.1f}", YEL, 3))
    o.append(piece(circ(cx, cy, r), YEL, shade=0))
    o.append(face(cx, cy - 2, r / 22, mood))
    return "".join(o)


def cloud(cx, cy, s=1.0):
    if STYLE == "origami":
        sh = poly([(cx - 34 * s, cy + 10 * s), (cx - 26 * s, cy - 6 * s), (cx - 10 * s, cy - 18 * s), (cx + 8 * s, cy - 12 * s), (cx + 24 * s, cy - 4 * s), (cx + 34 * s, cy + 10 * s)])
    else:
        sh = Sh(f"M{cx - 34 * s:.1f},{cy + 10 * s:.1f} a{11 * s:.1f},{11 * s:.1f} 0 0 1 {8 * s:.1f},{-17 * s:.1f} a{15 * s:.1f},{15 * s:.1f} 0 0 1 {26 * s:.1f},{-9 * s:.1f} "
                f"a{13 * s:.1f},{13 * s:.1f} 0 0 1 {24 * s:.1f},{8 * s:.1f} a{10 * s:.1f},{10 * s:.1f} 0 0 1 {10 * s:.1f},{18 * s:.1f}Z", (cx - 34 * s, cy - 24 * s, cx + 34 * s, cy + 10 * s))
    return piece(sh, "#FFFFFF", shade=0, thick=False)


# ---------------------------------------------------------------- UI pieces
def finger(x, y, rot=-20.0):
    o = [f'<g transform="translate({x} {y}) rotate({rot})">']
    o.append(f'<path d="M-9,46 V12 a9,9 0 0 1 18,0 v10 l4,-2 a6,6 0 0 1 8,4 l4,-1 a6,6 0 0 1 8,6 l2,1 a6,6 0 0 1 7,6 v18 a24,24 0 0 1 -24,24 h-16 a14,14 0 0 1 -11,-20Z" fill="{SKIN}" stroke="{darker(SKIN, .35)}" stroke-width="2" stroke-linejoin="round"/>')
    o.append(f'<circle cx="0" cy="0" r="15" fill="none" stroke="{YEL}" stroke-width="3" opacity=".9"/><circle cx="0" cy="0" r="25" fill="none" stroke="{YEL}" stroke-width="2" opacity=".5"/></g>')
    return "".join(o)


def arc_path(x0, y0, x1, y1, lift=60):
    return stroke(f"M{x0},{y0} Q{(x0 + x1) / 2},{min(y0, y1) - lift} {x1},{y1}", "#FFFFFF", 3, dash=(2, 7), op=.95)


def sparkle(cx, cy, r, c=YEL, op=1.0):
    return (f'<path d="M{cx},{cy - r} Q{cx + r * .16},{cy - r * .16} {cx + r},{cy} Q{cx + r * .16},{cy + r * .16} {cx},{cy + r} '
            f'Q{cx - r * .16},{cy + r * .16} {cx - r},{cy} Q{cx - r * .16},{cy - r * .16} {cx},{cy - r}Z" fill="{c}" opacity="{op}"/>')


def plank(cx, cy, w, text, size=22, col=WOOD, h=44):
    o = [piece(rr(cx - w / 2, cy - h / 2, w, h, 10), col, shade=2)]
    o.append(f'<circle cx="{cx - w / 2 + 13}" cy="{cy}" r="3" fill="{WALNUT}"/><circle cx="{cx + w / 2 - 13}" cy="{cy}" r="3" fill="{WALNUT}"/>')
    o.append(tx(cx, cy + size * .36, text, size, INK))
    return "".join(o)


def round_btn(cx, cy, r, col, icon=""):
    return piece(circ(cx, cy, r), col, shade=2) + icon


def home_icon(cx, cy):
    return flat(poly([(cx - 11, cy), (cx, cy - 11), (cx + 11, cy)]), RED) + flat(rr(cx - 8, cy - 1, 16, 10, 2), RED)


def speaker_icon(cx, cy, s=1.0, col="#FFFFFF"):
    o = [flat(poly([(cx - 9 * s, cy - 4 * s), (cx - 4 * s, cy - 4 * s), (cx + 3 * s, cy - 10 * s), (cx + 3 * s, cy + 10 * s), (cx - 4 * s, cy + 4 * s), (cx - 9 * s, cy + 4 * s)]), col)]
    o.append(stroke(f"M{cx + 7 * s},{cy - 5 * s} q5,5 0,10 M{cx + 11 * s},{cy - 9 * s} q8,9 0,18", col, 2.2 * s))
    return "".join(o)


def topbar(title):
    return (round_btn(36, 42, 21, WOOD, home_icon(36, 45)) + plank(195, 42, 180, title, 22)
            + round_btn(354, 42, 21, ORA, speaker_icon(352, 42, .95)))


def shadow_rect(x, y, w, h, r=18, col=WHITE, op=.12):
    return (f'<rect x="{x + 1}" y="{y + 4}" width="{w}" height="{h}" rx="{r}" fill="#5A3A1E" opacity="{op}"/>'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{col}"/>')


def bubble(x, y, w, h, text, size=17, tail=None, fill=WHITE, lines=None):
    o = [shadow_rect(x, y, w, h, 16, fill)]
    if tail == "down":
        o.append(f'<path d="M{x + 30},{y + h - 1} l10,16 l10,-16Z" fill="{fill}"/>')
    elif tail == "left":
        o.append(f'<path d="M{x + 1},{y + h / 2 - 10} l-14,10 l14,10Z" fill="{fill}"/>')
    elif tail == "right":
        o.append(f'<path d="M{x + w - 1},{y + h / 2 - 10} l14,10 l-14,10Z" fill="{fill}"/>')
    if lines:
        for i, ln in enumerate(lines):
            o.append(tx(x + w / 2, y + 30 + i * (size + 8), ln, size, INK))
    else:
        o.append(tx(x + w / 2, y + h / 2 + size * .36, text, size, INK))
    return "".join(o)


def lock_chip(x=14, y=16):
    o = [piece(rr(x, y, 42, 30, 10), WOOD2, shade=2)]
    o.append(stroke(f"M{x + 21},{y + 7} m-5,7 v-3 a5,5 0 0 1 10,0 v3", "#8A8F9C", 2.2))
    o.append(flat(rr(x + 13, y + 14, 16, 11, 3), "#8A8F9C"))
    return "".join(o)


def toggle(x, y, on=True):
    col = GRN if on else GREY
    return piece(rr(x, y, 46, 26, 13), col, shade=0) + piece(circ(x + (33 if on else 13), y + 13, 10), "#FFFFFF", shade=0)


def ground(y, col=GRASS, sky=SKY, sky2=None):
    """Sky, two far hills and the grass from y down."""
    o = [f'<rect width="{W}" height="{H}" fill="{lg([(0, sky2 or lighter(sky, .4)), (1, sky)])}"/>']
    o.append(piece(blob(80, y + 10, 170, 60, 4, .04, 1), darker(col, .08), shade=0, thick=False))
    o.append(piece(blob(330, y + 16, 150, 48, 4, .04, 2), darker(col, .14), shade=0, thick=False))
    o.append(f'<rect x="0" y="{y}" width="{W}" height="{H - y}" fill="{col}"/>')
    for i in range(14):
        gx, gy = 20 + _rand("g", i) * 350, y + 30 + _rand("g", i + 40) * (H - y - 60)
        o.append(stroke(f"M{gx:.1f},{gy:.1f} l-3,-7 M{gx:.1f},{gy:.1f} l0,-9 M{gx:.1f},{gy:.1f} l3,-7", darker(col, .15), 1.5, op=.6))
    return "".join(o)


def page(body, bg="#F7EEDC", w=W, h=H):
    css = (f"@font-face {{ font-family: Huninn; src: url('file://{FONT}'); }}"
           f"* {{ margin: 0; padding: 0; }} body {{ width: {w}px; height: {h}px; overflow: hidden; background: {bg}; }}")
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{D.svg()}{body}</svg>'
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head><body>{svg}</body></html>'


def render(html, out, w, h, scale):
    with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp:
        p = pathlib.Path(tmp) / "page.html"
        p.write_text(html)
        subprocess.run(["node", str(HERE / "render.js"), str(p), str(out), str(w), str(h), str(scale)], check=True)
    if pathlib.Path(out).stat().st_size > 400_000:
        from PIL import Image
        im = Image.open(out).convert("RGB")
        im.quantize(colors=256, method=Image.Quantize.MEDIANCUT, kmeans=2, dither=Image.Dither.FLOYDSTEINBERG).save(out, optimize=True)


# ================================================================ SCREEN 1: the farm (home)
def place_label(cx, cy, text, col):
    return piece(rr(cx - 46, cy - 17, 92, 34, 12), col, shade=2) + tx(cx, cy + 7, text, 18, "#FFFFFF", extra=f'stroke="{darker(col, .45)}" stroke-width="3.5" paint-order="stroke"')


def screen_farm():
    o = [ground(250)]
    o.append(cloud(70, 120, .8) + cloud(300, 150, .6))
    o.append(sun(330, 104, 20))
    o.append(lock_chip(14, 16))
    o.append(plank(195, 44, 220, "數數小農場", 24))
    # dirt paths joining the places
    path = "M90,330 C150,380 240,330 300,380 S220,500 110,520 S220,640 300,640"
    o.append(stroke(path, "#E2C79A", 30) + stroke(path, "#EDD7AF", 22))
    # 1 coop (feed the chicks)
    o.append(coop(92, 300, 1.0))
    for i, x in enumerate((40, 140)):
        o.append(place(x, 318, .75, chick))
    o.append(place_label(92, 352, "餵小雞", ORA))
    # 2 nests (eggs)
    o.append(nest(296, 318, 86))
    o.append(place(290, 312, .8, hen))
    o.append(egg(320, 312, .8) + egg(334, 314, .8))
    o.append(place_label(296, 352, "撿雞蛋", YEL))
    # 3 orchard (fruit)
    o.append(tree(90, 512, .62, fruits=((-30, -118), (14, -128), (34, -100), (-10, -92))))
    o.append(basket_front(140, 498, 40, 22))
    o.append(place_label(90, 540, "摘水果", GRN))
    # 4 pig pen (share)
    o.append(fence(236, 360, 500, WOOD))
    o.append(place(270, 496, .7, piglet) + place(326, 496, .7, piglet))
    o.append(sweet_potato(298, 504, 10, .7))
    o.append(place_label(298, 540, "分點心", PINK))
    # 5 vegetable rows (patterns)
    o.append(piece(rr(30, 610, 130, 40, 14), SOIL, shade=1))
    for i in range(4):
        o.append(cabbage(48 + i * 32, 628, 11) if i % 2 == 0 else carrot(48 + i * 32, 632, .55))
    o.append(place_label(95, 678, "排排隊", TEAL))
    # 6 the truck (market)
    o.append(place(310, 660, .62, truck, 3))
    o.append(place_label(296, 690, "去市場", BLUE))
    # the guide and today's chicks
    o.append(place(52, 820, .78, buffalo))
    o.append(bubble(102, 752, 196, 48, "今天先去哪裡呢？", 17, "left"))
    o.append(piece(rr(256, 806, 120, 30, 15), WOOD, shade=1) + tx(316, 826, "小雞 12 隻", 15, INK))
    o.append(place(258, 822, .45, chick))
    return page("".join(o))


# ================================================================ SCREEN 2: feed the chicks
def screen_chicks():
    o = [ground(300)]
    o.append(cloud(300, 150, .7))
    o.append(place(330, 300, .8, coop))
    o.append(topbar("餵小雞"))
    o.append(bubble(24, 92, 250, 52, "每隻小雞，一顆玉米", 18, "down"))
    xs = [55, 125, 195, 265, 335]
    for i, x in enumerate(xs):
        fed = i < 3
        o.append(place(x, 470, 1.55, chick, "happy" if fed else "smile"))
        if fed:
            o.append(kernel(x + 14, 474, 6.5))
            o.append(numtile(x, 386, i + 1, 38, ORA))
    # the corn on its way to chick 4
    o.append(arc_path(195, 600, 278, 476, 110))
    o.append(kernel(244, 520, 6.5))
    o.append(finger(270, 440, -16))
    o.append(bucket(195, 630))
    o.append(tx(195, 690, "點小雞，玉米就跳過去", 14, darker(GRASS, .55)))
    # the counting strip: numerals light up as the child counts
    o.append(shadow_rect(30, 720, 330, 76, 22, CREAM))
    for i in range(5):
        o.append(numtile(72 + i * 62, 758, i + 1, 46, ORA, lit=i < 3))
    o.append(sparkle(368, 712, 9))
    return page("".join(o))


# ================================================================ SCREEN 3: collect eggs
def screen_eggs():
    o = [ground(250, sky="#F6E2C4", sky2="#FBF1E1")]
    o.append(topbar("撿雞蛋"))
    # 阿嬤's order: a clipboard with the numeral and its dots
    o.append(piece(rr(28, 84, 170, 132, 16), WOOD2, shade=2))
    o.append(f'<rect x="40" y="96" width="146" height="108" rx="10" fill="{CREAM}"/>')
    o.append(piece(rr(92, 78, 42, 16, 5), "#8A8F9C", shade=0))
    o.append(tx(113, 122, "阿嬤要", 16, SOFT))
    o.append(card_num(78, 190, "7", 64, RED))
    o.append(dots(152, 166, 7, 4.8, RED, 12))
    o.append(place(310, 210, 1.0, buffalo))
    # the nests
    for nx, n in ((80, 2), (195, 3), (310, 1)):
        o.append(nest(nx, 352, 92))
        o.append(place(nx - 10, 346, .9, hen))
        for j in range(n):
            o.append(egg(nx + 28 + j * 11, 348 - (j % 2) * 4, .85))
    # the tray (a ten-frame) with six eggs, the seventh on its way
    o.append(egg_tray(195, 560, 6, 320, WOOD, ghost=6))
    o.append(arc_path(206, 344, 136, 588, 30))
    o.append(egg(150, 470, 1.15))
    o.append(finger(160, 486, -10))
    o.append(numtile(320, 470, 6, 52, ORA))
    o.append(bubble(28, 690, 334, 56, "6！再一顆就是 7", 18))
    o.append(tx(195, 790, "上面一排 5 顆，下面再數 1、2……", 14, darker(GRASS, .6)))
    return page("".join(o))


# ================================================================ SCREEN 4: pick fruit
def screen_fruit():
    o = [ground(330)]
    o.append(cloud(80, 130, .7))
    o.append(topbar("摘水果"))
    o.append(tree(150, 520, 1.55, fruits=((-46, -150), (-14, -168), (26, -146), (46, -110), (-40, -104), (8, -112), (-20, -132))))
    # the sheep's order sign
    o.append(place(320, 330, 1.0, sheep))
    o.append(piece(rr(266, 108, 110, 128, 14), WOOD, shade=2))
    o.append(f'<rect x="276" y="118" width="90" height="108" rx="10" fill="{CREAM}"/>')
    o.append(card_num(300, 188, "4", 58, GRN))
    o.append(dots(342, 162, 4, 4.6, GRN, 8))
    o.append(guava(342, 204, 9))
    o.append(stroke("M321,236 v24", WALNUT, 4))
    o.append(bubble(234, 370, 140, 48, "我要 4 顆", 18, None))
    # the basket with three guavas, the fourth being picked
    o.append(basket(195, 662, 140, 62))
    for x in (160, 190, 220):
        o.append(guava(x, 632, 15))
    o.append(basket_front(195, 662, 140, 62))
    o.append(arc_path(170, 376, 236, 628, 40))
    o.append(guava(212, 548, 15))
    o.append(finger(170, 388, -12))
    o.append(numtile(300, 640, 3, 50, GRN))
    o.append(bubble(28, 740, 334, 56, "1、2、3……再摘一顆！", 18))
    return page("".join(o))


# ================================================================ SCREEN 5: share snacks
def screen_share():
    o = [ground(250, col="#B9DB8E", sky="#D7EEF7")]
    o.append(fence(-10, 400, 300, WOOD))
    o.append(topbar("分點心"))
    o.append(bubble(24, 92, 300, 52, "小豬一隻一個，輪流分", 18, "down"))
    plates = [(70, 2), (195, 2), (320, 1)]
    for x, n in plates:
        o.append(place(x, 360, 1.3, piglet, "happy" if n == 2 else "smile"))
        o.append(piece(ell(x, 410, 52, 17), WHITE, shade=1))
        o.append(f'<ellipse cx="{x}" cy="{410}" rx="38" ry="10" fill="none" stroke="{GREY}" stroke-width="2"/>')
        for j in range(n):
            o.append(sweet_potato(x - 14 + j * 28, 404, -10 + j * 20, .9))
        o.append(numtile(x, 466, n, 34, PINK))
    # the basket: one sweet potato left, on its way to the third piglet
    o.append(basket(195, 650, 150, 64, "#C99A5E"))
    o.append(basket_front(195, 650, 150, 64, "#C99A5E"))
    o.append(arc_path(196, 596, 334, 404, 60))
    o.append(sweet_potato(282, 520, 20, 1.1))
    o.append(finger(290, 534, -30))
    o.append(bubble(28, 730, 334, 64, "", 17, lines=["你一個、你一個、你一個……"]))
    o.append(tx(195, 812, "分完了，大家比一比：都一樣多嗎？", 14, darker(GRASS, .6)))
    return page("".join(o))


# ================================================================ SCREEN 6: vegetable row pattern
def screen_pattern():
    o = [ground(200, col="#B5D98A")]
    o.append(topbar("排排隊"))
    o.append(bubble(24, 92, 300, 52, "高麗菜、紅蘿蔔、高麗菜……", 17, "down"))
    # the soil row with the pattern and one empty spot
    o.append(piece(rr(14, 196, 362, 120, 26), SOIL, shade=2))
    o.append(stroke("M30,280 H360", darker(SOIL, .25), 2, dash=(4, 8), op=.6))
    seq = ["c", "r", "c", "r", "c"]
    for i, k in enumerate(seq):
        x = 44 + i * 60
        o.append(cabbage(x, 254, 22) if k == "c" else carrot(x, 258, 1.05))
    o.append(f'<circle cx="344" cy="254" r="26" fill="{lighter(SOIL, .25)}" stroke="#FFFFFF" stroke-width="3" stroke-dasharray="6 6"/>')
    o.append(tx(344, 266, "？", 30, "#FFFFFF"))
    # the sound of the pattern (it is spoken and clapped too)
    o.append(shadow_rect(30, 340, 330, 54, 18, CREAM))
    for i, (w_, c) in enumerate((("咚", GRN), ("啪", ORA), ("咚", GRN), ("啪", ORA), ("咚", GRN), ("？", GREY))):
        o.append(tx(62 + i * 53, 375, w_, 22, darker(c, .3)))
    # the choices: three seed boxes
    o.append(tx(195, 452, "下一個種什麼？", 18, INK))
    for x, k, sel in ((80, "corn", False), (195, "r", True), (310, "c", False)):
        o.append(piece(rr(x - 52, 476, 104, 112, 20), WOOD if not sel else "#FFE7A8", shade=2))
        if sel:
            o.append(f'<rect x="{x - 52}" y="476" width="104" height="112" rx="20" fill="none" stroke="{GRN}" stroke-width="4"/>')
        o.append(corn(x, 532, 1.4) if k == "corn" else carrot(x, 534, 1.35) if k == "r" else cabbage(x, 532, 30))
    o.append(finger(206, 548, -15))
    o.append(place(60, 800, .85, buffalo, "happy"))
    o.append(bubble(118, 700, 250, 70, "", 17, "left", lines=["高麗菜、紅蘿蔔，", "一直輪流！"]))
    return page("".join(o))


# ================================================================ SCREEN 7: the truck to market (add and take away)
def screen_truck():
    o = [ground(380)]
    o.append(cloud(90, 140, .7) + cloud(320, 112, .5))
    o.append(topbar("去市場"))
    o.append(bubble(24, 92, 342, 56, "車上有 3 個西瓜，再放 2 個", 18, "down"))
    # the melon patch with two melons going up
    o.append(piece(rr(220, 470, 160, 70, 26), "#B9D88F", shade=0, thick=False))
    for mx, my in ((250, 506), (290, 512), (330, 504), (356, 520)):
        o.append(watermelon(mx, my, 15))
    o.append(tx(300, 560, "西瓜田", 14, darker(GRASS, .6)))
    o.append(place(205, 404, 1.45, truck, 3, 2))
    o.append(finger(216, 286, -14))
    o.append(stroke("M-10,422 H400", "#C7B08C", 8, op=.6))
    # the picture sum: 3 and 2 make 5
    o.append(shadow_rect(22, 588, 346, 120, 24, CREAM))
    for i in range(3):
        o.append(watermelon(46 + i * 26, 628, 11))
    o.append(tx(132, 636, "和", 20, SOFT))
    for i in range(2):
        o.append(watermelon(166 + i * 26, 628, 11))
        o.append(f'<circle cx="{166 + i * 26}" cy="628" r="14" fill="none" stroke="{YEL}" stroke-width="2.5"/>')
    o.append(tx(236, 636, "一共", 20, SOFT))
    o.append(numtile(300, 626, 5, 52, GRN))
    o.append(tx(195, 690, "（家長可以打開算式：3 ＋ 2 ＝ 5）", 13, SOFT))
    o.append(place(60, 820, .8, buffalo, "happy"))
    o.append(bubble(118, 740, 248, 52, "點西瓜數一數：一共幾個？", 15, "left"))
    return page("".join(o))


# ================================================================ SCREEN 8: rest, with a 回真實生活 card
def screen_rest():
    o = [f'<rect width="{W}" height="{H}" fill="{lg([(0, "#5C5A8E"), (.55, "#E59A7A"), (1, "#F6CC8E")])}"/>']
    o.append(piece(blob(80, 420, 190, 70, 4, .04, 1), "#7E9C66", shade=0, thick=False))
    o.append(piece(blob(330, 430, 160, 60, 4, .04, 2), "#6E8C5A", shade=0, thick=False))
    o.append(f'<rect x="0" y="420" width="{W}" height="{H - 420}" fill="#8DAA6E"/>')
    o.append(piece(circ(320, 110, 26), "#FFF2C2", shade=0) + f'<circle cx="332" cy="102" r="24" fill="#5E5B8F" opacity=".95"/>')
    for sx, sy in ((60, 70), (120, 130), (240, 60), (200, 160), (360, 190)):
        o.append(sparkle(sx, sy, 5, "#FFF4C8", .9))
    o.append(place(110, 430, 1.1, coop))
    o.append(place(270, 446, 1.1, buffalo, "sleep", False))
    o.append(tx(316, 360, "z", 22, "#FFFFFF") + tx(332, 340, "z", 16, "#FFFFFF"))
    o.append(txo(195, 236, "換你去做了！", 38, INK, CREAM, 10))
    o.append(tx(195, 274, "小農場休息囉，明天再來", 17, "#FFFFFF"))
    # the real-life card
    o.append(shadow_rect(26, 496, 338, 258, 26, CREAM))
    o.append(piece(rr(42, 512, 128, 34, 17), GRN, shade=0) + tx(106, 535, "回真實生活", 16, "#FFFFFF"))
    o.append(tx(46, 584, "吃晚飯的時候，", 19, INK, "start"))
    o.append(tx(46, 614, "幫每個人放一支湯匙。", 19, INK, "start"))
    o.append(tx(46, 644, "數數看，放了幾支？", 19, INK, "start"))
    for i in range(4):
        o.append(spoon(70 + i * 40, 700, -12 + i * 8, 1.0))
    o.append(piece(rr(256, 676, 92, 54, 27), ORA, shade=2) + tx(302, 710, "好！", 22, "#FFFFFF"))
    o.append(lock_chip(174, 778))
    o.append(tx(195, 830, "請爸爸媽媽解開", 14, "#FFFFFF"))
    return page("".join(o))


# ================================================================ SCREEN 9: parents
def seg(x, y, w, labels, sel):
    o = [f'<rect x="{x}" y="{y}" width="{w}" height="36" rx="18" fill="#EFE6D8"/>']
    cw = w / len(labels)
    for i, lb in enumerate(labels):
        if i == sel:
            o.append(piece(rr(x + i * cw + 2, y + 2, cw - 4, 32, 16), ORA, shade=0))
        o.append(tx(x + i * cw + cw / 2, y + 23, lb, 14.5, "#FFFFFF" if i == sel else INK))
    return "".join(o)


def screen_parents():
    o = [f'<rect width="{W}" height="{H}" fill="#F2EBE0"/>']
    o.append(round_btn(36, 42, 21, WOOD, home_icon(36, 45)))
    o.append(tx(195, 50, "家長模式", 24, INK))
    y = 80
    o.append(shadow_rect(16, y, 358, 152, 18, WHITE, .08))
    o.append(tx(32, y + 28, "難度", 16, INK, "start"))
    o.append(seg(32, y + 40, 326, ["小小農夫 3–4", "小農夫 4–5", "大農夫 5–6"], 1))
    o.append(tx(32, y + 104, "每次玩多久", 16, INK, "start"))
    o.append(seg(130, y + 84, 228, ["10", "15 分", "20", "30"], 1))
    o.append(tx(32, y + 140, "數到：10　（小小 5、大 20；可以自己改）", 13, SOFT, "start"))
    y += 166
    o.append(shadow_rect(16, y, 358, 200, 18, WHITE, .08))
    rows = [("加減的算式 ＋ － ＝（只有大農夫）", False), ("回真實生活的卡片", True), ("點錯時牛牛提示", True), ("英文數數（One, two…）", False), ("音樂、音效", True)]
    for i, (lb, on) in enumerate(rows):
        o.append(tx(32, y + 30 + i * 38, lb, 15, INK, "start") + toggle(312, y + 12 + i * 38, on))
    y += 214
    o.append(shadow_rect(16, y, 358, 196, 18, WHITE, .08))
    o.append(tx(32, y + 28, "今天：玩了 12 分鐘，餵小雞、撿雞蛋、分點心", 13.5, INK, "start"))
    o.append(tx(32, y + 54, "數過的數量（越深越常數）", 13.5, SOFT, "start"))
    heat = [5, 5, 5, 5, 4, 4, 4, 3, 3, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0]
    for i, v in enumerate(heat):
        cx, cy = 44 + (i % 10) * 33, y + 84 + (i // 10) * 40
        col = mixc("#EFE6D8", ORA, v / 5)
        o.append(piece(rr(cx - 14, cy - 14, 28, 28, 7), col, shade=0, thick=False))
        o.append(tx(cx, cy + 5, str(i + 1), 13, INK if v < 4 else "#FFFFFF"))
    o.append(tx(32, y + 178, "一眼看出：1～4 很快，5 還在數　｜　分一分：會輪流分", 12.5, SOFT, "start"))
    y += 210
    o.append(shadow_rect(16, y, 358, 92, 18, WHITE, .08))
    o.append(tx(32, y + 28, "回真實生活（打勾的是做過的）", 15, INK, "start"))
    o.append(tx(32, y + 54, "☑ 數湯匙　☑ 數冰箱裡的蛋　☐ 分餅乾", 14, SOFT, "start"))
    o.append(tx(32, y + 78, "☐ 收玩具：放進去幾個、拿出來幾個", 14, SOFT, "start"))
    y += 106
    o.append(piece(rr(16, y, 358, 50, 16), ORA, shade=1) + tx(195, y + 32, "完整版（一次買斷）", 17, "#FFFFFF"))
    return page("".join(o), "#F2EBE0")


# ================================================================ PAGE 0: THE SAME CORNER IN THREE STYLES
def farm_corner(x, y, w=330, h=240):
    o = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{ {"woodcut": "#F3E9D4", "origami": "#D3E7F2"}.get(STYLE, SKY) }"/>']
    k = _clip(rr(x, y, w, h, 14))
    o.append(f'<g clip-path="url(#{k})">')
    if STYLE == "woodcut":
        for i in range(7):
            yy = y + 18 + i * 15 + _rand("sky", i) * 5
            o.append(stroke(f"M{x + 10 + _rand('sx', i) * 60:.1f},{yy:.1f} q60,-3 {120 + _rand('sl', i) * 90:.1f},1", "#9DBFCC", 2.2, op=.8))
    o.append(piece(blob(x + w * .3, y + h * .82, w * .6, h * .35, 4, .04, 1), GRASS, shade=0, thick=False))
    o.append(piece(blob(x + w * .85, y + h * .86, w * .4, h * .3, 4, .04, 2), darker(GRASS, .1), shade=0, thick=False))
    o.append(sun(x + w - 40, y + 38, 18))
    o.append(cloud(x + 150, y + 40, .6))
    o.append(place(x + 62, y + 150, .78, coop))
    o.append(place(x + 40, y + 196, .65, hen))
    o.append(tree(x + 286, y + 182, .55, fruits=((-30, -120), (12, -128), (30, -100), (-12, -96))))
    o.append(egg_tray(x + 228, y + 214, 6, 112, WOOD))
    for i, cx in enumerate((x + 90, x + 122, x + 154)):
        o.append(place(cx, y + 230, .9, chick, "happy" if i == 1 else "smile"))
    o.append(numtile(x + 122, y + 168, 3, 32, ORA))
    o.append("</g>")
    return "".join(o)


def style_sheet():
    global STYLE
    ph = 1300
    o = [f'<rect width="{W}" height="{ph}" fill="#F7F2EA"/>']
    o.append(tx(195, 54, "畫風：三選一", 30, INK))
    o.append(tx(195, 84, "同一個農場角落，三種畫法", 16, SOFT))
    bands = [("A 木頭玩具風", "木頭做的農場玩具：鋸過的厚度、木紋、", "邊角磨圓。東西像真的拿得起來數。", "wood"),
             ("B 摺紙風", "每樣東西都是色紙摺的：一半亮一半暗、", "有摺痕，角是尖尖的多邊形。", "origami"),
             ("C 木刻版畫風", "刻好的木板印在米色紙上：平平的色塊、", "裡面有雕刻刀刻出的白色細痕。", "woodcut")]
    y = 108
    for title, d1, d2, st in bands:
        h = 370
        if st == "wood":
            o.append(f'<rect x="12" y="{y - 4}" width="366" height="{h + 8}" rx="28" fill="#5DB86A"/>')
            o.append(f'<rect x="16" y="{y}" width="358" height="{h}" rx="24" fill="#FFFFFF"/>')
            o.append(f'<rect x="262" y="{y - 14}" width="100" height="30" rx="15" fill="#5DB86A"/>' + tx(312, y + 7, "建議這個", 14, "#FFFFFF"))
        else:
            o.append(f'<rect x="16" y="{y + 4}" width="358" height="{h}" rx="24" fill="#E9DED3"/><rect x="16" y="{y}" width="358" height="{h}" rx="24" fill="#FFFFFF"/>')
        o.append(tx(34, y + 40, title, 22, INK, "start"))
        o.append(tx(34, y + 68, d1, 13.5, "#6E5C52", "start"))
        o.append(tx(34, y + 90, d2, 13.5, "#6E5C52", "start"))
        STYLE = st
        o.append(f'<rect x="30" y="{y + 108}" width="330" height="244" rx="14" fill="{PAPER[st]}"/>')
        o.append(farm_corner(30, y + 110, 330, 240))
        STYLE = "wood"
        y += h + 24
    return page("".join(o), "#F7F2EA", W, ph), ph


# ================================================================ CONTACT SHEET AND MAIN
def contact_sheet(names):
    cw_, ch_, gap, m = 232, 502, 24, 30
    per = 3
    rows = (len(names) + per - 1) // per
    w = per * cw_ + (per - 1) * gap + 2 * m
    rowh = ch_ + 64
    h = rows * rowh + 40
    items = []
    for i, n in enumerate(names):
        r, c = divmod(i, per)
        x = m + c * (cw_ + gap)
        y = 28 + r * rowh
        items.append(f'<div style="position:absolute;left:{x}px;top:{y}px;width:{cw_}px;text-align:center">'
                     f'<img src="file://{HERE / (n + ".png")}" style="width:{cw_}px;height:{ch_}px;border-radius:18px;box-shadow:0 6px 16px rgba(90,60,40,.2)">'
                     f'<div style="font:19px Huninn, sans-serif;color:{INK};margin-top:10px">{n.replace("_", " ")}</div></div>')
    css = f"@font-face {{ font-family: Huninn; src: url('file://{FONT}'); }} * {{ margin:0; padding:0 }} body {{ width:{w}px; height:{h}px; background:#F7F1E8; position:relative }}"
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head><body>{"".join(items)}</body></html>', w, h


SCREENS = {"1_農場": screen_farm, "2_餵小雞": screen_chicks, "3_撿雞蛋": screen_eggs, "4_摘水果": screen_fruit,
           "5_分點心": screen_share, "6_排排隊": screen_pattern, "7_去市場": screen_truck, "8_休息": screen_rest,
           "9_家長模式": screen_parents}


def main(only=None):
    global D
    if only in (None, "0"):
        D = Defs()
        html, ph = style_sheet()
        render(html, HERE / "0_畫風選擇.png", W, ph, 2)
        print("0_畫風選擇")
    for name, make in SCREENS.items():
        if only not in (None, name.split("_")[0]):
            continue
        D = Defs()
        render(make(), HERE / f"{name}.png", W, H, 2)
        print(name)
    if only in (None, "c"):
        html, w, h = contact_sheet(list(SCREENS))
        render(html, HERE / "contact_sheet.png", w, h, 1.25)
        print("contact_sheet")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
