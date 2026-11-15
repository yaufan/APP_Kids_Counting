// Records a demo video of 數數小農場 being played: a scripted child (a white
// dot where the finger is) with a caption under the phone screen; the music
// and sounds the app asked for are written down and mixed in afterwards by
// tools/demo_audio.py.
//
//   flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true
//   python3 ../tools/demo_audio.py
//
// Needs ffmpeg; writes build/demo/demo.mp4, chapters.txt and sounds.txt.
// Skipped in normal test runs.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:counting_farm/app/app.dart';
import 'package:counting_farm/app/strings.dart';
import 'package:counting_farm/core/content.dart';
import 'package:counting_farm/core/game.dart';
import 'package:counting_farm/core/providers.dart';
import 'package:counting_farm/core/sounds.dart';
import 'package:counting_farm/core/store.dart';
import 'package:counting_farm/core/voice.dart';
import 'package:counting_farm/features/parent/parent_gate.dart';

import '../helpers.dart' show loadFonts;
import '../play.dart';

const _phone = Size(390, 844);
const _captionHeight = 84.0;
const _fps = 10;
const _demo = bool.fromEnvironment('DEMO');

/// The music and the sounds asked for, with the frame they were asked at.
class _Recording implements Sounds {
  _Recording(this.frame);

  final int Function() frame;
  final lines = <String>[];
  final _holders = MusicHolders();
  Music? _playing;

  @override
  set music(bool on) {}

  @override
  set effects(bool on) {}

  @override
  void play(String sfx) => lines.add('${frame()} sfx $sfx');

  @override
  void hold(Object owner, Music? music) {
    _holders.hold(owner, music);
    _changed();
  }

  @override
  void release(Object owner) {
    _holders.release(owner);
    _changed();
  }

  void _changed() {
    final now = _holders.current;
    if (now == _playing) return;
    _playing = now;
    lines.add('${frame()} music ${now?.file ?? '-'}');
  }
}

