# 圖和程式的約定（數數小農場）

全部的圖都是 `design/art/` 的 Python 畫的 SVG（木刻版畫風），放在 `app/assets/art/`，App 用 flutter_svg 畫。數字和字都不畫在圖裡，由 App 用字型（jf open 粉圓）寫上去。

## 木刻版畫風怎麼畫（`design/art/kit.py`）
- 每個形狀：一塊平平的「油墨色」，外面一圈深色的邊（邊是畫在色塊**後面**的粗線，所以幾個形狀合在一起時，中間的接縫看不到），再加幾條紙色的刀痕。
- 刀痕是細長的尖片，全部往同一個方向斜（約 −28°）。
- **要數的東西中間不刻**（使用者選了 C，設計擔心刀痕讓小朋友數東西時分心）：`cut()` 預設留一塊「中間」（形狀較短那一邊的 42%）不放刀痕，刀痕只在邊邊。小東西（蛋、小雞、水果、西瓜）最多一兩條，太小的東西一條也沒有。每個要數的東西看起來都是一整塊清楚的形狀。
- 天空、山丘、草地、木箱這些背景才用 `core=0`（刀痕可以在任何地方）和 `carve_lines()`（一條一條長長的刻線）。
- 刀痕**不用 clipPath**：shapely 先把每一條刀痕和形狀（扣掉中間）算好交集，SVG 裡只有一般的路徑。
- 沒有影子、沒有反光、沒有漸層（只有 icon 和背景偶爾用）；顏色帶一點土色，像印在米色紙上。

## 顏色
和 `app/lib/app/theme.dart` 的 `Inks` 一樣：紙 `#F6EDD9`、深色油墨 `#3B2A1E`（眼睛、邊、字，從來不用純黑）、紅 `#C8553D`、橘 `#E08A3A`、小雞黃 `#EDBE3F`、綠 `#86AE5E`、葉綠 `#5E8C4A`、天空 `#BFD9DE`、藍 `#4F7FA8`、木頭 `#D3A46C`。

## flutter_svg 的規則
不用 `filter`、`mask`、`clipPath`、`pattern`、`style`、`text`、`image`、`mix-blend-mode`；每個路徑都要有 fill 或 stroke；每個檔案小於 80 KB；viewBox 從 0 0 開始。`python3 build.py check` 檢查這些，`python3 build.py fluttercheck` 用真的 flutter_svg 和 Chromium 各畫一次比對（75 個檔案都一樣）。

## 檔案和大小
- `animals/`：`grandma`、`grandma_happy`（120 × 140）、`buffalo`、`buffalo_sleep`（140 × 120）、`chick`、`chick_happy`、`pig`、`sheep`（100 × 100）、`hen`（120 × 110）、`rabbit`、`duck`（100 × 110）、`uncle`（110 × 140）。腳站在下面中間。
- `duck` 的背心是空的：App 在背心中間寫號碼（小小農夫畫點點），位置是寬的 0.38～0.62、高的 0.58 起，約 0.24 寬。
- `food/`：每個 100 × 100、置中：`egg`、`corn`（一顆玉米粒，小雞吃的）、`cob`（一根玉米）、`guava`、`banana`、`mango`、`orange`、`waxapple`、`papaya`、`potato`、`bun`、`cabbage`、`carrot`、`eggplant`、`pumpkin`、`melon`。
- `farm/`：`home`（390 × 620，首頁的整個農場）、`sky`（390 × 260）、`hills`（390 × 140）、`coop`、`bucket`、`haystack`、`nest`、`tree`、`basket`、`plate`、`fence`、`bed`、`crate`、`river`（有木橋，橋面在寬的 66～322／390）、`shelf`、`truck`（360 × 172）、`field`、`stall`、`sun`、`cloud`、`moon`、`star`。
- `ui/`：`tray5`（300 × 76）、`tray10`（300 × 136）是蛋盒和車斗的十格框，第 i 個洞的中心在 (30 + 60 × (i % 5), 38 + 60 × (i ÷ 5))；`sign`（200 × 70，木牌，App 寫字）、`bell`、`stamp`（App 寫「好了」）、`lock`、`check`；`card_*`（100 × 100）是回真實生活卡的圖。

## 首頁的位置
`design/art/farm.py` 畫 `farm/home.svg`，同時寫 `app/lib/app/farm_layout.dart`（不要手改）：六個地方的中心（木牌在下面）、孵出來的小雞走來走去的位置（最多 10 隻）、樹上的果子、菜園新長的菜、貨車旁的西瓜。改了位置要重新 `python3 build.py farm`。

## APP 圖示
`design/art/icon.py`：一隻小雞、一塊寫著 3 的木頭數字方塊、蛋盒裡三顆蛋，天空是刻線。`python3 icon.py preview OUT.png` 看（和兄弟 APP 的圖示放在一起），`python3 icon.py export` 寫進 Android 和 iOS。
