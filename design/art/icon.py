"""數數小農場's app icon, in the woodcut-print look of the rest of the art (kit.py): a yellow chick on
the hill beside a wooden number block 3 and three eggs in the egg box, under a carved sky. The 3 is
written with the app's font (jf open 粉圓) after Chromium draws the rest.

    python3 icon.py preview OUT.png      # the icon big (512), as a phone cuts it (round, rounded square)
                                         # at 96 and 48 px, and at 48 px on a light and a dark home screen
                                         # next to the sibling apps' icons
    python3 icon.py export               # writes the Android and iOS icons into app/

export writes (the same files as the sibling apps' icon.py)
- Android, full square art: app/android/app/src/main/res/mipmap-{mdpi..xxxhdpi}/ic_launcher.png
  (48..192 px, opaque).
- Android adaptive icon (API 26+): mipmap-anydpi-v26/ic_launcher.xml, with
  drawable-{mdpi..xxxhdpi}/ic_launcher_foreground.png and ic_launcher_background.png (108 dp canvas;
  the whole subject stays inside the central 66 dp circle, the part every launcher mask shows).
- iOS: every PNG listed in app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json, at its
  size, opaque (no alpha).

Everything is drawn in 200 x 200 units with kit.Ctx, rendered at 1024 px by Chromium (Node.js with
Playwright) and scaled down with Pillow. Deterministic. Scratch files go to /dev/shm and are deleted.
"""
import sys

sys.dont_write_bytecode = True      # no __pycache__ in design/art

import json  # noqa: E402
import math  # noqa: E402
import pathlib  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import animals  # noqa: E402
import kit  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
APP = ROOT / "app"
RES = APP / "android" / "app" / "src" / "main" / "res"
IOS = APP / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
FONT = APP / "assets" / "fonts" / "jf-openhuninn-2.1.ttf"

U = 200                              # drawing units across the icon
C = 1024                             # rendered size, scaled down from here
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
VIEW = 72 / 108                      # how much of the adaptive canvas a launcher shows
SAFE_R = .44 * U                     # the subject stays within this radius of the middle

CHICK = (24, 34, 1.08)               # the chick's top left and scale (animals.draw_chick is 100 x 100)
TILE = (120, 40, 46)                 # the number block: top left and side
GLYPH_AT = (TILE[0] + TILE[2] / 2, TILE[1] + TILE[2] / 2)
TRAY = (50, 140, 100, 30)            # the egg box: left, top, width, height


# ================================================================ the picture
def background(c, view):
    """Cream paper with a carved sky and a green hill, filling the square."""
    c.flat(kit.rect(0, 0, U, U), kit.SKY)
    c.carve_lines(0, 8, U, U * .62, 7, key="iconsky", op=.8)
    c.begin(f"translate(100 100) scale({view:.4f}) translate(-100 -100)")
    c.cut(kit.puffs(40, 40, 50, 22, n=3, key="iconcloud"), kit.PAPER, marks=0, edge=1.2)
    c.end()
    c.cut(kit.smooth([(-30, 150), (60, 118), (140, 130), (230, 112), (230, 230), (-30, 230)], .7), kit.GREEN, key="iconhill", marks=3, core=0, edge=1.6)


def subject(c, view):
    """The chick, the number block and three eggs in the box."""
    c.begin(f"translate(100 100) scale({view:.4f}) translate(-100 -100)")
    x, y, s = TILE
    c.cut(kit.rrect(x, y, s, s, 9), kit.ORANGE, marks=0, edge=2)
    c.begin(f"translate({CHICK[0]} {CHICK[1]}) scale({CHICK[2]})")
    animals.draw_chick(c)
    c.end()
    tx, ty, tw, th = TRAY
    c.cut(kit.rrect(tx, ty, tw, th, 8), kit.WOOD, marks=1, core=0, key="icontray", edge=1.8)
    for i in range(3):
        cx = tx + tw * (i + .5) / 3
        c.cut(kit.ellipse(cx, ty + th * .42, 12, 15), kit.CREAM, marks=0, edge=1.6)
    c.end()


def check_safe():
    """The block, the chick and the egg box stay within SAFE_R of the middle."""
    x, y, s = TILE
    cx, cy, k = CHICK
    tx, ty, tw, th = TRAY
    far = [(x + s, y), (x + s, y + s), (x, y), (cx + 17 * k, cy + 30 * k), (cx + 20 * k, cy + 95 * k), (tx, ty + th), (tx + tw, ty + th)]
    worst = max(math.hypot(px - U / 2, py - U / 2) for px, py in far)
    if worst > SAFE_R * 1.02:
        sys.exit(f"icon: the subject reaches {worst:.1f} units from the middle (keep within {SAFE_R:.1f})")