void main() {
  testWidgets('demo video', skip: !_demo, (tester) async {
    await tester.runAsync(loadFonts);
    tester.view.physicalSize = Size(_phone.width * 3, (_phone.height + _captionHeight) * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var frameCount = 0;
    var now = DateTime(2026, 11, 15, 10);
    final track = _Recording(() => frameCount);
    final finger = ValueNotifier<Offset?>(null);
    final caption = ValueNotifier<String>('');
    final key = GlobalKey();
    final store = MemoryStore();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          SizedBox.fromSize(
            size: _phone,
            child: MediaQuery(
              data: const MediaQueryData(size: _phone, devicePixelRatio: 3, padding: EdgeInsets.only(top: 24)),
              child: Stack(children: [
                ProviderScope(
                  overrides: [
                    storeProvider.overrideWithValue(store),
                    savedGameProvider.overrideWithValue(const Game()),
                    soundsProvider.overrideWithValue(track),
                    voiceProvider.overrideWithValue(const SilentVoice()),
                    randomProvider.overrideWithValue(math.Random(3)),
                    clockProvider.overrideWithValue(() => now),
                  ],
                  child: const FarmApp(),
                ),
                IgnorePointer(child: ValueListenableBuilder(valueListenable: finger, builder: (_, at, _) => _Finger(at))),
              ]),
            ),
          ),
          SizedBox(
            width: _phone.width,
            height: _captionHeight,
            child: ColoredBox(
              color: const Color(0xFF8A5A3A),
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: caption,
                  builder: (_, text, _) => Text(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Huninn', color: Colors.white, fontSize: 17, height: 1.35)),
                ),
              ),
            ),
          ),
        ]),
      ),
    ));

    final rec = (await tester.runAsync(() => _Recorder.start(key)))!;
    final marks = <String>[];
    void mark(String name) => marks.add('$name $frameCount');
    Future<void> frames(int n) async {
      for (var i = 0; i < n; i++) {
        frameCount++;
        await tester.runAsync(() async {
          await rec.capture();
          await Future<void>.delayed(const Duration(milliseconds: 15));
        });
        await tester.pump(const Duration(milliseconds: 1000 ~/ _fps));
      }
    }

    Future<void> seconds(double s) => frames((s * _fps).round());
    Future<void> touch(Offset at) async {
      finger.value = at;
      await frames(2);
      await tester.tapAt(at);
      await frames(2);
      finger.value = null;
    }

    Offset at(String l) => tester.getCenter(find.bySemanticsLabel(l).last);
    Future<void> label(String l) async {
      final f = find.bySemanticsLabel(l);
      if (f.evaluate().isEmpty || !tester.getRect(f.last).overlaps(Offset.zero & _phone)) {
        await tester.scrollUntilVisible(f, 120, scrollable: find.byType(Scrollable).first);
        await frames(3);
      }
      await touch(at(l));
    }
    Future<void> tapKey(String id) => touch(tester.getCenter(find.byKey(ValueKey(id)).last));
    ProviderContainer container() => ProviderScope.containerOf(tester.element(find.byType(FarmApp)));
    void change(Game Function(Game) f) => container().read(gameProvider.notifier).change(f);



    final now0 = now;
    final player = Player(tester, tap: (f) => touch(tester.getCenter(f.last)), wait: (ms) => seconds(ms / 1000));
    Future<void> home() async {
      await label(Strings.home);
      await seconds(1.2);
    }

    Future<void> place(Place p) async {
      await tapKey('place-${p.name}');
      await seconds(1);
    }

    // The farm.
    mark('farm');
    caption.value = '數數小農場：3～5 歲在小農場玩數量\n幫農場阿嬤做事，每件工作都是在數數';
    await seconds(3.5);
    caption.value = '六個地方用小路連起來；點牛牛會「哞～」';
    await tapKey('buffalo');
    await seconds(2.5);
    caption.value = '「小雞 3 隻」：小雞排好隊，一隻一隻點著數';
    await tapKey('chick-sign');
    await seconds(1.5);
    for (var i = 0; i < 3; i++) {
      await tapKey('parade-$i');
      await seconds(.7);
    }
    await seconds(2);
    await label(Strings.back);
    await seconds(1);

    // 餵小雞 (小小農夫).
    mark('chicks');
    caption.value = '餵小雞（小小農夫 3～4 歲）：每隻小雞一顆玉米\n點一隻，數一個，下面的珠子亮一顆';
    await place(Place.chicks);
    await player.play();
    caption.value = '小雞躲貓貓：看一眼，有幾隻？\n點哪一張都好，小雞全部出來一起數';
    await player.play();
    await home();

    // 撿雞蛋 (小農夫).
    mark('eggs');
    change((g) => g.withSettings(g.settings.copyWith(level: Level.big)));
    caption.value = '撿雞蛋（小農夫 4～5 歲）：照阿嬤的數字撿蛋\n蛋盒是十格框：上面一排滿了就是 5';
    await place(Place.eggs);
    caption.value = '自己按「好了！」：少了阿嬤陪你數，\n多了那顆蛋跳回雞窩，一起再數一次';
    await player.play(mistakes: true);
    await home();

    // 摘水果.
    mark('fruit');
    caption.value = '摘水果：小羊、小兔、小鴨舉著牌子\n芭樂、香蕉、芒果、橘子、蓮霧、木瓜';
    await place(Place.fruit);
    await player.play();
    caption.value = '比一比：兩排一顆對一顆，誰的多？\n再點多出來的，讓它們一樣多';
    await player.play();
    await home();

    // 分點心: a whole round, then the 回真實生活 card.
    mark('share');
    change((g) => g.withSettings(g.settings.copyWith(level: Level.small)));
    caption.value = '分點心：一隻一個，輪流分\n一直給同一隻？「我已經比較多了，給旁邊的」';
    await place(Place.share);
    await player.play(mistakes: true);
    caption.value = '分完了，每隻一樣多';
    while (find.byKey(const ValueKey('playing')).evaluate().isNotEmpty) {
      await player.play();
    }
    mark('card');
    caption.value = '玩完一輪，農場熱鬧一點\n再來一張「回真實生活」卡，帶到生活裡做做看';
    await seconds(3.5);
    caption.value = '按「好！」收進農場日記（家長看得到），也可以「下次」';
    await label(Strings.ok);
    await seconds(2.5);
    await home();

    // 排排隊.
    mark('garden');
    change((g) => g.withSettings(g.settings.copyWith(level: Level.big)));
    caption.value = '排排隊：菜園的規律，下一個種什麼？\n種錯了菜會長歪，阿嬤念一遍再選';
    await place(Place.garden);
    await player.play(mistakes: true);
    caption.value = '鴨子過橋：照號碼 1、2、3……走過去';
    await player.play();
    await home();

    // 去市場.
    mark('market');
    change((g) => g.withSettings(g.settings.copyWith(sentences: true)));
    caption.value = '去市場：把西瓜裝上小貨車（車斗也是十格框）\n裝好了叭叭開去市場';
    await place(Place.market);
    await player.play();
    caption.value = '多一個：再放一個，現在有幾個？\n（家長打開算式，才會出現 4 ＋ 1 ＝ 5）';
    await player.play();
    await seconds(1);
    await home();

    // Parent mode.
    mark('parent');
    caption.value = '家長答對題目，才能進家長模式';
    const digits = {'零': 0, '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9};
    Future<void> gate() async {
      final parts = (find.textContaining('加').evaluate().first.widget as Text).data!.split(' ');
      for (final d in '${digits[parts[0]]! + digits[parts[2]]!}'.split('')) {
        await touch(tester.getCenter(find.byKey(ValueKey('gate-key-$d'))));
        await frames(3);
      }
    }

    await label(Strings.parent);
    await seconds(1.2);
    await gate();
    await seconds(1.5);
    caption.value = '家長模式：難度、數到幾、玩多久、要玩哪些地方';
    await seconds(3.5);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await seconds(3);
    caption.value = '看進度：1～10 數過幾次、一眼看出選對幾次\n農場日記可以打勾「做過了」';
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await seconds(4);
    await touch(tester.getCenter(find.byIcon(Icons.close_rounded)));
    await seconds(1.5);

    // Rest.
    mark('rest');
    now = now0.add(const Duration(minutes: 30));
    caption.value = '家長設定的時間到了（預設 15 分鐘）\n「換你去做了！去數數家裡的湯匙吧！」';
    await seconds(6);
    caption.value = '';
    mark('end');
    await seconds(0.5);
    expect(ParentPass.take(), isFalse);
    await tester.runAsync(() async {
      await rec.finish();
      File('build/demo/chapters.txt').writeAsStringSync('${marks.join('\n')}\n');
      File('build/demo/sounds.txt').writeAsStringSync('fps $_fps\nframes $frameCount\n${track.lines.join('\n')}\n');
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }, timeout: const Timeout(Duration(minutes: 40)));
}

