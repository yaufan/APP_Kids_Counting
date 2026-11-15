"""Buttons, boxes and the 回真實生活 card pictures (woodcut prints, kit.py), in app/assets/art/ui/.

- tray5 (300 x 76) and tray10 (300 x 136): the wooden egg box / truck bed, a ten-frame. The holes'
  middles are at (30 + 60 i, 38 + 60 r) (docs/art.md); the app puts an egg or a melon in each.
- sign (200 x 70): a wooden sign board, the app writes on it. bell (100 x 100), stamp (100 x 100, the
  red 「好了」 seal; the app writes 好了 on it), lock, check, speaker, home (60 x 60).
- card_<name> (100 x 100): one picture per 回真實生活 card (core/content.dart).
"""
import math
import sys

sys.dont_write_bytecode = True

import kit  # noqa: E402
from kit import Shape, arc, circle, ellipse, poly, rect, rrect, smooth  # noqa: E402

OUT = kit.ART / "ui"


def tray(rows):
    h = 16 + 60 * rows
    c = kit.Ctx(300, h)
    c.cut(rrect(3, 3, 294, h - 6, 16), kit.WOOD, key=f"tray{rows}", marks=3, core=0)
    for r in range(rows):
        for i in range(5):
            c.cut(ellipse(30 + 60 * i, 38 + 60 * r, 22, 20), kit.dk(kit.WOOD, .32), marks=0, edge=1)
    return c.svg()


def sign():
    c = kit.Ctx(200, 70)
    c.cut(rrect(4, 6, 192, 58, 10), kit.WOOD, key="sign", marks=2, core=.5)
    c.dots([(14, 35), (186, 35)], 3, kit.DARKWOOD)
    return c.svg()


def bell():
    c = kit.Ctx(100, 100)
    c.cut(Shape([("M", 20, 76), ("C", 22, 50, 26, 22, 50, 20), ("C", 74, 22, 78, 50, 80, 76), ("Z",)]), kit.GOLD, key="bell", marks=1)
    c.cut(rrect(12, 72, 76, 10, 5), kit.dk(kit.GOLD, .2), marks=0, edge=1.2)
    c.cut(circle(50, 88, 7), kit.dk(kit.GOLD, .3), marks=0, edge=1)
    c.cut(circle(50, 16, 6), kit.dk(kit.GOLD, .25), marks=0, edge=1)
    return c.svg()


def stamp():
    c = kit.Ctx(100, 100)
    c.stroke(circle(50, 50, 42), "#C23B32", 5)
    c.stroke(circle(50, 50, 34), "#C23B32", 2)
    return c.svg()


def lock():
    c = kit.Ctx(60, 60)
    c.stroke(Shape([("M", 20, 28), ("L", 20, 20), ("C", 20, 8, 40, 8, 40, 20), ("L", 40, 28)]), kit.DARKWOOD, 5)
    c.cut(rrect(12, 26, 36, 28, 6), kit.GOLD, marks=0, edge=1.4)
    c.cut(circle(30, 38, 4), kit.DARKWOOD, marks=0, edge=0)
    return c.svg()


def check():
    c = kit.Ctx(60, 60)
    c.cut(circle(30, 30, 26), kit.LEAF, marks=0, edge=1.4)
    c.stroke(Shape([("M", 18, 31), ("L", 27, 40), ("L", 43, 21)]), kit.PAPER, 6)
    return c.svg()


# ---------------------------------------------------------------- the 回真實生活 pictures
def card(draw):
    c = kit.Ctx(100, 100)
    draw(c)
    return c.svg()


def chopsticks(c):
    c.cut(ellipse(50, 70, 36, 14), kit.CREAM, marks=0)
    c.cut(poly([(24, 20), (28, 18), (70, 78), (66, 80)]) + poly([(36, 16), (40, 15), (78, 74), (74, 76)]), kit.BROWN, marks=0, edge=1.2)


def slippers(c):
    for x, col in ((34, kit.BLUE), (66, kit.RED)):
        c.cut(rrect(x - 13, 20, 26, 66, 13), col, marks=0, edge=1.4)
        c.cut(rrect(x - 15, 30, 30, 16, 8), kit.dk(col, .25), marks=0, edge=1.2)


def spoons(c):
    for i, x in enumerate((26, 44, 62, 80)):
        c.cut(ellipse(x, 28, 7, 10), "#B8B6B0", marks=0, edge=1.2)
        c.cut(rrect(x - 2, 36, 4, 50, 2), "#B8B6B0", marks=0, edge=1.2)


def cups(c):
    for x in (30, 70):
        c.cut(Shape([("M", x - 16, 34), ("L", x + 16, 34), ("L", x + 12, 82), ("L", x - 12, 82), ("Z",)]), kit.SKY, marks=0, edge=1.4)
        c.flat(rect(x - 13, 50, 26, 6), kit.BLUE, .6)


def birds(c):
    for x, y in ((30, 40), (60, 30), (74, 62)):
        c.cut(ellipse(x, y, 13, 10), kit.BLUE, marks=0, edge=1.2)
        c.cut(poly([(x + 12, y - 2), (x + 19, y), (x + 12, y + 2)]), kit.ORANGE, marks=0, edge=.8)
        c.flat(circle(x + 5, y - 3, 1.8), kit.INK)


def eggrack(c):
    c.cut(rrect(10, 40, 80, 40, 8), kit.SKY, marks=0)
    for i, x in enumerate((24, 42, 60, 78)):
        c.cut(ellipse(x, 44, 8, 11), kit.CREAM, marks=0, edge=1.2)


