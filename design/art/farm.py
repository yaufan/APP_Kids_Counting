"""The farm and its places (woodcut prints, kit.py), in app/assets/art/farm/, and where things go on the
home page (app/lib/app/farm_layout.dart, written here: do not edit it by hand).

- home (390 x 620): the farm seen from above the hill: carved sky, hills, the dirt path and the six
  places (hen house, nests, fruit tree, pigsty, vegetable rows, the blue truck). The app puts the
  signs, 阿嬤, 牛牛, the chick sign and what the farm has grown on top (farm_layout.dart).
- sky (390 x 260) and hills (390 x 140): the top and bottom of every activity's page.
- coop 160 x 140, bucket 100 x 100, haystack 220 x 110, nest 140 x 60, tree 240 x 250, basket
  160 x 90, plate 120 x 44, fence 390 x 90, bed 380 x 70 (the soil of the vegetable row), crate
  100 x 80 (a seed box), river 390 x 120 (with a plank bridge), shelf 300 x 40, truck 360 x 170, field
  300 x 70, stall 200 x 150; sun, cloud, moon, star.
"""
import sys

sys.dont_write_bytecode = True

import kit  # noqa: E402
from kit import Shape, circle, ellipse, poly, rect, rrect, smooth  # noqa: E402

OUT = kit.ART / "farm"
LAYOUT = kit.ROOT / "app" / "lib" / "app" / "farm_layout.dart"

HW, HH = 390, 620
# Where the six places stand on the home page (their picture's middle), in home units.
SPOTS = {"chicks": (92, 222), "eggs": (292, 218), "fruit": (96, 352), "share": (292, 352), "garden": (96, 478), "market": (288, 478)}
# The chicks the farm has hatched wander here (up to 10), the tree's fruit, the new vegetables.
HATCH = [(150, 262), (172, 250), (196, 262), (160, 282), (214, 280), (186, 292), (138, 300), (226, 300), (204, 312), (168, 316)]
TREE_FRUIT = [(78, 316), (110, 312), (94, 332), (64, 340), (124, 338), (100, 300)]
SPROUTS = [(36, 520), (60, 526), (84, 520), (108, 526), (132, 520), (156, 526)]
MELONS = [(332, 532), (352, 540), (312, 540), (372, 532)]


def sky_band(c, x0, y0, x1, y1, rows, key):
    c.flat(rect(x0, y0, x1 - x0, y1 - y0), kit.SKY)
    c.carve_lines(x0, y0 + 6, x1, y1 - 6, rows, key=key, op=.8)


def hill(c, pts, col, key, marks=4):
    c.cut(smooth(pts, .7), col, key=key, marks=marks, core=0, edge=1.4)


def sun(c, x, y, r):
    for i in range(8):
        import math
        a = math.radians(i * 45)
        c.stroke(Shape([("M", x + (r + 4) * math.cos(a), y + (r + 4) * math.sin(a)), ("L", x + (r + 11) * math.cos(a), y + (r + 11) * math.sin(a))]),
                 kit.GOLD, 3)
    c.cut(circle(x, y, r), kit.YELLOW, key="sun", marks=2, core=0)
    c.face(x, y, r * .55, blush=True, happy=True)


def cloud(c, x, y, w):
    c.cut(kit.puffs(x, y, w, w * .45, n=4, key=f"cloud{x}"), kit.PAPER, marks=0, edge=1.2)


def coop_at(c, x, y, s=1.0):
    """The hen house: a wooden box with a red roof and a round door; (x, y) the middle of its base."""
    w, h = 120 * s, 70 * s
    c.cut(rect(x - w / 2, y - h, w, h), kit.WOOD, key=f"coop{x}", marks=3, core=0)
    for i in range(1, 4):
        c.stroke(Shape([("M", x - w / 2, y - h + h * i / 4), ("L", x + w / 2, y - h + h * i / 4)]), kit.dk(kit.WOOD, .3), 1.2, op=.6)
    c.cut(poly([(x - w / 2 - 12 * s, y - h), (x, y - h - 46 * s), (x + w / 2 + 12 * s, y - h)]), kit.RED, key=f"roof{x}", marks=2, core=0)
    c.cut(Shape([("M", x - 16 * s, y), ("L", x - 16 * s, y - 26 * s), ("C", x - 16 * s, y - 46 * s, x + 16 * s, y - 46 * s, x + 16 * s, y - 26 * s),
                 ("L", x + 16 * s, y), ("Z",)]), kit.DARKWOOD, marks=0)
    c.cut(circle(x, y - h - 18 * s, 7 * s), kit.PAPER, marks=0, edge=1.2)
    c.stroke(Shape([("M", x + 16 * s, y - 4 * s), ("L", x + 40 * s, y + 10 * s)]), kit.BROWN, 4 * s)