class _Finger extends StatelessWidget {
  const _Finger(this.at);

  final Offset? at;

  @override
  Widget build(BuildContext context) {
    final p = at;
    if (p == null) return const SizedBox.expand();
    return Stack(children: [
      Positioned(
        left: p.dx - 22,
        top: p.dy - 22,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
            border: Border.all(color: const Color(0xFF4A3B32).withValues(alpha: 0.5), width: 3),
          ),
        ),
      ),
    ]);
  }
}

/// Streams frames of [key]'s boundary into ffmpeg.
class _Recorder {
  _Recorder(this._key, this._ffmpeg);

  final GlobalKey _key;
  final Process _ffmpeg;

  static Future<_Recorder> start(GlobalKey key) async {
    Directory('build/demo').createSync(recursive: true);
    final size = Size(_phone.width * 2, (_phone.height + _captionHeight) * 2);
    final ffmpeg = await Process.start('ffmpeg', [
      '-y', '-loglevel', 'error',
      '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '${size.width.toInt()}x${size.height.toInt()}', '-r', '$_fps', '-i', '-',
      '-vf', 'fps=30', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '24', '-movflags', '+faststart', 'build/demo/demo_silent.mp4',
    ]);
    ffmpeg.stderr.listen(stderr.add);
    return _Recorder(key, ffmpeg);
  }

  Future<void> capture() async {
    final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    _ffmpeg.stdin.add(bytes!.buffer.asUint8List());
    await _ffmpeg.stdin.flush();
  }

  Future<void> finish() async {
    await _ffmpeg.stdin.flush();
    await _ffmpeg.stdin.close();
    final code = await _ffmpeg.exitCode;
    if (code != 0) throw StateError('ffmpeg failed ($code)');
  }
}
