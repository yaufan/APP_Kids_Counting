"""Woodcut-print drawing kit for 數數小農場 (木刻版畫風).

Everything looks printed from carved wood blocks on cream paper: each shape is one flat, slightly
earthy ink colour with a dark ink edge, and a few paper-coloured gouge marks (thin pointed slivers,
all leaning the same way) where the carving knife took wood away. The user chose this style; the
design worried the marks could distract a child counting, so (docs/art.md):

- marks are few, and on a counted thing they sit only near its EDGE: the middle of anything that is
  counted stays one clean blob of colour (`cut(..., marks=...)` keeps them out of a core area);
- small things (an egg, a chick, a fruit, a melon) get at most one or two marks;
- big backgrounds (sky, hills, fields) get the carved lines.

The marks are not clipped with clipPath: shapely intersects every sliver with the shape (minus its
core) here in Python, so the SVG is only plain paths and flutter_svg draws what Chromium draws (no
filter, mask, clipPath, style, text, image or pattern; docs/art.md).

    import kit
    c = kit.Ctx(120, 100)                                # viewBox 0 0 120 100
    c.cut(kit.circle(60, 50, 30), kit.YELLOW, key="sun")  # edge + flat ink + gouge marks at the edge
    c.cut(shape, kit.GREEN, marks=0)                     # no marks
    c.cut(shape, kit.GREEN, marks=8, core=0)             # a background: marks anywhere
    c.flat(shape, kit.INK)                               # flat ink, no edge
    c.stroke(kit.arc(60, 50, 8, 20, 160), kit.INK, 2)    # a line
    c.eyes(60, 40, 10); c.smile(60, 48, 6)               # a face
    kit.write_svg(path, c.svg())                         # checks the rules, then writes

Shapes (`Shape`) are lists of path commands; `+` unions them (all clockwise, nonzero fill),
`.move .scale .flip .rotate`. Deterministic: randomness only via `rnd(key)`.
"""
import colorsys
import hashlib
import math
import pathlib
import random
import re
import xml.etree.ElementTree as ET

from shapely.geometry import Polygon
from shapely.ops import unary_union

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
ART = ROOT / "app" / "assets" / "art"

# ---------------------------------------------------------------- palette (printing inks, a little earthy)
PAPER = "#F6EDD9"      # the cream paper (and the gouge marks)
INK = "#3B2A1E"        # the dark ink: edges, eyes, lines
RED = "#C8553D"
BRICK = "#A8483A"
PINK = "#E6A49A"
ORANGE = "#E08A3A"
YELLOW = "#EDBE3F"     # the chicks
GOLD = "#D9A53A"
CREAM = "#FBF4E4"      # eggs, the hen
GREEN = "#86AE5E"
LEAF = "#5E8C4A"
OLIVE = "#9DB86A"
SKY = "#BFD9DE"
BLUE = "#4F7FA8"
NAVY = "#34506E"
WOOD = "#D3A46C"
BROWN = "#94653F"
DARKWOOD = "#6E4A2E"
SOIL = "#B98A5E"
PURPLE = "#7D5B8E"
GREY = "#8E8A86"
BUFFALO = "#7E7682"
SKIN = "#EBC29C"
CHEEK = "#E58F7E"

PLACES = {"chicks": YELLOW, "eggs": ORANGE, "fruit": GREEN, "share": PINK, "garden": OLIVE, "market": BLUE}


def _rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def _hex(r, g, b):
    return "#%02X%02X%02X" % tuple(max(0, min(255, round(v))) for v in (r, g, b))


def mix(a, b, t):
    """Colour a moved t (0..1) of the way to colour b."""
    return _hex(*[x + (y - x) * t for x, y in zip(_rgb(a), _rgb(b))])


def lt(c, t):
    return mix(c, PAPER, t)


def dk(c, t):
    return mix(c, INK, t)


def edge_of(c):
    """The dark ink edge of a shape printed in c."""
    return mix(c, INK, .72)


def tone(c, l=1.0, s=1.0, dh=0.0):
    h, L, S = colorsys.rgb_to_hls(*[x / 255 for x in _rgb(c)])
    r, g, b = colorsys.hls_to_rgb((h + dh) % 1, max(0, min(1, L * l)), max(0, min(1, S * s)))
    return _hex(r * 255, g * 255, b * 255)