def nest_at(c, x, y, w):
    c.cut(ellipse(x, y, w / 2, w * .2), "#D2AE62", key=f"nest{x}{y}", marks=0)
    for i in range(6):
        xx = x - w * .4 + i * w * .16
        c.stroke(Shape([("M", xx, y - 3), ("C", xx + w * .03, y + 3, xx + w * .1, y + 3, xx + w * .14, y - 1)]), "#9E7A3A", 1.4)


def tree_at(c, x, y, s=1.0, key="tree"):
    """A round fruit tree; (x, y) the foot of its trunk."""
    c.cut(rrect(x - 9 * s, y - 70 * s, 18 * s, 70 * s, 5 * s), kit.BROWN, marks=1, key=key + "trunk")
    crown = kit.blob(x, y - 100 * s, 66 * s, 54 * s, lumps=9, wobble=.1, key=key)
    c.cut(crown, kit.LEAF, key=key + "crown", marks=4, core=.3)


def fence_at(c, x0, x1, y, h=40):
    posts = Shape()
    xx = x0
    while xx <= x1:
        posts = posts + poly([(xx - 5, y), (xx - 5, y - h + 6), (xx, y - h), (xx + 5, y - h + 6), (xx + 5, y)])
        xx += 22
    c.cut(rect(x0 - 6, y - h * .72, x1 - x0 + 12, 6) + rect(x0 - 6, y - h * .32, x1 - x0 + 12, 6), kit.WOOD, marks=0, edge=1.2)
    c.cut(posts, kit.lt(kit.WOOD, .2), marks=0, edge=1.2)


def truck_at(c, x, y, s=1.0, key="truck"):
    """The little blue truck (發財車), facing right; (x, y) the middle of the ground under it."""
    def P(px, py):
        return (x + (px - 180) * s, y + (py - 170) * s)
    cab = Shape([("M", *P(240, 140)), ("L", *P(240, 60)), ("C", *P(240, 50), *P(248, 44), *P(258, 44)), ("L", *P(300, 44)),
                 ("C", *P(312, 44), *P(318, 50), *P(322, 60)), ("L", *P(344, 100)), ("C", *P(352, 104), *P(354, 110), *P(354, 118)),
                 ("L", *P(354, 140)), ("Z",)])
    c.cut(cab, kit.BLUE, key=key + "cab", marks=2, core=.3)
    c.cut(Shape([("M", *P(262, 56)), ("L", *P(302, 56)), ("L", *P(326, 96)), ("L", *P(262, 96)), ("Z",)]), kit.SKY, marks=0, edge=1.2)
    bed = rect(*P(14, 104), 232 * s, 38 * s)
    c.cut(bed, kit.BLUE, key=key + "bed", marks=2, core=0)
    c.stroke(Shape([("M", *P(14, 118)), ("L", *P(246, 118))]), kit.dk(kit.BLUE, .4), 1.4, op=.7)
    c.cut(rrect(*P(12, 138), 344 * s, 12 * s, 4 * s), kit.NAVY, marks=0)
    for wx in (70, 290):
        c.cut(circle(*P(wx, 152), 20 * s), kit.INK, marks=0, edge=1)
        c.cut(circle(*P(wx, 152), 8 * s), kit.GREY, marks=0, edge=1)
    c.cut(circle(*P(350, 122), 5 * s), kit.YELLOW, marks=0, edge=1)


def pig_mini(c, x, y, s=1.0):
    pk = "#E9A5A0"
    c.cut(poly([(x - 12 * s, y - 14 * s), (x - 10 * s, y - 26 * s), (x - 2 * s, y - 18 * s)]) + poly([(x + 12 * s, y - 14 * s), (x + 10 * s, y - 26 * s), (x + 2 * s, y - 18 * s)]), pk, marks=0, edge=1)
    c.cut(circle(x, y - 8 * s, 14 * s), pk, marks=0, edge=1.2)
    c.eyes(x, y - 11 * s, 9 * s, r=1.6 * s)
    c.cut(ellipse(x, y - 4 * s, 5 * s, 3.6 * s), kit.lt(pk, .35), marks=0, edge=.8)


