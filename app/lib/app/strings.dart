import '../core/content.dart';
import '../core/speech.dart';

/// Everything the app says and shows, in Traditional Chinese (Taiwan). Lines
/// the voice says have their numbers in characters (Say), never digits.
abstract final class Strings {
  static const appName = '數數小農場';

  // The farm (home).
  static const hello = '歡迎來到小農場！今天先去哪裡呢？';
  static const where = '今天先去哪裡呢？';
  static String chickSign(int n) => '小雞 $n 隻';
  static const countChicks = '小雞排好隊了，一隻一隻點著數！';
  static String chicksCounted(int n) => '一共${Say.units(n, '隻')}小雞！';
  static String manyChicks(int counted) => '還有好多好多隻，數到${Say.count(counted)}了，好厲害！';
  static const moo = '哞～我是牛牛。';
  static const lockedPlace = '這個地方在完整版裡，請爸爸媽媽看看。';
  static const parent = '家長';
  static const home = '回農場';
  static const again = '再聽一次';
  static const back = '回去';

  static String placeName(Place p) => p.zh;

  // Shared.
  static String all(int n, Thing t) => '一共${Say.qty(n, t)}！';
  static const playAgain = '再玩一次';
  static String goTo(Place p) => '去${p.zh.startsWith('去') ? p.zh.substring(1) : p.zh}';
  static String roundDone(Place p) => switch (p) {
        Place.chicks || Place.eggs => '做完了！謝謝你幫忙，農場孵出一隻小雞了！',
        Place.fruit => '做完了！謝謝你幫忙，果樹又長出一顆果子！',
        Place.share => '做完了！小動物都吃飽了，謝謝你！',
        Place.garden => '做完了！菜園又多了一棵菜！',
        Place.market => '做完了！市場又多了一筐西瓜！',
      };
  static const doneTitle = '做完了！';
  static const ok = '好！';
  static const later = '下次';
  static const lifeTitle = '回真實生活';
  static const done = '好了！';
  static const sentenceNote = '（家長打開的算式）';

  // 餵小雞.
  static const feedHowTo = '每隻小雞，一顆玉米。點小雞，餵牠吃！';
  static const feedShort = '一隻一顆，餵小雞！';
  static const shortHowTo = '每隻小雞一顆玉米。玉米夠不夠呢？';
  static const fedAlready = '啾？我吃過了，換別隻吧！';
  static String fedAll(int n) => '一共${Say.units(n, '隻')}小雞，${Say.units(n, '顆')}玉米！';
  static const notEnough = '玉米不夠，少一顆！去菜園拔一根吧。';
  static const pullCorn = '去菜園拔一根';
  static const pulled = '拔到了！再餵這一隻。';
  static String sameNow(int n) => '現在一樣多了！${Say.units(n, '隻')}小雞，${Say.units(n, '顆')}玉米！';
  static const peekHowTo = '小雞躲貓貓！看仔細，有幾隻？';
  static const peekAsk = '有幾隻呢？點一張卡。';
  static const peekCount = '小雞都出來了，我們一起數！';
  static String peekAll(int n) => '一共${Say.units(n, '隻')}小雞！';
  static const peekRight = '你一眼就看出來了！';