def rnd(*key):
    h = hashlib.md5("|".join(map(str, key)).encode()).hexdigest()
    return random.Random(int(h[:12], 16))


# ---------------------------------------------------------------- numbers
def n(v):
    """A number, short: one decimal, no trailing .0, no -0."""
    s = f"{v:.1f}"
    if s.endswith(".0"):
        s = s[:-2]
    if s == "-0":
        s = "0"
    return s


# ---------------------------------------------------------------- shapes
KAPPA = 0.5522847498


class Shape:
    """Path commands: ('M', x, y) ('L', x, y) ('C', x1, y1, x2, y2, x, y) ('Z',). All shapes the kit
    makes wind clockwise on screen, so unions (`a + b`) fill with the default nonzero rule."""

    def __init__(self, cmds=None):
        self.cmds = list(cmds or [])

    def __add__(self, other):
        return Shape(self.cmds + other.cmds)

    def move(self, dx, dy):
        return self.map(lambda x, y: (x + dx, y + dy))

    def scale(self, s, cx=0.0, cy=0.0, sy=None):
        sy = s if sy is None else sy
        return self.map(lambda x, y: (cx + (x - cx) * s, cy + (y - cy) * sy))

    def flip(self, cx):
        """Mirror left-right about x = cx (winding is fixed afterwards)."""
        return self.map(lambda x, y: (2 * cx - x, y)).reverse()

    def rotate(self, deg, cx, cy):
        a = math.radians(deg)
        ca, sa = math.cos(a), math.sin(a)
        return self.map(lambda x, y: (cx + (x - cx) * ca - (y - cy) * sa, cy + (x - cx) * sa + (y - cy) * ca))

    def map(self, f):
        out = []
        for c in self.cmds:
            if c[0] == "Z":
                out.append(c)
            else:
                pts = [f(c[i], c[i + 1]) for i in range(1, len(c), 2)]
                out.append((c[0],) + tuple(v for p in pts for v in p))
        return Shape(out)

    def reverse(self):
        """The same outline the other way round (one subpath at a time)."""
        out = []
        for sub in self.subpaths():
            pts = []   # (point, incoming control pair or None)
            cur = None
            for c in sub:
                if c[0] == "M":
                    cur = (c[1], c[2])
                    pts.append((cur, None))
                elif c[0] == "L":
                    cur = (c[1], c[2])
                    pts.append((cur, None))
                elif c[0] == "C":
                    cur = (c[5], c[6])
                    pts.append((cur, (c[1], c[2], c[3], c[4])))
            rev = pts[::-1]
            out.append(("M",) + rev[0][0])
            for i in range(1, len(rev)):
                p, _ = rev[i]
                _, ctrl = rev[i - 1]      # the control pair that led INTO rev[i-1] from rev[i]
                if ctrl is None:
                    out.append(("L",) + p)
                else:
                    out.append(("C", ctrl[2], ctrl[3], ctrl[0], ctrl[1]) + p)
            out.append(("Z",))
        return Shape(out)

    def subpaths(self):
        subs, cur = [], []
        for c in self.cmds:
            if c[0] == "M" and cur:
                subs.append(cur)
                cur = []
            cur.append(c)
        if cur:
            subs.append(cur)
        return subs

    def bbox(self):
        xs = [c[i] for c in self.cmds if c[0] != "Z" for i in range(1, len(c), 2)]
        ys = [c[i] for c in self.cmds if c[0] != "Z" for i in range(2, len(c), 2)]
        return min(xs), min(ys), max(xs), max(ys)

    def d(self, dx=0.0, dy=0.0):
        out = []
        for c in self.cmds:
            if c[0] == "Z":
                out.append("Z")
            else:
                nums = [n(c[i] + (dx if i % 2 else dy)) for i in range(1, len(c))]
                out.append(c[0] + " ".join(nums))
        return "".join(out)


def poly(points, close=True):
    """A polygon through points (any winding; it is made clockwise)."""
    pts = [tuple(p) for p in points]
    area = sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1] for i in range(len(pts)))
    if area < 0:      # counter-clockwise on screen (y down) -> reverse
        pts = pts[::-1]
    cmds = [("M",) + pts[0]] + [("L",) + p for p in pts[1:]]
    if close:
        cmds.append(("Z",))
    return Shape(cmds)


