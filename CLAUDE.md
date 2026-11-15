# 給 Claude 的專案規則（數數小農場）

這份是這個專案的「記憶」。每個在這個專案裡工作的 Claude 都要照著做。它是「畫畫小鎮」（https://github.com/yaufan/APP_Kids_Paint）、「字母寵物」（https://github.com/yaufan/APP_Kids_Paint_for_learning_writing）、「動物小餐廳」（https://github.com/yaufan/APP_Kids_Cook）、「小卡認天下」（https://github.com/yaufan/APP_Kids_Card_Game）、「想一想樂園」（https://github.com/yaufan/APP_Kids_Brainstorming）、「眼尖尖大挑戰」（https://github.com/yaufan/APP_Kids_FalseCharge）、「迷宮小冒險」（https://github.com/yaufan/APP_Kids_maze）「小小生活家」（https://github.com/yaufan/APP_Kids_live_circ）、「小小音樂家」（https://github.com/yaufan/APP_Kids_Music）、「心情小屋」（https://github.com/yaufan/APP_Kids_Feelings）、「晚安小鎮」（https://github.com/yaufan/APP_Kids_Goodnight）、「安全小隊」（https://github.com/yaufan/APP_Kids_Safety）和「ㄅㄆㄇ小火車」（https://github.com/yaufan/APP_Kids_Bopomofo）的兄弟 APP，技術和流程照那邊（畫風不同），這裡寫這個專案自己的事。程式的架構最接近ㄅㄆㄇ小火車和安全小隊（Python 畫 SVG、ParentPass、休息時間、等語音念完、只跟第一根手指），有疑問先看那邊怎麼做。

## 和使用者合作
- **一律用繁體中文回覆**，用白話說明，少用技術名詞；要用的話順便解釋。
- 使用者用手機上的 Claude App 看對話，**打不開 artifact 連結**。圖片、影片、聲音、QR code 都用傳檔案的方式（SendUserFile）給。
- 設計階段：每個想法都畫成草圖（`docs/mockups/`）傳給使用者看，再問。
- 之後每做完一版：給示範影片片段、手機截圖、下載 QR code（和畫畫小鎮一樣）。
- 有要使用者決定的事，列出選項和我的建議，再問。
- 不要開 pull request，除非使用者要求。用了網路搜尋，回覆最後附「Sources:」和連結。

## 這個 APP
- 給 **3～5 歲**的小朋友，在台灣，國語為主：玩數量。到台灣鄉下的小農場幫農場阿嬤做事，每件工作都是在數數：一個一個點著數、一眼看出有幾個、看數字拿東西、比多比少、平分、排順序、找規律；小農夫再玩「多一個、少一個」（不教正式的加減）。
- 六個地方（0.1 全做）：餵小雞（一隻一顆、夠不夠、小雞躲貓貓）、撿雞蛋（十格框的蛋盒、盒子裡有幾顆）、摘水果（六種台灣水果、比一比）、分點心（輪流分、一樣多）、排排隊（菜園的規律、鴨子過橋、南瓜排排站）、去市場（裝西瓜上小貨車、多一個少一個）。每個地方玩完一張「回真實生活」卡（30 張），收進農場日記給家長看。
- 兩個難度：小小農夫（3～4 歲，數到 5、只有點點不出現數字）、小農夫（4～5 歲，數到 10、數字＋點點、自己按「好了」）；家長也可以單獨改「數到幾」。
- 帶路的是農場阿嬤；小水牛牛牛、小雞、小豬這些是農場的動物。農場會慢慢變熱鬧（孵出小雞、多一棵菜），沒有星星和分數。
- 設計在 [docs/design.md](docs/design.md)，改設計時一起改它；草圖在 `docs/mockups/`（畫的是 A 木頭玩具風，只看排版）；圖和程式的約定在 [docs/art.md](docs/art.md)。
- 畫風：**木刻版畫風**，只做一種（米色紙上平平的油墨色塊、深色的邊、紙色的刀痕）。刀痕要少、只刻在東西的邊邊，要數的東西中間不刻，每個要數的東西看起來是一整塊。要和兄弟 APP 的畫風**不一樣**。
- 不會失敗：沒有倒數、沒有扣分、沒有排名、沒有錯誤音；做錯只是一件好笑的事，再一起數一次。
- 只有國語；量詞要對（5 隻小雞、7 顆蛋），說數量時「兩」不說「二」（`core/speech.dart`）。
- 每次玩多久由家長設定（預設 15 分鐘），時間到了農場黃昏、牛牛打瞌睡，說「換你去做了！去數數家裡的湯匙吧！」。
- 加減的算式（4＋1＝5）預設不出現，家長可以打開。
- 免費版：餵小雞、撿雞蛋、摘水果（數到 10）；完整版：分點心、排排隊、去市場。購買只在家長模式。
- 技術名稱：Flutter 專案 `counting_farm`、applicationId `com.yaufan.countingfarm`、APK `counting-farm-版本-arm64.apk`、簽章環境變數 `COUNTING_FARM_KEYSTORE`（密碼 `COUNTING_FARM_KEYSTORE_PASSWORD`）。
- 資安：不接受別的 APP 傳來的頁面（`flutter_deeplinking_enabled` 關掉、`overridePlatformDefaultLocation`），家長模式只能從家長關卡進去（`ParentPass`），不要任何權限。
- 不連網、不定位、沒有廣告、沒有帳號。以後上架要收費：免費下載一部分，一次買斷完整版，購買只在家長模式（要過家長關卡）。
- 每個動作都要有音效，全部用程式合成。
- 授權：非商業使用（`LICENSE`），中英文版本；別人做的部分（字型）在 `NOTICE.md`。
- 名稱：數數小農場。GitHub：https://github.com/yaufan/APP_Kids_Counting