def veg_rows(c, x, y, w, key):
    c.cut(rrect(x - w / 2, y - 14, w, 28, 12), kit.SOIL, key=key, marks=2, core=0)
    for i in range(5):
        xx = x - w * .4 + i * w * .2
        c.cut(circle(xx, y - 14, 9), "#8DB86A", marks=0, edge=1.1)
        c.flat(ellipse(xx, y - 15, 5, 4), "#B6D48A")


def home():
    c = kit.Ctx(HW, HH)
    sky_band(c, 0, 0, HW, 190, 9, "homesky")
    sun(c, 334, 52, 24)
    cloud(c, 70, 52, 70)
    cloud(c, 200, 96, 54)
    hill(c, [(-40, 210), (80, 150), (220, 170), (330, 140), (440, 180), (440, 700), (-40, 700)], kit.OLIVE, "hill1", 5)
    hill(c, [(-40, 300), (120, 250), (300, 280), (440, 240), (440, 700), (-40, 700)], kit.GREEN, "hill2", 6)
    # The dirt path from place to place.
    road = Shape([("M", 110, 250), ("C", 200, 230, 240, 250, 280, 250), ("C", 330, 252, 330, 300, 270, 330), ("C", 200, 360, 130, 330, 110, 380),
                  ("C", 96, 420, 160, 440, 220, 450), ("C", 280, 460, 290, 470, 300, 500)])
    c.stroke(road, kit.dk(kit.SOIL, .35), 26)
    c.stroke(road, kit.SOIL, 22)
    x, y = SPOTS["chicks"]
    coop_at(c, x, y + 26, .8)
    x, y = SPOTS["eggs"]
    for dx, dy in ((-30, 10), (32, 14)):
        nest_at(c, x + dx, y + dy + 10, 56)
        c.cut(ellipse(x + dx - 8, y + dy, 8, 10) + ellipse(x + dx + 8, y + dy + 2, 8, 10), kit.CREAM, marks=0, edge=1.1)
    x, y = SPOTS["fruit"]
    tree_at(c, x, y + 34, .62, key="hometree")
    x, y = SPOTS["share"]
    fence_at(c, x - 60, x + 60, y + 26, 36)
    pig_mini(c, x - 24, y + 14)
    pig_mini(c, x + 24, y + 16)
    x, y = SPOTS["garden"]
    veg_rows(c, x, y + 4, 140, "rows1")
    x, y = SPOTS["market"]
    truck_at(c, x, y + 34, .38, key="hometruck")
    for i, (mx, my) in enumerate([(-38, 6), (-22, 4), (-6, 6)]):
        c.cut(ellipse(x + mx, y + my, 9, 8), "#5E9A4E", marks=0, edge=1)
    return c.svg()


def sky():
    c = kit.Ctx(390, 260)
    sky_band(c, 0, 0, 390, 260, 11, "sky")
    cloud(c, 80, 70, 70)
    cloud(c, 300, 130, 56)
    return c.svg()


def hills():
    c = kit.Ctx(390, 140)
    hill(c, [(-40, 60), (90, 10), (220, 40), (330, 6), (440, 40), (440, 180), (-40, 180)], kit.OLIVE, "hillsA", 3)
    hill(c, [(-40, 110), (140, 66), (300, 96), (440, 70), (440, 180), (-40, 180)], kit.GREEN, "hillsB", 4)
    return c.svg()


def coop():
    c = kit.Ctx(160, 140)
    coop_at(c, 80, 136, 1.1)
    return c.svg()


def bucket():
    c = kit.Ctx(100, 100)
    c.cut(Shape([("M", 14, 30), ("L", 86, 30), ("L", 76, 94), ("L", 24, 94), ("Z",)]), kit.WOOD, key="bucket", marks=2, core=0)
    for y in (46, 62, 78):
        c.stroke(Shape([("M", 16, y), ("L", 84, y)]), kit.dk(kit.WOOD, .35), 1.2, op=.6)
    c.cut(ellipse(50, 30, 36, 8), kit.YELLOW, marks=0, edge=1.2)
    c.dots([(36, 28), (46, 31), (58, 28), (66, 31), (52, 26)], 3, kit.GOLD)
    c.stroke(kit.arc(50, 30, 34, 190, 350), kit.DARKWOOD, 2.4)
    return c.svg()