def rrect(x, y, w, h, r=8.0, rtl=None, rtr=None, rbr=None, rbl=None):
    """A rounded rectangle; corner radii can differ."""
    r = min(r, w / 2, h / 2)
    a, b, c_, d = [min(v if v is not None else r, w / 2, h / 2) for v in (rtl, rtr, rbr, rbl)]
    k = KAPPA
    cmds = [("M", x + a, y), ("L", x + w - b, y)]
    if b:
        cmds.append(("C", x + w - b + b * k, y, x + w, y + b - b * k, x + w, y + b))
    cmds.append(("L", x + w, y + h - c_))
    if c_:
        cmds.append(("C", x + w, y + h - c_ + c_ * k, x + w - c_ + c_ * k, y + h, x + w - c_, y + h))
    cmds.append(("L", x + d, y + h))
    if d:
        cmds.append(("C", x + d - d * k, y + h, x, y + h - d + d * k, x, y + h - d))
    cmds.append(("L", x, y + a))
    if a:
        cmds.append(("C", x, y + a - a * k, x + a - a * k, y, x + a, y))
    cmds.append(("Z",))
    return Shape(cmds)


def rect(x, y, w, h):
    return rrect(x, y, w, h, 0)


def ellipse(cx, cy, rx, ry=None):
    ry = rx if ry is None else ry
    k = KAPPA
    return Shape([
        ("M", cx + rx, cy),
        ("C", cx + rx, cy + ry * k, cx + rx * k, cy + ry, cx, cy + ry),
        ("C", cx - rx * k, cy + ry, cx - rx, cy + ry * k, cx - rx, cy),
        ("C", cx - rx, cy - ry * k, cx - rx * k, cy - ry, cx, cy - ry),
        ("C", cx + rx * k, cy - ry, cx + rx, cy - ry * k, cx + rx, cy),
        ("Z",)])


def circle(cx, cy, r):
    return ellipse(cx, cy, r, r)


def smooth(points, tension=0.5):
    """A closed, smooth (Catmull-Rom) curve through points, clockwise."""
    pts = [tuple(p) for p in points]
    area = sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1] for i in range(len(pts)))
    if area < 0:
        pts = pts[::-1]
    m = len(pts)
    cmds = [("M",) + pts[0]]
    for i in range(m):
        p0, p1, p2, p3 = pts[(i - 1) % m], pts[i], pts[(i + 1) % m], pts[(i + 2) % m]
        c1 = (p1[0] + (p2[0] - p0[0]) * tension / 3, p1[1] + (p2[1] - p0[1]) * tension / 3)
        c2 = (p2[0] - (p3[0] - p1[0]) * tension / 3, p2[1] - (p3[1] - p1[1]) * tension / 3)
        cmds.append(("C",) + c1 + c2 + p2)
    cmds.append(("Z",))
    return Shape(cmds)


def blob(cx, cy, rx, ry=None, lumps=7, wobble=0.12, key="blob"):
    """A soft potato shape (a bush, a cushion, a cloud body): an ellipse with seeded bumps."""
    ry = rx if ry is None else ry
    r = rnd("blob", key, lumps)
    pts = []
    for i in range(lumps):
        a = 2 * math.pi * i / lumps
        f = 1 + r.uniform(-wobble, wobble)
        pts.append((cx + rx * f * math.cos(a), cy + ry * f * math.sin(a)))
    return smooth(pts, 0.9)


def cloud(cx, cy, w, h, puffs=4):
    """A cloud / bush: a flat base with round puffs on top (a union of shapes)."""
    s = rrect(cx - w / 2, cy - h * .1, w, h * .6, h * .3)
    for i in range(puffs):
        t = (i + .5) / puffs
        px = cx - w / 2 + w * t
        pr = h * (.42 if i % 2 == 0 else .34)
        s = s + circle(px, cy - h * .15 + (0 if i % 2 == 0 else h * .1), pr)
    return s


def star(cx, cy, R, r=None, points=5, rot=-90.0):
    r = R * .48 if r is None else r
    pts = []
    for i in range(points * 2):
        a = math.radians(rot + 180.0 * i / points)
        rad = R if i % 2 == 0 else r
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    return poly(pts)