## GitHub Actions
- 工作流程（照小小生活家；第一次放上 main 前要先問）：
  - `app.yml`（App）：推到 `main` 而且改到 `app/**` 時跑分析、全部測試（含完整流程）、打包 APK，約 15～20 分鐘。
  - `release.yml`（Release）：推到 `main` 而且改到 `app/pubspec.yaml`、`CHANGELOG.md` 或它自己時，版本還沒發布過就打包三個 APK 放上 Releases，約 20 分鐘；版本沒變約 1 分鐘。
  - `cleanup.yml`：手動，刪舊的建置檔案，約 1 分鐘。
- 推工作分支（`claude/...`）不會啟動任何工作流程。
- 簽章：和畫畫小鎮用**同一把測試金鑰**（別名 `kidspaint`），Secrets 名稱一樣：`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`，要放在這個專案的 Actions → Secrets → Repository secrets。指紋 `TEST_KEY_SHA256` 寫在工作流程裡。以後上架要換成正式的上傳金鑰。
- 發新版本：`app/pubspec.yaml` 的 `version`、`app/lib/app/version.dart` 的預設值、`CHANGELOG.md` 最上面一段（`## 版本 …`）三個要一致（`test/version_test.dart` 檢查）。
- **任何會啟動 Actions 的動作，都要先問使用者，等使用者同意才做**，問的時候說清楚四件事：
  1. 會跑哪些工作流程。
  2. 這次大約用掉幾分鐘。
  3. 這個月目前用了多少。
  4. 跑完大約還剩多少。

  規則和畫畫小鎮的 `CLAUDE.md` 一樣；那個帳號每月 2,000 分鐘是所有私有專案共用的，Mac 主機的 1 分鐘算 10 分鐘。

## Git
- **發布新版本、做成可以安裝的 APK、給下載 QR code**：照 skill `release-kids-app`（`.claude/skills/release-kids-app/SKILL.md`），兄弟 APP 共用同一份。
- 在系統指定的 `claude/...` 工作分支上開發，commit 完就推這個分支。
- commit 訊息用英文寫清楚改了什麼和為什麼，結尾加系統要求的署名行。不要寫模型名稱。
- 不能 commit：金鑰、密碼、不公開的文件、`__pycache__`。

## 和畫畫小鎮共用的做法（開始寫程式時照著做）
- Flutter 3.47.8、Riverpod、flutter_svg、audioplayers、flutter_tts。存檔是一個 JSON 檔（`app/lib/core/store.dart`），沒有用 drift，所以本機跑測試**不用** sqlite 那段，直接 `flutter test`。
- 觸控：用原始的手指事件（`Listener`），手指一碰就畫。不要用拖曳手勢，它要移動 36 點才開始，小朋友短短的一筆會不見。
- 圖和聲音都用程式產生（SVG 用 Python 畫；聲音用 numpy 合成），不用別人的素材。
- 本機測試：在 `app/` 裡 `flutter test`（不含 `test/flow_test.dart`），`flutter analyze` 要零問題。以後加了 drift，才照畫畫小鎮的 `tools/run_tests.sh`（pubspec 的 sqlite 那段不能 commit）。
- 完整流程和截圖：`flutter test test/flow_test.dart`，截圖在 `app/build/screenshots/`。
- 示範影片（每一版都要給使用者）：在 `app/` 裡 `flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true`（約 5～10 分鐘，要 ffmpeg），再在專案根目錄 `python3 tools/demo_audio.py` 把背景音樂和音效混進去。輸出 `app/build/demo/demo.mp4`；`chapters.txt` 是每一段開始的格數（每秒 10 格），用來剪新功能的片段。