def write_glyph(img, view):
    """3 on the number block, with the app's font: cream with a dark ink edge."""
    px = img.size[0] / U
    gx, gy = GLYPH_AT
    gx, gy = 100 + (gx - 100) * view, 100 + (gy - 100) * view
    f = font(round(38 * view * px))
    d = ImageDraw.Draw(img)
    d.text((gx * px, gy * px), "3", font=f, fill=kit.PAPER, anchor="mm", stroke_width=round(2.2 * view * px), stroke_fill=kit.edge_of(kit.ORANGE))


def doc(c, px):
    text = c.svg()
    return text.replace("<svg ", f'<svg width="{px}" height="{px}" ', 1)


def subject_svg(adaptive):
    c = kit.Ctx(U, U)
    subject(c, VIEW if adaptive else 1.0)
    return doc(c, C)


def background_svg(adaptive):
    c = kit.Ctx(U, U)
    background(c, VIEW if adaptive else 1.0)
    return doc(c, C)


# ================================================================ rendering
RENDER_JS = """
const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const jobs = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const browser = await chromium.launch();
  for (const [inp, out, px] of jobs) {
    for (let tries = 1; ; tries++) {          // a screenshot now and then fails while the machine is busy
      const page = await browser.newPage({ viewport: { width: px, height: px }, deviceScaleFactor: 1 });
      try {
        await page.goto('file://' + inp);
        await page.screenshot({ path: out, omitBackground: true });
        break;
      } catch (e) {
        if (tries >= 3) throw e;
      } finally {
        await page.close();
      }
    }
  }
  await browser.close();
})();
"""


def render_all(svgs):
    """{key: svg text} -> {key: RGBA image}, all drawn by one Chromium."""
    shm = "/dev/shm" if pathlib.Path("/dev/shm").is_dir() else None
    with tempfile.TemporaryDirectory(dir=shm, prefix="farm_icon_") as tmp:
        tmp = pathlib.Path(tmp)
        jobs = []
        for i, (key, text) in enumerate(svgs.items()):
            src, out = tmp / f"{i}.svg", tmp / f"{i}.png"
            src.write_text(text)
            jobs.append([str(src), str(out), C])
        (tmp / "jobs.json").write_text(json.dumps(jobs))
        (tmp / "r.js").write_text(RENDER_JS)
        subprocess.run(["node", str(tmp / "r.js"), str(tmp / "jobs.json")], check=True, cwd=HERE)
        return {key: Image.open(tmp / f"{i}.png").convert("RGBA").copy() for i, key in enumerate(svgs)}


def art():
    """(full square art RGB, adaptive background RGB, adaptive foreground RGBA)."""
    check_safe()
    for key, text in (("fg", subject_svg(False)), ("afg", subject_svg(True)), ("bg", background_svg(False)),
                      ("abg", background_svg(True))):
        kit.check_svg(f"icon/{key}", text)
    im = render_all({"bg": background_svg(False), "fg": subject_svg(False),
                     "abg": background_svg(True), "afg": subject_svg(True)})
    write_glyph(im["fg"], 1.0)
    write_glyph(im["afg"], VIEW)
    full = Image.alpha_composite(im["bg"], im["fg"]).convert("RGB")
    return full, im["abg"].convert("RGB"), im["afg"]


def launcher_view(bg, fg):
    """The adaptive icon as a launcher shows it: both layers, the middle 72 dp of 108."""
    whole = Image.alpha_composite(bg.convert("RGBA"), fg).convert("RGB")
    k = C * 18 / 108
    return whole.crop((round(k), round(k), round(C - k), round(C - k)))


def resized(img, px):
    return img.resize((px, px), Image.LANCZOS)


def mask(kind, px):
    s = px * 4
    m = Image.new("L", (s, s), 0)
    dr = ImageDraw.Draw(m)
    if kind == "round":
        dr.ellipse((0, 0, s - 1, s - 1), fill=255)
    elif kind == "squircle":
        pts = []
        for i in range(720):
            t = 2 * math.pi * i / 720
            c, si = math.cos(t), math.sin(t)
            pts.append((s / 2 + s / 2 * math.copysign(abs(c) ** (2 / 5), c), s / 2 + s / 2 * math.copysign(abs(si) ** (2 / 5), si)))
        dr.polygon(pts, fill=255)
    else:                                       # iOS-like rounded square
        dr.rounded_rectangle((0, 0, s - 1, s - 1), radius=s * .225, fill=255)
    return m.resize((px, px), Image.LANCZOS)


# ================================================================ preview
SIBLINGS = (("畫畫小鎮", "APP_Kids_Paint"), ("字母寵物", "app_kids_paint_for_learning_writing"), ("動物小餐廳", "app_kids_cook"),
            ("小卡認天下", "app_kids_card_game"), ("想一想樂園", "app_kids_brainstorming"), ("眼尖尖", "app_kids_falsecharge"),
            ("迷宮小冒險", "app_kids_maze"), ("小小生活家", "app_kids_live_circ"), ("心情小屋", "app_kids_feelings"),
            ("晚安小鎮", "app_kids_goodnight"), ("安全小隊", "app_kids_safety"), ("ㄅㄆㄇ小火車", "app_kids_bopomofo"))