def buttons(c):
    c.cut(Shape([("M", 20, 20), ("L", 80, 20), ("L", 84, 92), ("L", 16, 92), ("Z",)]), kit.PINK, marks=0)
    for y in (36, 56, 76):
        c.cut(circle(50, y, 6), kit.CREAM, marks=0, edge=1.2)
        c.dots([(48, y - 1.5), (52, y + 1.5)], 1, kit.INK)


def hand(c):
    palm = rrect(28, 46, 44, 44, 16)
    fingers = Shape()
    for x, h, rot in ((30, 30, -18), (40, 38, -6), (52, 40, 0), (64, 36, 6)):
        fingers = fingers + rrect(x - 5, 46 - h, 10, h + 8, 5).rotate(rot, x, 50)
    thumb = rrect(70, 56, 10, 26, 5).rotate(35, 74, 70)
    c.cut(palm + fingers + thumb, kit.SKIN, marks=0)


def stairs(c):
    c.cut(poly([(10, 90), (10, 72), (30, 72), (30, 54), (50, 54), (50, 36), (70, 36), (70, 18), (90, 18), (90, 90)]), kit.WOOD, key="stairs", marks=1)


def bowl(c):
    c.dots([(38, 44), (48, 40), (58, 44), (44, 50), (54, 50), (62, 38)], 7, kit.PURPLE)
    c.cut(Shape([("M", 12, 50), ("L", 88, 50), ("C", 86, 78, 70, 88, 50, 88), ("C", 30, 88, 14, 78, 12, 50), ("Z",)]), kit.CREAM, marks=0)
    c.stroke(Shape([("M", 20, 62), ("L", 80, 62)]), kit.BLUE, 2, op=.7)


def bus(c):
    c.cut(rrect(8, 26, 84, 50, 10), kit.GOLD, marks=0)
    for x in (18, 38, 58):
        c.cut(rrect(x, 34, 16, 16, 3), kit.SKY, marks=0, edge=1)
    c.cut(rrect(76, 34, 12, 30, 3), kit.SKY, marks=0, edge=1)
    for x in (26, 72):
        c.cut(circle(x, 78, 9), kit.INK, marks=0, edge=1)


def books(c):
    for i, (col, y) in enumerate(((kit.RED, 70), (kit.BLUE, 52), (kit.GREEN, 34))):
        c.cut(rrect(18 + i * 4, y, 64 - i * 6, 16, 3), col, marks=0, edge=1.3)
        c.flat(rect(24 + i * 4, y + 4, 50 - i * 6, 3), kit.PAPER, .8)


def cookie(c):
    c.cut(circle(50, 50, 34), "#D9A35E", key="cookie", marks=0)
    c.dots([(38, 40), (60, 36), (50, 56), (66, 60), (36, 62)], 3.4, kit.DARKWOOD)


def blocks(c):
    c.cut(rrect(14, 58, 30, 30, 4), kit.RED, marks=0, edge=1.3)
    c.cut(rrect(48, 58, 30, 30, 4), kit.BLUE, marks=0, edge=1.3)
    c.cut(rrect(30, 24, 30, 30, 4), kit.GOLD, marks=0, edge=1.3)


def starpic(c):
    c.cut(kit.star(50, 52, 38, 17), kit.GOLD, marks=0)


def family(c):
    for x, h, col in ((22, 40, kit.RED), (44, 56, kit.BLUE), (66, 64, kit.GREEN), (86, 30, kit.ORANGE)):
        c.cut(rrect(x - 8, 92 - h, 16, h, 6), col, marks=0, edge=1.2)
        c.cut(circle(x, 92 - h - 8, 8), kit.SKIN, marks=0, edge=1.2)


def socks(c):
    for x, col in ((32, kit.RED), (66, kit.BLUE)):
        c.cut(Shape([("M", x - 10, 14), ("L", x + 10, 14), ("L", x + 10, 62), ("C", x + 10, 70, x + 22, 72, x + 22, 82), ("C", x + 22, 90, x + 10, 92, x, 88),
                     ("C", x - 12, 82, x - 10, 70, x - 10, 62), ("Z",)]), col, marks=0, edge=1.3)
        c.flat(rect(x - 10, 22, 20, 5), kit.PAPER, .8)


def basketpic(c):
    c.cut(circle(36, 40, 11) + circle(54, 36, 11) + circle(66, 44, 11), kit.RED, marks=0, edge=1.2)
    c.cut(Shape([("M", 12, 44), ("L", 88, 44), ("L", 78, 88), ("L", 22, 88), ("Z",)]), "#C79A5A", marks=0)
    c.stroke(Shape([("M", 18, 60), ("L", 82, 60), ("M", 20, 74), ("L", 80, 74)]), kit.dk("#C79A5A", .4), 1.4)


CARDS = {"chopsticks": chopsticks, "slippers": slippers, "spoons": spoons, "cups": cups, "birds": birds, "eggrack": eggrack,
         "buttons": buttons, "hand": hand, "stairs": stairs, "bowl": bowl, "bus": bus, "books": books, "cookie": cookie, "blocks": blocks,
         "star": starpic, "family": family, "socks": socks, "basket": basketpic}


def build():
    files = {"tray5": tray(1), "tray10": tray(2), "sign": sign(), "bell": bell(), "stamp": stamp(), "lock": lock(), "check": check()}
    for name, draw in CARDS.items():
        files[f"card_{name}"] = card(draw)
    for name, svg in files.items():
        kit.write_svg(OUT / f"{name}.svg", svg)
    print(f"ui: {len(files)} files")


if __name__ == "__main__":
    build()
