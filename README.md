# 數數小農場

給 **3～5 歲**的小朋友，在台灣，國語為主：玩數量。到台灣鄉下的小農場幫農場阿嬤做事，每件工作都是在數數：一個一個點著數、一眼看出有幾個、看數字拿東西、比多比少、平分、排順序、找規律；小農夫再玩「多一個、少一個」（不教正式的加減）。

- 設計：[docs/design.md](docs/design.md)，草圖在 `docs/mockups/`。
- 和「畫畫小鎮」「字母寵物」「動物小餐廳」「小卡認天下」「想一想樂園」「眼尖尖大挑戰」「迷宮小冒險」「小小生活家」「小小音樂家」「心情小屋」「晚安小鎮」「安全小隊」「ㄅㄆㄇ小火車」是兄弟 APP：同一個作者、同一套技術、不同畫風。
- 不連網、不定位、沒有廣告、沒有帳號。

## 下載（Android）
- 最新版：[Releases](https://github.com/yaufan/APP_Kids_Counting/releases/latest)，一般手機下載 `counting-farm-版本-arm64.apk`。
- 用手機掃描 [docs/download-qr.png](docs/download-qr.png)。

## 目前進度
- 0.1.0（測試版）：農場首頁（會變熱鬧、點小雞數數）、六個地方（餵小雞、撿雞蛋、摘水果、分點心、排排隊、去市場）、兩個難度（小小農夫、小農夫）、30 張回真實生活卡和農場日記、休息時間、家長關卡和家長模式（含進度）、音樂和音效、APP 圖示。木刻版畫風。版本紀錄在 [CHANGELOG.md](CHANGELOG.md)。

## 程式和素材在哪裡
- `app/`：Flutter 程式。`lib/core/` 是內容、出題（`rounds.dart`）、念數字和量詞（`speech.dart`）、存檔和規則（`game.dart`）、聲音和語音；`lib/app/` 是路由、休息時間和共用的元件；`lib/features/` 是農場首頁、六個地方、休息、家長模式。
- `design/art/`：用 Python 畫的圖（木刻版畫風），`python3 build.py all` 全部重畫，`fluttercheck` 用真的 flutter_svg 比對；`icon.py` 是 APP 圖示。約定在 [docs/art.md](docs/art.md)。
- `design/sounds/make_sounds.py`：合成全部的音樂和聲音。
- 測試：在 `app/` 裡 `flutter test`；完整流程 `flutter test test/flow_test.dart`，截圖在 `app/build/screenshots/`；示範影片 `flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true`，再 `python3 tools/demo_audio.py`。

## 授權
- 非商業使用授權：自己、家人使用，或學校、非營利團體的教學，都可以免費使用、修改、分享，要註明出處。
- 商業用途（販賣、收費、廣告、上架）要先取得作者書面同意。也不可以拿來訓練 AI。
- 細節見 [LICENSE](LICENSE)；別人做的部分（字型）見 [NOTICE.md](NOTICE.md)。