def font(size):
    try:
        return ImageFont.truetype(str(FONT), size)
    except OSError:
        return ImageFont.load_default()


def siblings():
    out = []
    for zh, repo in SIBLINGS:
        for base in (ROOT.parent, ROOT.parent.parent, pathlib.Path("/home/user")):      # the siblings sit next to this repo or one level up
            p = base / repo / "app" / "android" / "app" / "src" / "main" / "res" / "mipmap-xxxhdpi" / "ic_launcher.png"
            if p.is_file():
                out.append((zh, Image.open(p).convert("RGB")))
                break
    return out


def home_screen(icons, dark, W):
    """A strip of a phone's home screen: icons (label, image) at 48 px, round, with their names."""
    H = 104
    top, bottom = ("#3A3550", "#1E1B2B") if dark else ("#F6EFE6", "#E3EEF8")
    strip = Image.new("RGB", (W, H))
    dr = ImageDraw.Draw(strip)
    for y in range(H):
        dr.line([(0, y), (W, y)], fill=kit.mix(top, bottom, y / (H - 1)))
    step = W / len(icons)
    f = font(13)
    for i, (label, im) in enumerate(icons):
        x = round(step * i + step / 2 - 24)
        strip.paste(resized(im, 48), (x, 18), mask("round", 48))
        tw = dr.textlength(label, font=f)
        dr.text((x + 24 - tw / 2, 74), label, font=f, fill="#FFFFFF" if dark else "#3B3550")
    return strip


def preview(out):
    full, abg, afg = art()
    view = launcher_view(abg, afg)
    pad, big = 24, 512
    W = pad * 2 + big + 40 + 420
    H = pad + big + pad + 104 * 2 + pad
    sheet = Image.new("RGB", (W, H), "#FFFFFF")
    dr = ImageDraw.Draw(sheet)
    sheet.paste(resized(full, big), (pad, pad))                                  # the full square art, big
    x, y = pad + big + 40, pad
    f = font(22)
    dr.text((x, y), "adaptive (round, squircle), full art: 96 / 48 px", font=f, fill="#3B2A1E")
    y += 40
    for kind, im, s in (("round", view, 96), ("squircle", view, 96), ("square", full, 96)):
        sheet.paste(resized(im, s), (x, y), mask(kind, s))
        x += s + 24
    x, y = pad + big + 40, pad + 40 + 96 + 24
    for kind, im, s in (("round", view, 48), ("squircle", view, 48), ("square", full, 48), ("round", view, 36)):
        sheet.paste(resized(im, s), (x, y + 48 - s), mask(kind, s))
        x += s + 24
    y = pad + big + pad
    icons = siblings() + [("數數小農場", view)]
    sheet.paste(home_screen(icons, False, W - 2 * pad), (pad, y))
    sheet.paste(home_screen(icons, True, W - 2 * pad), (pad, y + 104))
    sheet.save(out)
    print(out)


# ================================================================ export
ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
"""


def export():
    full, bg, fg = art()
    written = []
    for d, k in DENSITIES.items():
        mip = RES / f"mipmap-{d}"
        mip.mkdir(parents=True, exist_ok=True)
        resized(full, round(48 * k)).save(mip / "ic_launcher.png")
        dr = RES / f"drawable-{d}"
        dr.mkdir(parents=True, exist_ok=True)
        resized(fg, round(108 * k)).save(dr / "ic_launcher_foreground.png")
        resized(bg, round(108 * k)).save(dr / "ic_launcher_background.png")
        written += [mip / "ic_launcher.png", dr / "ic_launcher_foreground.png", dr / "ic_launcher_background.png"]
    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(ADAPTIVE_XML)
    written.append(anydpi / "ic_launcher.xml")
    contents = json.loads((IOS / "Contents.json").read_text())
    sizes = {}
    for image in contents["images"]:
        if image.get("filename"):
            px = round(float(image["size"].split("x")[0]) * float(image["scale"].rstrip("x")))
            if sizes.setdefault(image["filename"], px) != px:
                sys.exit(f"{image['filename']} is listed at two sizes in Contents.json")
    for fname, px in sizes.items():
        resized(full, px).convert("RGB").save(IOS / fname)
        written.append(IOS / fname)
    manifest = (APP / "android" / "app" / "src" / "main" / "AndroidManifest.xml").read_text()
    if 'android:icon="@mipmap/ic_launcher"' not in manifest:
        print("note: AndroidManifest.xml's android:icon is not @mipmap/ic_launcher")
    for p in written:
        print(p.relative_to(ROOT))


if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "export":
        export()
    elif len(sys.argv) >= 3 and sys.argv[1] == "preview":
        preview(sys.argv[2])
    else:
        print(__doc__)
