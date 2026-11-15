"""The farm's people and animals (woodcut prints, kit.py), in app/assets/art/animals/.

- grandma, grandma_happy: 農場阿嬤, the guide (bamboo hat, flowered scarf), 120 x 140.
- buffalo, buffalo_sleep: 牛牛 the water buffalo in a bamboo hat, 140 x 120.
- chick, chick_happy (fed): 100 x 100; the counted chick: one clear yellow blob, marks only at the rim.
- hen 120 x 110, pig 100 x 100, sheep 100 x 100, rabbit 100 x 110.
- duck 100 x 110: 鴨子過橋; its vest is left plain cream for the app's number (docs/art.md: the
  number's middle is at (50, 74), about 22 units high).
- uncle: 阿伯 who buys a melon at the market, 110 x 140.
Feet stand on the bottom edge, in the middle.
"""
import sys

sys.dont_write_bytecode = True

import kit  # noqa: E402
from kit import Shape, arc, circle, ellipse, poly, rrect, smooth  # noqa: E402

OUT = kit.ART / "animals"


def feet(c, xs, y, col=kit.ORANGE, w=2.2):
    for x in xs:
        c.stroke(Shape([("M", x, y - 8), ("L", x, y - 2), ("M", x, y - 2), ("L", x - 4, y), ("M", x, y - 2), ("L", x + 4, y)]), col, w)


def chick(happy=False):
    c = kit.Ctx(100, 100)
    draw_chick(c, happy)
    return c.svg()


def draw_chick(c, happy=False):
    """The chick in 100 x 100 units (also the app icon's)."""
    feet(c, (40, 60), 97)
    body = ellipse(50, 58, 33, 31)
    c.cut(body, kit.YELLOW, key="chick-body", marks=2)
    c.cut(ellipse(30, 64, 11, 8).rotate(-20, 30, 64), kit.GOLD, marks=0, edge=1.2)          # wing
    c.stroke(Shape([("M", 48, 28), ("C", 44, 18, 52, 16, 52, 24)]), kit.dk(kit.GOLD, .3), 2.4)   # tuft
    c.stroke(Shape([("M", 52, 28), ("C", 56, 18, 64, 22, 58, 28)]), kit.dk(kit.GOLD, .3), 2.4)
    c.face(56, 50, 16, blush=True, happy=happy)
    if happy:
        c.cut(poly([(52, 58), (64, 58), (58, 66)]), kit.ORANGE, edge=1, marks=0)
        c.cut(poly([(53, 57), (63, 57), (58, 52)]), kit.ORANGE, edge=1, marks=0)
    else:
        c.cut(poly([(51, 57), (65, 57), (58, 65)]), kit.ORANGE, edge=1, marks=0)


def hen():
    c = kit.Ctx(120, 110)
    feet(c, (50, 70), 107, w=2.6)
    c.cut(poly([(26, 52), (8, 22), (20, 30), (14, 12), (34, 40)]), kit.CREAM, marks=0)        # tail
    c.cut(ellipse(58, 66, 36, 30), kit.CREAM, key="hen-body", marks=2)
    c.cut(ellipse(52, 70, 18, 11).rotate(-12, 52, 70), kit.mix(kit.CREAM, kit.WOOD, .35), marks=0, edge=1.2)
    c.cut(circle(86, 38, 16), kit.CREAM, marks=0)
    c.cut(circle(80, 22, 5) + circle(87, 19, 6) + circle(94, 23, 5), kit.RED, marks=0, edge=1.2)
    c.cut(poly([(100, 38), (112, 42), (100, 46)]), kit.ORANGE, marks=0, edge=1)
    c.cut(ellipse(98, 52, 4, 6), kit.RED, marks=0, edge=1)
    c.eyes(90, 35, 8, r=2.4)
    c.flat(circle(94, 42, 2.6), kit.CHEEK, .7)
    return c.svg()


def pig(happy=False):
    c = kit.Ctx(100, 100)
    pk = "#E9A5A0"
    c.cut(rrect(28, 80, 14, 17, 6) + rrect(58, 80, 14, 17, 6), kit.dk(pk, .12), marks=0)
    c.cut(poly([(22, 34), (24, 10), (42, 26)]) + poly([(78, 34), (76, 10), (58, 26)]), pk, marks=0)
    c.cut(ellipse(50, 56, 38, 34), pk, key="pig", marks=2)
    c.face(50, 46, 20, happy=happy)
    c.cut(ellipse(50, 66, 12, 8.5), kit.lt(pk, .35), marks=0, edge=1.2)
    c.flat(ellipse(46, 66, 2, 3) + ellipse(54, 66, 2, 3), kit.dk(pk, .55))
    return c.svg()