  // Filling (撿雞蛋, 摘水果, 去市場).
  static String eggOrder(int n) => '阿嬤要${Say.qty(n, Things.egg)}，幫我撿蛋放進蛋盒。';
  static String fruitOrder(Animal a, int n, Thing t) => '${a.zh}說：我要${Say.qty(n, t)}！';
  static String melonOrder(int n) => '市場要${Say.qty(n, Things.melon)}，把西瓜放上小貨車。';
  static const pressDone = '放好了，就按「好了！」的鈴鐺。';
  static String notYet(int have, int want, String unit) =>
      have == 0 ? '還沒有放喔，要${Say.units(want, unit)}。' : '我們數數看：${Say.upTo(have)}。現在${Say.units(have, unit)}，還要${Say.units(want - have, unit)}喔！';
  static String tooMany(int have, int want, Thing t, Animal? who) => who != null
      ? '哇，${Say.units(have, t.unit)}！我只要${Say.units(want, t.unit)}，還你${Say.units(have - want, t.unit)}。'
      : '${Say.qty(have, t)}，比${Say.units(want, t.unit)}多${Say.units(have - want, t.unit)}喔！';
  static String rightAmount(int n) => '${Say.upTo(n)}，剛剛好！';
  static String filled(int n, Thing t, Animal? who) => switch (t.id) {
        'egg' => '好了！一共${Say.qty(n, t)}，送去給阿嬤！',
        'melon' => '好了！一共${Say.qty(n, t)}，叭叭！開去市場囉！',
        _ => '好了！一共${Say.qty(n, t)}。${who?.zh ?? ''}說：謝謝你！',
      };
  static const full = '放滿了！';
  static String howMany(Thing t) => '盒子裡有幾${t.unit}${t.zh}？點一張卡。';
  static const countTogether = '我們一起數一數！';

  // 比一比.
  static String compareMore(Animal a, Animal b) => '${a.zh}和${b.zh}，誰的多？';
  static String compareFewer(Animal a, Animal b) => '${a.zh}和${b.zh}，誰的少？';
  static String compared(Animal a, int na, Animal b, int nb, Thing t, bool more) {
    final winner = more ? (na > nb ? a : b) : (na < nb ? a : b);
    return '${a.zh}${Say.units(na, t.unit)}，${b.zh}${Say.units(nb, t.unit)}，${winner.zh}的${more ? '多' : '少'}！';
  }

  static const makeSame = '讓它們一樣多：點多出來的那一顆。';
  static String same(int n, String unit) => '一樣多了！都是${Say.units(n, unit)}！';
  static const notExtra = '這一顆有伴喔，點旁邊沒有伴的那一顆。';

  // 分點心.
  static String shareHowTo(Animal a, Thing t) => '${t.zh}，${a.zh}一隻一個，輪流分。點籃子！';
  static const youOne = '你一個。';
  static const iHaveMore = '我已經比較多了，給旁邊的！';
  static String shared(Animal a, int each, Thing t) => '分完了！每隻${a.zh}都是${Say.units(each, t.unit)}，一樣多！';

  // 排排隊.
  static String chant(List<Thing> row) => row.map((t) => t.zh).join('、');
  static String patternAsk(List<Thing> row) => '${chant(row)}……下一個種什麼？';
  static String patternRight(List<Thing> row) => '對！${chant(row)}，一直輪流！';
  static String patternAgain(List<Thing> row) => '長歪了！我們念念看：${chant(row)}……';
  static String patternHelp(Thing t) => '阿嬤幫你種：${t.zh}！';
  static String ducksHowTo(int n) => '小鴨子要過橋，照順序走：一號、二號……點一號鴨子！';
  static String duckGo(int d) => '${Say.count(d)}號！';
  static String duckWrong(int d, int want) => '我是${Say.count(d)}號，要找${Say.count(want)}號喔！';
  static String ducksDone(int n) => '${Say.upTo(n)}，全部過橋了！';
  static const pumpkinHowTo = '南瓜排排站：從小小的，排到大大的。先點最小的！';
  static const pumpkinWords = ['小的', '中的', '大的'];
  static const pumpkinWrong = '先找小小的那一顆喔！';
  static const pumpkinDone = '小、中、大，排好了！';

  // 去市場.
  static String moreAsk(int n) => '車上有${Say.qty(n, Things.melon)}，再放一個上去！';
  static String fewerAsk(int n) => '車上有${Say.qty(n, Things.melon)}。阿伯要買一個，拿一個給他！';
  static const nowHowMany = '現在有幾個？點一張卡。';
  static const leftHowMany = '車上還剩幾個？點一張卡。';
  static String moreDone(int start, int result) => '${Say.units(start, '個')}再放一個，一共${Say.units(result, '個')}！';
  static String fewerDone(int start, int result) => '${Say.units(start, '個')}拿走一個，還剩${Say.units(result, '個')}！';
  static const thanksUncle = '阿伯說：謝謝！';

