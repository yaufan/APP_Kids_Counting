"""The things that are counted (woodcut prints, kit.py), in app/assets/art/food/, each 100 x 100 and
centred: one clear blob of colour each, with at most one or two gouge marks at the rim (docs/art.md).

egg, corn (one big kernel for a chick), cob (an ear of corn), the six fruit of 摘水果 (guava, banana,
mango, orange, waxapple, papaya), the snacks of 分點心 (potato, bun; cob and banana again), the
vegetables of 排排隊 (cabbage, carrot, eggplant; cob again), pumpkin and melon (a watermelon).
"""
import sys

sys.dont_write_bytecode = True

import kit  # noqa: E402
from kit import Shape, circle, ellipse, poly, rrect, smooth  # noqa: E402

OUT = kit.ART / "food"


def leaf(c, x, y, rx, ry, rot, col=kit.LEAF):
    c.cut(ellipse(x, y, rx, ry).rotate(rot, x, y), col, marks=0, edge=1.2)
    c.stroke(Shape([("M", x - rx * .7, y), ("L", x + rx * .7, y)]).rotate(rot, x, y), kit.dk(col, .45), 1)


def stem(c, x, y, h=10):
    c.stroke(Shape([("M", x, y), ("C", x - 1, y - h * .5, x + 2, y - h * .8, x + 3, y - h)]), kit.DARKWOOD, 3.2)


def egg():
    c = kit.Ctx(100, 100)
    c.cut(ellipse(50, 53, 31, 39), kit.CREAM, key="egg", marks=1)
    return c.svg()


def corn():
    """One fat kernel (what a chick eats)."""
    c = kit.Ctx(100, 100)
    c.cut(Shape([("M", 50, 18), ("C", 74, 18, 84, 44, 78, 62), ("C", 72, 80, 60, 86, 50, 86), ("C", 40, 86, 28, 80, 22, 62),
                 ("C", 16, 44, 26, 18, 50, 18), ("Z",)]), kit.YELLOW, key="kernel", marks=1)
    c.flat(ellipse(50, 70, 14, 8), kit.lt(kit.YELLOW, .45), .8)
    return c.svg()


def cob():
    c = kit.Ctx(100, 100)
    body = Shape([("M", 50, 10), ("C", 66, 12, 70, 40, 66, 62), ("C", 62, 80, 56, 88, 50, 88), ("C", 44, 88, 38, 80, 34, 62),
                  ("C", 30, 40, 34, 12, 50, 10), ("Z",)])
    c.cut(body, kit.YELLOW, key="cob", marks=1)
    for y in (26, 40, 54, 68):
        c.stroke(Shape([("M", 38, y), ("C", 44, y + 3, 56, y + 3, 62, y)]), kit.dk(kit.YELLOW, .35), 1.2, op=.7)
    c.cut(Shape([("M", 50, 92), ("C", 30, 80, 22, 56, 28, 40), ("C", 34, 60, 42, 76, 52, 84), ("Z",)]), kit.LEAF, marks=0, edge=1.2)
    c.cut(Shape([("M", 50, 92), ("C", 70, 80, 78, 56, 72, 40), ("C", 66, 60, 58, 76, 48, 84), ("Z",)]), kit.GREEN, marks=0, edge=1.2)
    return c.svg()


def guava():
    c = kit.Ctx(100, 100)
    stem(c, 50, 22)
    c.cut(smooth([(50, 20), (74, 28), (82, 54), (70, 80), (50, 86), (30, 80), (18, 54), (26, 28)]), "#A9C46A", key="guava", marks=1)
    leaf(c, 64, 16, 11, 5, -20)
    return c.svg()


def banana():
    c = kit.Ctx(100, 100)
    body = Shape([("M", 20, 30), ("C", 24, 66, 52, 84, 82, 74), ("C", 88, 72, 88, 66, 82, 66), ("C", 56, 70, 36, 56, 30, 28), ("Z",)])
    c.cut(body, "#EBC94A", key="banana", marks=1)
    c.cut(rrect(16, 20, 10, 12, 3).rotate(-15, 21, 26), kit.DARKWOOD, marks=0, edge=1)
    return c.svg()


def mango():
    c = kit.Ctx(100, 100)
    stem(c, 44, 20)
    c.cut(smooth([(44, 20), (70, 24), (84, 50), (72, 80), (46, 86), (24, 70), (22, 42)]), "#EDA23C", key="mango", marks=1)
    c.flat(ellipse(36, 40, 10, 8), "#D6694A", .55)
    leaf(c, 58, 14, 11, 5, -25)
    return c.svg()


def orange():
    c = kit.Ctx(100, 100)
    c.cut(circle(50, 54, 33), kit.ORANGE, key="orange", marks=1)
    c.dots([(40, 44), (60, 48), (48, 66), (64, 64), (36, 60)], 1.2, kit.dk(kit.ORANGE, .2), .6)
    leaf(c, 60, 20, 11, 5, -20)
    stem(c, 50, 24, 6)
    return c.svg()