def sheep(happy=False):
    c = kit.Ctx(100, 100)
    c.cut(rrect(32, 78, 10, 20, 4) + rrect(58, 78, 10, 20, 4), "#5E5450", marks=0)
    wool = kit.puffs(50, 52, 78, 50, n=5, key="sheep") + kit.circle(50, 62, 30)
    c.cut(wool, kit.CREAM, key="sheep", marks=2)
    c.cut(ellipse(22, 40, 9, 5).rotate(20, 22, 40) + ellipse(78, 40, 9, 5).rotate(-20, 78, 40), "#D8C4AE", marks=0)
    c.cut(ellipse(50, 50, 18, 21), "#E8D6C2", marks=0)
    c.cut(kit.blob(50, 30, 16, 8, lumps=6, wobble=.15, key="tuft"), kit.CREAM, marks=0, edge=1.2)
    c.face(50, 48, 15, happy=happy)
    return c.svg()


def rabbit(happy=False):
    c = kit.Ctx(100, 110)
    wh = "#EFE3D3"
    c.cut(ellipse(36, 22, 8, 22).rotate(-10, 36, 22) + ellipse(64, 22, 8, 22).rotate(10, 64, 22), wh, marks=0)
    c.flat(ellipse(36, 24, 3.5, 15).rotate(-10, 36, 24) + ellipse(64, 24, 3.5, 15).rotate(10, 64, 24), kit.PINK)
    c.cut(ellipse(50, 84, 30, 24), wh, key="rabbit-body", marks=1)
    c.cut(ellipse(50, 56, 25, 22), wh, marks=1, key="rabbit-head")
    c.face(50, 54, 16, happy=happy)
    c.flat(ellipse(50, 61, 3, 2), kit.CHEEK)
    return c.svg()


def duck():
    c = kit.Ctx(100, 110)
    feet(c, (40, 60), 107, w=3)
    c.cut(poly([(14, 70), (4, 56), (22, 60)]), kit.CREAM, marks=0)
    c.cut(ellipse(50, 76, 34, 26), kit.CREAM, key="duck-body", marks=1)
    c.cut(circle(56, 34, 20), kit.CREAM, marks=0)
    c.cut(Shape([("M", 70, 34), ("C", 84, 30, 92, 36, 86, 42), ("C", 80, 46, 72, 44, 70, 40), ("Z",)]), kit.ORANGE, marks=0, edge=1.2)
    c.eyes(60, 30, 12, r=2.4)
    c.flat(circle(66, 38, 2.6), kit.CHEEK, .7)
    # The vest: plain, for the app's number.
    c.cut(rrect(34, 60, 32, 30, 10), kit.BLUE, marks=0, edge=1.4)
    c.flat(rrect(38, 63, 24, 24, 8), kit.PAPER)
    return c.svg()


def buffalo(sleep=False):
    c = kit.Ctx(140, 120)
    g = kit.BUFFALO
    c.cut(rrect(44, 92, 16, 26, 6) + rrect(82, 92, 16, 26, 6), kit.dk(g, .2), marks=0)
    c.cut(ellipse(72, 82, 46, 28), g, key="buffalo-body", marks=2)
    for s in (-1, 1):
        x = 70 + s * 22
        horn = smooth([(x, 46), (x + s * 20, 40), (x + s * 30, 26), (x + s * 26, 38), (x + s * 14, 50)])
        c.cut(horn, "#EFE2C4", marks=0, edge=1.3)
        c.cut(ellipse(70 + s * 30, 54, 9, 5).rotate(s * 20, 70 + s * 30, 54), kit.dk(g, .08), marks=0)
    c.cut(circle(70, 58, 24), g, marks=1, key="buffalo-head")
    c.cut(ellipse(70, 70, 16, 10), "#C9C0CA", marks=0, edge=1.2)
    c.flat(ellipse(64, 70, 2.2, 3) + ellipse(76, 70, 2.2, 3), kit.dk(g, .6))
    c.eyes(70, 54, 18, closed=sleep, r=2.6)
    c.cheeks(70, 61, 28, 3.6)
    hat = Shape([("M", 36, 40), ("C", 52, 34, 62, 20, 70, 14), ("C", 78, 20, 88, 34, 104, 40), ("C", 82, 46, 58, 46, 36, 40), ("Z",)])
    c.cut(hat, "#D9B76E", marks=1, key="hat", core=0)
    c.stroke(Shape([("M", 50, 38), ("C", 62, 41, 78, 41, 90, 38)]), kit.dk("#D9B76E", .45), 1.4)
    return c.svg()