  // The rest.
  static const restTitle = '換你去做了！';
  static const restLine = '小農場休息囉，去數數家裡的湯匙吧！';
  static const restSay = '換你去做了！小農場休息囉，去數數家裡的湯匙吧！';
  static const restParent = '請爸爸媽媽解開';

  // The parent gate.
  static const callParent = '請爸爸媽媽來';
  static const parentGateTitle = '家長確認';
  static String gateQuestion(String a, String b) => '$a 加 $b 等於多少？';
  static String gateWait(int s) => '請等 $s 秒再試';
  static const gateRules = '答錯三次要等一分鐘';
  static const wrongAnswer = '不對喔，換一題';
  static const cancel = '取消';
  static const backspace = '刪掉';

  // Parent mode.
  static const parentTitle = '家長模式';
  static const levelTitle = '難度';
  static String levelLine(Level l) => '${l.zh} ${l.ages}';
  static const levelNote = '小小農夫數到 5，只有點點和東西，不出現數字；小農夫數到 10，數字和點點一起出現，要自己按「好了！」，還有「多一個、少一個」。';
  static const countTitle = '數到幾';
  static String countLine(int? n) => n == null ? '照難度' : '數到 $n';
  static const countNote = '可以和難度分開改，例如 3 歲但已經很會數。數到 20 在 0.2 版。';
  static const playTime = '每次玩多久';
  static String minutes(int m) => '$m 分';
  static const playTimeNote = '時間到了農場黃昏、休息，要家長解開或等一小時。家長模式裡和 APP 放在背景的時間不算。';
  static const resting = '現在在休息時間。';
  static const playOn = '讓小朋友繼續玩';
  static const placesTitle = '要玩哪些地方';
  static const placesNote = '至少留一個。有鎖的是完整版。';
  static const helpTitle = '幫忙和卡片';
  static const sentences = '「多一個、少一個」顯示算式（4 ＋ 1 ＝ 5）';
  static const sentencesNote = '預設關：上小學前先用東西懂「變多、變少」，符號留給小學。';
  static const cards = '回真實生活卡';
  static const cardsNote = '每個地方玩完一張，休息畫面也有一張；關掉就都不出現。';
  static const hints = '阿嬤的提示';
  static const hintsNote = '排排隊錯兩次，對的那個會發亮；第三次阿嬤幫忙。';
  static const soundTitle = '聲音';
  static const voice = '語音（阿嬤說話、數數）';
  static const slow = '念慢一點';
  static const music = '音樂';
  static const effects = '音效';
  static const progressTitle = '看進度（小朋友看不到）';
  static String today(int minutes, List<Place> places) => '今天玩了 $minutes 分鐘${places.isEmpty ? '' : '：${places.map((p) => p.zh).join('、')}'}';
  static const countedTitle = '數過幾次（1～10）';
  static const countedNote = '顏色越深，數到那個數量的次數越多。';
  static const glanceTitle = '一眼看出（選對／出現）';
  static String shareLine(int fair, int all) => all == 0 ? '分點心：還沒玩過' : '分點心：玩了 $all 次，$fair 次一直輪流分';
  static String patternLine(Set<String> kinds) => kinds.isEmpty ? '菜園的規律：還沒種對過' : '菜園的規律：種對過 ${(kinds.toList()..sort()).join('、')}';
  static String farmLine(int chicks, int veg, int fruit) => '農場：小雞 $chicks 隻、菜 $veg 棵、果子 $fruit 顆';
  static const diaryTitle = '農場日記（回真實生活卡）';
  static const diaryEmpty = '還沒有收下的卡片。小朋友在卡片上按「好！」就會出現在這裡，做過了可以打勾。';
  static const fullVersion = '完整版';
  static const fullNote = '測試期間先全部打開。免費版：餵小雞、撿雞蛋、摘水果；完整版：分點心、排排隊、去市場。以後的購買只在這裡。';
  static const fullSwitch = '完整版（測試用）';
  static const about = '關於';
  static const privacy = '不連網、不定位、沒有廣告、沒有帳號、不要任何權限。玩到哪裡只存在這支手機裡。';
  static String version(String v) => '版本 $v';
}