def heart(cx, cy, s):
    """A heart about s wide, centred on cx, cy."""
    w, h = s, s * .95
    x0, y0 = cx, cy - h * .3          # the notch
    return Shape([
        ("M", x0, y0),
        ("C", x0 + w * .1, y0 - h * .3, x0 + w * .5, y0 - h * .3, x0 + w * .5, y0 + h * .05),
        ("C", x0 + w * .5, y0 + h * .4, x0 + w * .15, y0 + h * .55, x0, y0 + h * .75),
        ("C", x0 - w * .15, y0 + h * .55, x0 - w * .5, y0 + h * .4, x0 - w * .5, y0 + h * .05),
        ("C", x0 - w * .5, y0 - h * .3, x0 - w * .1, y0 - h * .3, x0, y0),
        ("Z",)])


def path(points, closed=False):
    """An open polyline (for strokes) or closed polygon."""
    pts = [tuple(p) for p in points]
    cmds = [("M",) + pts[0]] + [("L",) + p for p in pts[1:]]
    if closed:
        cmds.append(("Z",))
    return Shape(cmds)


def arc(cx, cy, r, a0, a1, steps=None):
    """An open arc (degrees, clockwise on screen) made of cubic pieces, for smiles and the like."""
    span = a1 - a0
    steps = steps or max(1, int(abs(span) / 90) + 1)
    cmds = []
    for i in range(steps):
        t0 = math.radians(a0 + span * i / steps)
        t1 = math.radians(a0 + span * (i + 1) / steps)
        k = 4 / 3 * math.tan((t1 - t0) / 4)
        p0 = (cx + r * math.cos(t0), cy + r * math.sin(t0))
        p3 = (cx + r * math.cos(t1), cy + r * math.sin(t1))
        p1 = (p0[0] - k * r * math.sin(t0), p0[1] + k * r * math.cos(t0))
        p2 = (p3[0] + k * r * math.sin(t1), p3[1] - k * r * math.cos(t1))
        if i == 0:
            cmds.append(("M",) + p0)
        cmds.append(("C",) + p1 + p2 + p3)
    return Shape(cmds)


def ring(cx, cy, r_out, r_in):
    """A ring (needs even-odd: pass rule='evenodd' to flat())."""
    return circle(cx, cy, r_out) + circle(cx, cy, r_in)


def soft_rect(x, y, w, h):
    """A pill / very round rectangle (the usual marshmallow block)."""
    return rrect(x, y, w, h, min(w, h) * .45)


def puffs(cx, cy, w, h, n=5, key="puffs"):
    """A cloud: a soft base with round puffs on top, n puffs, seeded sizes."""
    r = rnd("puffs", key, n)
    s = rrect(cx - w / 2, cy - h * .05, w, h * .55, h * .27)
    for i in range(n):
        t = (i + .5) / n
        px = cx - w / 2 + w * (.08 + .84 * t)
        pr = h * (.30 + .14 * math.sin(math.pi * t)) * r.uniform(.9, 1.1)
        s = s + circle(px, cy - h * .02 - pr * .35, pr)
    return s


# ---------------------------------------------------------------- shapely (for the gouge marks)
def _flatten(sub, steps=10):
    """The points of one subpath, curves cut into straight pieces."""
    pts, cur = [], None
    for c in sub:
        if c[0] in "ML":
            cur = (c[1], c[2])
            pts.append(cur)
        elif c[0] == "C":
            p0, p1, p2, p3 = cur, (c[1], c[2]), (c[3], c[4]), (c[5], c[6])
            for i in range(1, steps + 1):
                t = i / steps
                u = 1 - t
                pts.append((u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
                            u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1]))
            cur = p3
    return pts


def geom(shape):
    """The shape as a shapely geometry (the union of its subpaths: nonzero fill, all clockwise)."""
    polys = []
    for sub in shape.subpaths():
        pts = _flatten(sub)
        if len(pts) >= 3:
            p = Polygon(pts)
            if not p.is_valid:
                p = p.buffer(0)
            if not p.is_empty:
                polys.append(p)
    return unary_union(polys) if polys else Polygon()


def from_geom(g):
    """A shapely (multi)polygon as a Shape of straight lines (holes are dropped: none are needed)."""
    out = Shape()
    parts = getattr(g, "geoms", [g])
    for p in parts:
        if p.is_empty or p.geom_type != "Polygon" or p.area < .6:
            continue
        pts = list(p.exterior.coords)[:-1]
        if len(pts) >= 3:
            out = out + poly([(round(x, 1), round(y, 1)) for x, y in pts])
    return out


