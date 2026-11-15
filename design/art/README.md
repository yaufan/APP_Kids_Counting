# design/art：數數小農場的圖（木刻版畫風）

Every picture is a woodcut print on cream paper: flat ink, a dark ink edge, and a few paper-coloured
gouge marks, kept to the rim of anything that is counted (the user chose this style; the design was
worried the marks could distract a child counting). The contract with the app (sizes, where numbers
go, the farm's layout) is `docs/art.md`. Numbers and words are never drawn here.

## Draw
```python
import kit
c = kit.Ctx(100, 100)                                  # viewBox 0 0 100 100
c.cut(kit.circle(50, 55, 34), kit.YELLOW, key="x")     # edge + flat ink + one or two marks at the rim
c.cut(shape, kit.GREEN, marks=0)                       # no marks
c.cut(shape, kit.GREEN, marks=6, core=0)               # a background: marks anywhere
c.carve_lines(0, 0, 390, 200, 9)                       # the carved lines of a sky
c.face(50, 48, 16, happy=True)                         # eyes, cheeks, a smile
kit.write_svg(path, c.svg())                           # checks the rules, then writes
```
Shapes: `rrect rect ellipse circle poly smooth blob puffs star heart path arc`; `+` is a union.
Needs shapely (the marks are intersected with the shape here, no clipPath in the SVG).

## Modules
- `animals.py`: 阿嬤, 牛牛, the chick, hen, pig, sheep, rabbit, duck (a plain vest for the number), 阿伯.
- `food.py`: the egg, corn, the six fruit, the snacks, the vegetables, pumpkin, melon.
- `farm.py`: the home farm and `app/lib/app/farm_layout.dart`, the sky and hills, and every place's things.
- `ui.py`: the ten-frame trays, the sign, bell, stamp, lock, check, the 回真實生活 card pictures.
- `icon.py`: the app icon.

## Commands (run in this folder)
```
python3 build.py all                    # every module, then check
python3 build.py sheet OUT.png [dir]    # a contact sheet (animals / food / farm / ui)
python3 build.py fluttercheck           # real flutter_svg vs Chromium
python3 icon.py preview OUT.png         # the app icon with the sibling apps' icons
python3 icon.py export                  # the Android and iOS icons
```
Look at the sheet after every change. Deterministic: build twice, same bytes. No `__pycache__`
(every script sets `sys.dont_write_bytecode`). Do not run git here.