def waxapple():
    c = kit.Ctx(100, 100)
    body = Shape([("M", 50, 20), ("C", 64, 20, 70, 32, 74, 48), ("C", 80, 70, 76, 86, 64, 86), ("C", 58, 80, 54, 86, 50, 86),
                  ("C", 46, 86, 42, 80, 36, 86), ("C", 24, 86, 20, 70, 26, 48), ("C", 30, 32, 36, 20, 50, 20), ("Z",)])
    c.cut(body, "#C9454A", key="waxapple", marks=1)
    stem(c, 50, 22, 8)
    return c.svg()


def papaya():
    c = kit.Ctx(100, 100)
    body = smooth([(50, 12), (64, 22), (72, 50), (68, 76), (50, 90), (32, 76), (28, 50), (36, 22)])
    c.cut(body, "#E9A23E", key="papaya", marks=1)
    c.flat(ellipse(44, 34, 6, 10), "#9DB86A", .55)
    return c.svg()


def potato():
    """A roasted sweet potato (烤地瓜)."""
    c = kit.Ctx(100, 100)
    body = smooth([(14, 54), (30, 34), (56, 30), (82, 40), (88, 56), (72, 70), (44, 72), (22, 66)])
    c.cut(body, "#A4515A", key="potato", marks=1)
    c.flat(ellipse(56, 44, 12, 6), "#E7B65A", .9)
    return c.svg()


def bun():
    """A steamed meat bun (肉包)."""
    c = kit.Ctx(100, 100)
    c.cut(Shape([("M", 14, 72), ("C", 14, 40, 34, 24, 50, 24), ("C", 66, 24, 86, 40, 86, 72), ("C", 70, 80, 30, 80, 14, 72), ("Z",)]),
          "#F2E6D0", key="bun", marks=1)
    for a in (-30, -10, 10, 30):
        c.stroke(Shape([("M", 50, 26), ("C", 50 + a * .3, 36, 50 + a * .7, 44, 50 + a, 50)]), kit.dk("#F2E6D0", .35), 1.4)
    return c.svg()


def cabbage():
    c = kit.Ctx(100, 100)
    c.cut(circle(50, 54, 36), "#8DB86A", key="cabbage", marks=1)
    c.cut(ellipse(50, 50, 24, 22), "#B6D48A", marks=0, edge=1.2)
    c.stroke(Shape([("M", 50, 30), ("C", 46, 44, 46, 56, 50, 70)]), kit.dk("#8DB86A", .35), 1.4)
    return c.svg()


def carrot():
    c = kit.Ctx(100, 100)
    for x, rot in ((44, -20), (50, 0), (56, 20)):
        c.cut(ellipse(x, 18, 5, 13).rotate(rot, x, 26), kit.LEAF, marks=0, edge=1.1)
    c.cut(Shape([("M", 32, 30), ("C", 44, 26, 58, 26, 68, 30), ("C", 66, 54, 58, 80, 50, 92), ("C", 42, 80, 34, 54, 32, 30), ("Z",)]),
          kit.ORANGE, key="carrot", marks=1)
    c.stroke(Shape([("M", 40, 46), ("L", 46, 46), ("M", 54, 60), ("L", 60, 60)]), kit.dk(kit.ORANGE, .35), 1.2)
    return c.svg()


def eggplant():
    c = kit.Ctx(100, 100)
    body = Shape([("M", 30, 24), ("C", 42, 20, 52, 30, 58, 44), ("C", 66, 60, 84, 66, 80, 82), ("C", 74, 94, 52, 92, 40, 78),
                  ("C", 28, 64, 22, 40, 30, 24), ("Z",)])
    c.cut(body, kit.PURPLE, key="eggplant", marks=1)
    c.cut(poly([(22, 22), (36, 14), (44, 26), (34, 34)]), kit.LEAF, marks=0, edge=1.1)
    return c.svg()


def pumpkin():
    c = kit.Ctx(100, 100)
    stem(c, 50, 30, 12)
    body = ellipse(32, 60, 20, 26) + ellipse(68, 60, 20, 26) + ellipse(50, 60, 22, 28)
    c.cut(body, "#E39A3B", key="pumpkin", marks=1)
    c.stroke(Shape([("M", 40, 38), ("C", 36, 50, 36, 70, 40, 84), ("M", 60, 38), ("C", 64, 50, 64, 70, 60, 84)]), kit.dk("#E39A3B", .35), 1.4)
    return c.svg()


def melon():
    c = kit.Ctx(100, 100)
    c.cut(ellipse(50, 54, 38, 33), "#5E9A4E", key="melon", marks=1)
    for dx in (-22, -8, 8, 22):
        c.stroke(Shape([("M", 50 + dx * .5, 22), ("C", 50 + dx * 1.2, 40, 50 + dx * 1.2, 68, 50 + dx * .5, 86)]), "#2F5A30", 3.2, op=.85)
    stem(c, 50, 22, 6)
    return c.svg()


def build():
    files = {f.__name__: f() for f in (egg, corn, cob, guava, banana, mango, orange, waxapple, papaya, potato, bun, cabbage, carrot,
                                       eggplant, pumpkin, melon)}
    for name, svg in files.items():
        kit.write_svg(OUT / f"{name}.svg", svg)
    print(f"food: {len(files)} files")


if __name__ == "__main__":
    build()