def haystack():
    c = kit.Ctx(220, 110)
    c.cut(Shape([("M", 6, 106), ("C", 10, 40, 60, 14, 110, 14), ("C", 160, 14, 210, 40, 214, 106), ("Z",)]), "#DDB75E", key="hay", marks=6, core=0)
    for i in range(9):
        x = 20 + i * 22
        c.stroke(Shape([("M", x, 100), ("C", x + 4, 80, x - 2, 60, x + 6, 44)]), kit.dk("#DDB75E", .3), 1.2, op=.6)
    return c.svg()


def nest():
    c = kit.Ctx(140, 60)
    nest_at(c, 70, 34, 128)
    return c.svg()


def tree():
    c = kit.Ctx(240, 250)
    tree_at(c, 120, 246, 1.4, key="tree")
    return c.svg()


def basket():
    c = kit.Ctx(160, 90)
    c.cut(Shape([("M", 8, 20), ("L", 152, 20), ("L", 136, 86), ("L", 24, 86), ("Z",)]), "#C79A5A", key="basket", marks=2, core=0)
    for y in (36, 52, 68):
        c.stroke(Shape([("M", 12, y), ("L", 148, y)]), kit.dk("#C79A5A", .4), 1.4, op=.7)
    for x in range(26, 140, 18):
        c.stroke(Shape([("M", x, 22), ("L", x + 2, 84)]), kit.dk("#C79A5A", .3), 1, op=.5)
    c.cut(rrect(4, 14, 152, 10, 5), kit.dk("#C79A5A", .15), marks=0, edge=1.2)
    return c.svg()


def plate():
    c = kit.Ctx(120, 44)
    c.cut(ellipse(60, 22, 56, 18), kit.CREAM, key="plate", marks=0)
    c.stroke(ellipse(60, 21, 40, 11), kit.BLUE, 1.6, op=.7)
    return c.svg()


def fence():
    c = kit.Ctx(390, 90)
    fence_at(c, 10, 380, 86, 70)
    return c.svg()


def bed():
    c = kit.Ctx(380, 70)
    c.cut(rrect(4, 10, 372, 56, 24), kit.SOIL, key="bed", marks=5, core=0)
    for x in range(30, 360, 60):
        c.stroke(Shape([("M", x, 30), ("C", x + 10, 26, x + 20, 34, x + 30, 30)]), kit.dk(kit.SOIL, .3), 1.4, op=.6)
    return c.svg()


def crate():
    c = kit.Ctx(100, 80)
    c.cut(rrect(6, 20, 88, 56, 6), kit.WOOD, key="crate", marks=2, core=0)
    for y in (38, 56):
        c.stroke(Shape([("M", 8, y), ("L", 92, y)]), kit.dk(kit.WOOD, .35), 1.4, op=.7)
    c.cut(rrect(2, 14, 96, 10, 3), kit.dk(kit.WOOD, .1), marks=0, edge=1.2)
    return c.svg()


def river():
    c = kit.Ctx(390, 120)
    c.cut(rect(-4, 30, 398, 70), "#7FB3C8", key="river", marks=6, core=0)
    c.carve_lines(0, 40, 390, 92, 4, key="water", op=.6)
    planks = Shape()
    for i in range(12):
        planks = planks + rrect(70 + i * 21, 26, 18, 78, 3)
    c.cut(planks, kit.WOOD, marks=0, edge=1.2)
    c.cut(rect(66, 22, 256, 7) + rect(66, 101, 256, 7), kit.BROWN, marks=0, edge=1.2)
    return c.svg()


def shelf():
    c = kit.Ctx(300, 40)
    c.cut(rrect(4, 6, 292, 18, 4), kit.WOOD, key="shelf", marks=2, core=0)
    c.cut(rect(24, 22, 10, 16) + rect(266, 22, 10, 16), kit.BROWN, marks=0, edge=1.2)
    return c.svg()