## 程式在哪裡
- `app/lib/core/`：內容的名字（`content.dart`：難度 `Level`、六個地方 `Place`、要數的東西和量詞 `Things`、動物、30 張回真實生活卡）、出題（`rounds.dart`：每個地方一輪的題目、每個難度的範圍、點點 `dotLayout` 和十格框的位置、比一比的差距、剛好分完、規律的答案只有一個、多一個少一個）、怎麼念數字（`speech.dart`：數數念「二」、數量念「兩」、量詞、算式只顯示不念；語音永遠拿不到阿拉伯數字）、存檔的東西（`game.dart`：設定、每個數量數過幾次、一眼看出、分點心、規律、農場長大、卡片輪流、農場日記、今天、休息）、聲音（`sounds.dart`，數數的音 `count_1`～`count_10`）、語音、存檔、`providers.dart`（含一輪還在玩的旗子 `roundBusyProvider`）。
- `app/lib/app/`：路由和休息時間（`app.dart`：`RestGuard`，家長模式和背景的時間不算，正在玩的一輪先玩完最多一分鐘）、顏色（`theme.dart` 的 `Inks`）、所有的字（`strings.dart`）、共用元件（`widgets.dart`：`Pressable`、`Pickable`（點或拖到哪裡放開都算放進去、只跟第一根手指、取消就回原位）、`CountTiles`、`TenFrame`、`ChoiceCard`、`DotFace`、`Later`（等語音念完）、`speak` 和 `HushOnLeave`）、`farm_layout.dart`（`design/art/farm.py` 產生）。
- `app/lib/features/`：農場首頁（`farm/`）、每個地方共用的一輪（`place/`：`place_screen.dart`、`task_host.dart` 的 `TaskHost` 和一起數 `CountAlong`）、餵小雞和躲貓貓（`chicks/`）、裝東西（`eggs/fill_view.dart`：撿雞蛋、摘水果、去市場共用；盒子裡有幾顆）、比一比（`fruit/`）、分點心（`share/`）、規律／鴨子／南瓜（`garden/`）、多一個少一個（`market/`）、休息（`rest/`）、家長關卡和家長模式（`parent/`）。
- 圖：`design/art/`（`kit.py` 木刻版畫畫法：刀痕用 shapely 算好、不用 clipPath、要數的東西中間不刻；`animals.py`、`food.py`、`farm.py`、`ui.py`、`icon.py`；`build.py all`、`sheet`、`fluttercheck`），約定在 `docs/art.md`。聲音：`design/sounds/make_sounds.py`（44 個檔，README 有每一個）。
- 測試：`rules_test`（念數字、出題範圍、點點不重疊、規律只有一個答案、存檔）、`art_test`、`safety_test`、`version_test`、`screens_test`（玩的時間、背景、正在玩的一輪、換畫面時的語音、等語音念完、取消的手指和第二根手指、家長關掉的東西、過午夜的卡片、三個聲音開關、太少和太多）、`flow_test`（手機和平板、兩個難度、六個地方，截圖 31 張）、`demo/demo_video_test.dart`（`--dart-define=DEMO=true`，再 `python3 tools/demo_audio.py`）。`test/play.dart` 是測試和示範影片共用的「小朋友怎麼玩每一題」。

## 目前的狀態（2026-11-15）
- 0.1.0 做好了，**還沒發布**：本機的分析、全部測試、完整流程（手機和平板）、示範影片都過了，commit 在 `claude/relaxed-albattani-6mbwpz` 分支。
- GitHub 專案 `APP_Kids_Counting` 可能還沒建；建好以後推工作分支，再照 skill `release-kids-app` 問使用者能不能推 `main`（第一次推 main 會跑 App 和 Release，各約 7～20 分鐘；Secrets 要先放好）。
- 還沒在真手機上試過：TTS 念數字和量詞（「兩隻小雞」「七顆蛋」）、念的速度和數數的節奏、拖東西的手感、聲音好不好聽和大小（做的時候沒辦法用耳朵聽）、木刻刀痕在小螢幕上會不會讓小朋友分心、平板上放大後的樣子。