def grandma(happy=False):
    c = kit.Ctx(120, 140)
    top = "#5B7FA6"
    c.cut(rrect(24, 88, 72, 50, 22), top, key="grandma-top", marks=2)                       # body
    c.cut(rrect(36, 108, 48, 30, 8), "#A9C2D6", marks=0, edge=1.2)                         # apron
    c.cut(ellipse(22, 104, 9, 14).rotate(20, 22, 104) + ellipse(98, 104, 9, 14).rotate(-20, 98, 104), top, marks=0)
    c.cut(circle(22, 116, 7) + circle(98, 116, 7), kit.SKIN, marks=0, edge=1.2)
    c.cut(ellipse(34, 62, 8, 14) + ellipse(86, 62, 8, 14), "#BDB6AE", marks=0, edge=1.2)        # grey hair
    c.cut(ellipse(60, 66, 26, 25), kit.SKIN, marks=0)                                       # face
    c.cut(ellipse(60, 46, 26, 9), "#BDB6AE", marks=0, edge=1.2)
    c.cut(poly([(30, 86), (60, 94), (90, 86), (60, 110)]), kit.RED, marks=0, edge=1.2)       # flowered scarf
    c.dots([(46, 92), (60, 99), (74, 92), (60, 90)], 1.8, kit.PAPER)
    hat = Shape([("M", 10, 44), ("C", 32, 36, 48, 18, 60, 8), ("C", 72, 18, 88, 36, 110, 44), ("C", 80, 52, 40, 52, 10, 44), ("Z",)])
    c.cut(hat, "#D9B76E", marks=1, key="grandma-hat", core=0)
    c.stroke(Shape([("M", 26, 43), ("C", 46, 47, 74, 47, 94, 43)]), kit.dk("#D9B76E", .45), 1.4)
    c.eyes(60, 64, 18, happy=happy, r=2.6)
    c.stroke(circle(51, 64, 7) + circle(69, 64, 7), kit.dk(kit.BROWN, .3), 1.4)           # round glasses
    c.stroke(Shape([("M", 58, 63), ("L", 62, 63)]), kit.dk(kit.BROWN, .3), 1.4)
    c.cheeks(60, 73, 30, 4.2)
    c.smile(60, 76, 12, open_=happy)
    return c.svg()


def uncle():
    c = kit.Ctx(110, 140)
    shirt = "#C4A04A"
    c.cut(rrect(22, 86, 66, 52, 20), shirt, key="uncle", marks=2)
    c.cut(rrect(34, 120, 42, 18, 4), "#5C5A66", marks=0, edge=1.2)
    c.cut(ellipse(55, 64, 24, 24), kit.SKIN, marks=0)
    c.cut(Shape([("M", 30, 54), ("C", 30, 32, 80, 32, 80, 54), ("L", 92, 56), ("C", 80, 50, 40, 48, 30, 54), ("Z",)]), kit.LEAF, marks=0)
    c.face(55, 64, 16)
    c.stroke(Shape([("M", 46, 76), ("C", 50, 79, 60, 79, 64, 76)]), kit.INK, 1.6)
    c.cut(circle(20, 112, 7) + circle(90, 112, 7), kit.SKIN, marks=0, edge=1.2)
    return c.svg()


def build():
    files = {
        "chick": chick(), "chick_happy": chick(True), "hen": hen(), "pig": pig(), "sheep": sheep(), "rabbit": rabbit(),
        "duck": duck(), "buffalo": buffalo(), "buffalo_sleep": buffalo(True), "grandma": grandma(),
        "grandma_happy": grandma(True), "uncle": uncle(),
    }
    for name, svg in files.items():
        kit.write_svg(OUT / f"{name}.svg", svg)
    print(f"animals: {len(files)} files")


if __name__ == "__main__":
    build()