def truck():
    c = kit.Ctx(360, 172)
    truck_at(c, 180, 170, 1.0)
    return c.svg()


def field():
    c = kit.Ctx(300, 70)
    c.cut(rrect(4, 14, 292, 52, 22), "#8FB565", key="field", marks=4, core=0)
    for x in range(24, 290, 40):
        c.stroke(Shape([("M", x, 40), ("C", x + 8, 30, x + 16, 46, x + 26, 36)]), kit.LEAF, 2, op=.8)
    return c.svg()


def stall():
    c = kit.Ctx(200, 150)
    c.cut(rect(20, 60, 160, 86), kit.WOOD, key="stall", marks=3, core=0)
    c.cut(rect(14, 96, 172, 14), kit.BROWN, marks=0, edge=1.2)
    stripes = Shape()
    for i in range(6):
        stripes = stripes + poly([(6 + i * 32, 20), (38 + i * 32, 20), (38 + i * 32, 56), (6 + i * 32, 56)])
    c.cut(rect(6, 20, 188, 36), kit.PAPER, marks=0, edge=1.2)
    red = Shape()
    for i in range(0, 6, 2):
        red = red + rect(6 + i * 31.3, 20, 31.3, 36)
    c.cut(red, kit.RED, marks=0, edge=0)
    c.stroke(rect(6, 20, 188, 36), kit.edge_of(kit.RED), 1.6)
    for i in range(6):
        c.cut(kit.arc(22 + i * 31.3, 56, 15.6, 0, 180) + Shape([("Z",)]), kit.RED if i % 2 == 0 else kit.PAPER, marks=0, edge=1)
    return c.svg()


def sunpic():
    c = kit.Ctx(100, 100)
    sun(c, 50, 50, 30)
    return c.svg()


def cloudpic():
    c = kit.Ctx(120, 70)
    cloud(c, 60, 40, 100)
    return c.svg()


def moon():
    c = kit.Ctx(100, 100)
    c.cut(Shape([("M", 60, 10), ("C", 30, 14, 14, 40, 18, 64), ("C", 24, 88, 58, 96, 82, 80), ("C", 56, 82, 38, 64, 40, 44),
                 ("C", 42, 28, 50, 16, 60, 10), ("Z",)]), "#F2D27A", key="moon", marks=1)
    return c.svg()


def star():
    c = kit.Ctx(40, 40)
    c.cut(kit.star(20, 20, 16, 7), "#F2D27A", marks=0, edge=1.2)
    return c.svg()


def write_layout():
    def pts(name, ps):
        return f"const {name} = [{', '.join(f'({x / HW:.3f}, {y / HH:.3f})' for x, y in ps)}];"

    spots = ", ".join(f"'{k}': ({x / HW:.3f}, {y / HH:.3f})" for k, (x, y) in SPOTS.items())
    LAYOUT.write_text(f"""// Written by design/art/farm.py (do not edit by hand): where things are on the
// home page's farm (assets/art/farm/home.svg), as fractions of its width and
// height ({HW} x {HH}).

/// The aspect of the farm picture.
const farmAspect = {HW / HH:.5f};

/// The middle of each place's picture (by Place.name); its sign goes under it.
const farmSpots = {{{spots}}};

/// Where the hatched chicks wander (the first ten).
{pts('hatchSpots', HATCH)}

/// The fruit that grows on the home tree.
{pts('treeFruitSpots', TREE_FRUIT)}

/// New vegetables in the patch.
{pts('sproutSpots', SPROUTS)}

/// Melons waiting by the truck.
{pts('melonSpots', MELONS)}
""")


def build():
    files = {"home": home(), "sky": sky(), "hills": hills(), "coop": coop(), "bucket": bucket(), "haystack": haystack(), "nest": nest(),
             "tree": tree(), "basket": basket(), "plate": plate(), "fence": fence(), "bed": bed(), "crate": crate(), "river": river(),
             "shelf": shelf(), "truck": truck(), "field": field(), "stall": stall(), "sun": sunpic(), "cloud": cloudpic(), "moon": moon(),
             "star": star()}
    for name, svg in files.items():
        kit.write_svg(OUT / f"{name}.svg", svg)
    write_layout()
    print(f"farm: {len(files)} files and {LAYOUT.relative_to(kit.ROOT)}")


if __name__ == "__main__":
    build()