def sliver(x, y, length, angle, width):
    """One gouge mark: a thin four-point lens from (x, y), `length` long at `angle` degrees."""
    a = math.radians(angle)
    ex, ey = x + length * math.cos(a), y + length * math.sin(a)
    mx, my = x + (ex - x) * .42, y + (ey - y) * .42
    nx, ny = -math.sin(a) * width / 2, math.cos(a) * width / 2
    return Polygon([(x, y), (mx + nx, my + ny), (ex, ey), (mx - nx, my - ny)])


# ---------------------------------------------------------------- the SVG writer
class Ctx:
    """One SVG file being drawn: viewBox 0 0 w h."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.body = []
        self.defs = {}
        self._open = 0

    # ---- gradients (used sparingly: a woodcut is flat; only the sky behind the carved lines)
    def _grad(self, kind, attrs, stops):
        st = "".join(f'<stop offset="{o:g}" stop-color="{c}"' + (f' stop-opacity="{a:.2f}"' if a < 1 else "") + "/>"
                     for o, c, a in stops)
        key = hashlib.md5((kind + attrs + st).encode()).hexdigest()[:8]
        gid = f"g{key}"
        self.defs.setdefault(gid, f'<{kind} id="{gid}" gradientUnits="userSpaceOnUse" {attrs}>{st}</{kind}>')
        return f"url(#{gid})"

    def linear(self, x1, y1, x2, y2, stops):
        return self._grad("linearGradient", f'x1="{n(x1)}" y1="{n(y1)}" x2="{n(x2)}" y2="{n(y2)}"', stops)

    # ---- raw
    def path_el(self, d, fill="none", stroke=None, sw=0.0, op=1.0, cap="round"):
        if not d:
            return
        a = [f'd="{d}"', f'fill="{fill}"']
        if stroke:
            a += [f'stroke="{stroke}"', f'stroke-width="{n(sw)}"', f'stroke-linecap="{cap}"', 'stroke-linejoin="round"']
        if op < 1:
            a.append(f'fill-opacity="{op:.2f}"' if fill != "none" else f'stroke-opacity="{op:.2f}"')
        self.body.append("<path " + " ".join(a) + "/>")

    # ---- the woodcut piece
    def cut(self, shape, col, edge=1.6, marks="auto", core=.42, key=None, angle=-28, mark_col=PAPER, edge_col=None,
            op=1.0, length=(.3, .55), mark_op=.9):
        """One printed shape: a dark ink edge (a stroke drawn behind the flat colour, so the seams of a
        union never show), the flat ink, then `marks` gouge marks in the paper colour.

        marks: a number, or "auto" (1 for a small thing, up to 6 for a big one); 0 for none.
        core: the middle that stays clean, as a fraction of the shape's smaller side (0: marks may go
        anywhere, for backgrounds). A counted thing keeps the default."""
        d = shape.d()
        if edge:
            self.path_el(d, "none", edge_col or edge_of(col), edge * 2, op=op)
        self.path_el(d, col, op=op)
        g = geom(shape)
        if g.is_empty:
            return
        x0, y0, x1, y1 = g.bounds
        w, h = x1 - x0, y1 - y0
        small = min(w, h)
        if marks == "auto":
            marks = 0 if small < 9 else (1 if g.area < 900 else 2 if g.area < 2500 else min(6, int(g.area / 1600)))
        if not marks:
            return
        allowed = g.buffer(-max(.8, edge * .6))
        if core:
            allowed = allowed.difference(g.buffer(-small * core / 2 * 1.0).buffer(small * .02))
            # Keep the marks in the lower right and upper left rims, away from the face or the middle.
        r = rnd("cut", key or d[:80], marks)
        found = Shape()
        tries = 0
        placed = 0
        while placed < marks and tries < marks * 25:
            tries += 1
            px = x0 + w * r.uniform(.05, .95)
            py = y0 + h * r.uniform(.05, .95)
            ln = small * r.uniform(*length) if core else min(w, h, 60) * r.uniform(.5, 1.0) + r.uniform(4, 16)
            s = sliver(px, py, ln, angle + r.uniform(-7, 7), max(1.0, min(3.2, ln * .1)))
            piece = s.intersection(allowed)
            if piece.is_empty or piece.area < s.area * .55:
                continue
            found = found + from_geom(piece)
            placed += 1
        if found.cmds:
            self.path_el(found.d(), mark_col, op=mark_op * op)

    def carve_lines(self, x0, y0, x1, y1, rows, col=PAPER, op=.75, key="lines", width=1.6, gap=.18):
        """Long thin carved lines across a background area (the sky of a woodcut)."""
        r = rnd("carve", key, rows)
        h = (y1 - y0) / rows
        s = Shape()
        for i in range(rows):
            y = y0 + h * (i + .5) + r.uniform(-h * .2, h * .2)
            xa = x0 + (x1 - x0) * r.uniform(0, gap * 2)
            xb = x1 - (x1 - x0) * r.uniform(0, gap * 2)
            wv = width * r.uniform(.6, 1.1)
            bend = r.uniform(-2.5, 2.5)
            s = s + Shape([("M", xa, y), ("C", xa + (xb - xa) * .3, y - wv + bend, xb - (xb - xa) * .3, y - wv - bend, xb, y),
                           ("C", xb - (xb - xa) * .3, y + wv - bend, xa + (xb - xa) * .3, y + wv + bend, xa, y), ("Z",)])
        self.path_el(s.d(), col, op=op)

    def flat(self, shape, col, op=1.0):
        self.path_el(shape.d(), col, op=op)

    def fill(self, shape, paint, op=1.0):
        self.path_el(shape.d(), paint, op=op)

    def stroke(self, shape, col=INK, w=2.0, op=1.0, cap="round"):
        self.path_el(shape.d(), "none", col, w, op=op, cap=cap)

    def dots(self, points, r, col, op=1.0):
        s = Shape()
        for x, y in points:
            s = s + circle(x, y, r)
        self.flat(s, col, op)

    # ---- faces (ink, no shine: printed)
    def eyes(self, cx, cy, gap, r=None, closed=False, happy=False):
        r = r or gap * .17
        for x in (cx - gap / 2, cx + gap / 2):
            if closed:
                self.stroke(arc(x, cy - r * .6, r * 1.2, 30, 150), INK, r * .75)
            elif happy:
                self.stroke(arc(x, cy + r * .9, r * 1.25, 210, 330), INK, r * .75)
            else:
                self.flat(ellipse(x, cy, r, r * 1.15), INK)
                self.flat(circle(x - r * .3, cy - r * .4, r * .32), PAPER)

    def cheeks(self, cx, cy, gap, r, op=.7):
        for x in (cx - gap / 2, cx + gap / 2):
            self.flat(ellipse(x, cy, r, r * .66), CHEEK, op)

    def smile(self, cx, cy, w, open_=False, col=INK):
        if open_:
            self.flat(Shape([("M", cx - w / 2, cy), ("C", cx - w * .4, cy + w * .75, cx + w * .4, cy + w * .75, cx + w / 2, cy),
                             ("Z",)]), "#B5483F")
            self.stroke(Shape([("M", cx - w / 2, cy), ("C", cx - w * .4, cy + w * .75, cx + w * .4, cy + w * .75, cx + w / 2, cy),
                               ("Z",)]), INK, max(1, w * .1))
        else:
            self.stroke(arc(cx, cy - w * .45, w * .55, 35, 145), col, max(1.2, w * .16))

    def face(self, cx, cy, gap, open_=False, blush=True, closed=False, happy=False):
        self.eyes(cx, cy, gap, closed=closed, happy=happy)
        if blush:
            self.cheeks(cx, cy + gap * .42, gap * 1.45, gap * .2)
        self.smile(cx, cy + gap * .42, gap * .55, open_)

    # ---- groups
    def begin(self, transform=None, op=None):
        a = ""
        if transform:
            a += f' transform="{transform}"'
        if op is not None:
            a += f' opacity="{op:.2f}"'
        self.body.append(f"<g{a}>")
        self._open += 1

    def end(self):
        self.body.append("</g>")
        self._open -= 1

    def svg(self):
        if self._open:
            raise SystemExit("Ctx: a <g> was not closed")
        defs = f"<defs>{''.join(self.defs[k] for k in sorted(self.defs))}</defs>" if self.defs else ""
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {n(self.w)} {n(self.h)}">'
                f'{defs}{"".join(self.body)}</svg>\n')


# ---------------------------------------------------------------- checks (docs/art.md: flutter_svg)
FORBIDDEN = ("<filter", "<mask", "<style", "style=", "class=", "<text", "<image", "<foreignObject", "<pattern",
             "mix-blend-mode", "mask=", "filter=", "vector-effect", "<symbol", "<marker", "@import", "<clipPath",
             "clip-path=")
_TOK = re.compile(r"[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?")
_NARGS = {"M": 2, "L": 2, "H": 1, "V": 1, "C": 6, "S": 4, "Q": 4, "T": 2, "A": 7, "Z": 0}
DRAWN = {"path", "ellipse", "circle", "rect", "polygon", "polyline", "line", "use"}
MAX_KB = 80


def check_path(d):
    """ValueError unless d is path data flutter_svg reads (it drops the WHOLE picture over one bad
    path, where Chromium only skips that path)."""
    toks = _TOK.findall(d)
    if not toks or toks[0] not in "Mm":
        raise ValueError(f"path does not start with M: {d[:40]!r}")
    if len("".join(toks)) != len(re.sub(r"[\s,]", "", d)):
        raise ValueError(f"stray characters in path: {d[:60]!r}")
    i = 0
    while i < len(toks):
        cmd = toks[i]
        if not cmd.isalpha():
            raise ValueError(f"numbers without a command: {d[:60]!r}")
        i += 1
        k = _NARGS[cmd.upper()]
        j = i
        while j < len(toks) and not toks[j].isalpha():
            j += 1
        cnt = j - i
        if (k == 0 and cnt) or (k and (cnt == 0 or cnt % k)):
            raise ValueError(f"command {cmd} has {cnt} numbers: {d[:60]!r}")
        i = j


def check_svg(name, text, size=None):
    """docs/art.md's rules: no filter/mask/style/text/image/pattern/blend, every drawn element has
    fill or stroke, under 70 KB, well-formed XML ending in </svg>, viewBox 0 0 w h (= size if given),
    parseable path data. Returns the size in KB; SystemExit on a problem."""
    bad = [f for f in FORBIDDEN if f in text]
    if bad:
        raise SystemExit(f"{name}: uses {bad} (flutter_svg cannot draw these)")
    kb = len(text.encode()) / 1024
    if kb > MAX_KB:
        raise SystemExit(f"{name}: {kb:.0f} KB (keep under {MAX_KB} KB)")
    if not text.rstrip().endswith("</svg>"):
        raise SystemExit(f"{name}: does not end with </svg>")
    try:
        root = ET.fromstring(text)
    except ET.ParseError as e:
        raise SystemExit(f"{name}: not well-formed XML: {e}")
    ns = "{http://www.w3.org/2000/svg}"
    if root.tag != f"{ns}svg":
        raise SystemExit(f"{name}: root is not <svg xmlns=...>")
    vb = root.get("viewBox")
    if not vb:
        raise SystemExit(f"{name}: no viewBox")
    vb = [float(v) for v in vb.split()]
    if vb[0] or vb[1]:
        raise SystemExit(f"{name}: viewBox must start at 0 0")
    if size and (abs(vb[2] - size[0]) > .01 or abs(vb[3] - size[1]) > .01):
        raise SystemExit(f"{name}: viewBox {vb[2]:g} x {vb[3]:g}, expected {size[0]:g} x {size[1]:g}")
    defs = root.find(f"{ns}defs")
    in_defs = {id(el) for el in defs.iter()} if defs is not None else set()
    for el in root.iter():
        tag = el.tag.replace(ns, "")
        d = el.get("d")
        if d is not None:
            try:
                check_path(d)
            except ValueError as e:
                raise SystemExit(f"{name}: {e}")
        if tag in DRAWN and id(el) not in in_defs and el.get("fill") is None and el.get("stroke") is None:
            raise SystemExit(f"{name}: a <{tag}> without fill/stroke")
        for a in ("fill", "stroke"):
            v = el.get(a)
            if v and v.startswith("url(#") and root.find(f".//*[@id='{v[5:-1]}']") is None:
                raise SystemExit(f"{name}: {a} points to a missing {v}")
    return kb


def viewbox_of(path):
    """(w, h) of an SVG file's viewBox."""
    vb = [float(v) for v in ET.parse(path).getroot().get("viewBox").split()]
    return vb[2], vb[3]


def write_svg(path, text, size=None):
    """Check, then write. Returns the size in KB."""
    path = pathlib.Path(path)
    name = str(path.relative_to(ROOT)) if ROOT in path.parents else str(path)
    kb = check_svg(name, text, size)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    return kb
