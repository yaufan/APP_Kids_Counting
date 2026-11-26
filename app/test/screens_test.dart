import 'dart:async';

import 'package:counting_farm/app/strings.dart';
import 'package:counting_farm/app/widgets.dart';
import 'package:counting_farm/core/content.dart';
import 'package:counting_farm/core/game.dart';
import 'package:counting_farm/core/providers.dart';
import 'package:counting_farm/core/sounds.dart';
import 'package:counting_farm/core/voice.dart';
import 'package:counting_farm/features/eggs/fill_view.dart';
import 'package:counting_farm/features/garden/garden_views.dart';
import 'package:counting_farm/features/market/change_view.dart';
import 'package:counting_farm/features/parent/parent_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'play.dart';

/// A music player that takes as long as the test says to start a tune.
class SlowLoop implements MusicLoop {
  final calls = <String>[];
  String? playing;
  Completer<void>? loading;

  @override
  Future<void> stop() async {
    calls.add('stop');
    playing = null;
  }

  @override
  Future<void> play(String file, double volume) async {
    calls.add('play $file');
    final c = loading = Completer<void>();
    await c.future;
    playing = file;
  }
}

/// The answer to the gate's question (「七 加 五 等於多少？」).
int _answer(String q) {
  const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  final ns = [for (final ch in q.split('')) if (digits.contains(ch)) digits.indexOf(ch)];
  return ns[0] + ns[1];
}

/// The lessons from the sibling apps' reviews, checked from the start: play
/// time, the voice between screens, the first finger only, what a parent
/// turned off, midnight, and each sound switch on its own.
void main() {
  Player playerFor(TestApp app) => Player(app.tester, tap: (f) async {
        await app.tester.tap(f.last, warnIfMissed: false);
        await app.settle(120);
      }, wait: (ms) => app.settle(ms));

  /// Plays the round on screen to its end (the card or the done panel).
  Future<void> playRound(TestApp app) async {
    final p = playerFor(app);
    var n = 0;
    while (find.byKey(const ValueKey('playing')).evaluate().isNotEmpty && n++ < 6) {
      await p.play();
    }
    await app.settle(2400);
  }

  testWidgets('time in parent mode is not the child\'s play time', (tester) async {
    final app = await TestApp.start(tester);
    app.now = app.now.add(const Duration(minutes: 10));
    await app.settle(2600);
    ParentPass.grant();
    app.go('/parent');
    await app.settle(2600);
    app.now = app.now.add(const Duration(minutes: 20));
    await app.settle(2600);
    expect(app.location, '/parent');
    app.go('/');
    await app.settle(2600);
    expect(app.location, '/', reason: 'the child has played 10 of the 15 minutes');
    app.now = app.now.add(const Duration(minutes: 6));
    await app.settle(2600);
    expect(app.location, '/rest');
    await app.end();
  });

  testWidgets('today\'s minutes do not count while the app is in the background', (tester) async {
    final app = await TestApp.start(tester);
    await app.settle(2600);
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    for (var i = 0; i < 4; i++) {
      await app.settle(30000);
    }
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await app.settle(400);
    expect(app.game.log(app.now).seconds, lessThan(10), reason: 'two minutes away are not two minutes played');
    await app.end();
  });

  void hide(WidgetTester tester) {
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
  }

  void show(WidgetTester tester) {
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
  }

  testWidgets('time in the background is not the child\'s play time, and a clock moved back gives none', (tester) async {
    final app = await TestApp.start(tester);
    app.now = app.now.add(const Duration(minutes: 10));
    await app.settle(2600);
    hide(tester);
    app.now = app.now.add(const Duration(minutes: 8));
    await app.settle(2600);
    show(tester);
    await app.settle(2600);
    expect(app.location, '/', reason: '10 of the 15 minutes played; 8 in the background are not play');
    app.now = app.now.subtract(const Duration(hours: 1));
    await app.settle(2600);
    expect(app.location, '/');
    app.now = app.now.add(const Duration(minutes: 6));
    await app.settle(2600);
    expect(app.location, '/rest', reason: '16 minutes played: the clock moved back an hour gave no extra hour');
    await app.end();
  });

  testWidgets('a clock moved back while the app is away gives no extra time either', (tester) async {
    final app = await TestApp.start(tester);
    app.now = app.now.add(const Duration(minutes: 12));
    await app.settle(2600);
    hide(tester);
    app.now = app.now.subtract(const Duration(hours: 2));
    show(tester);
    await app.settle(2600);
    expect(app.location, '/');
    app.now = app.now.add(const Duration(minutes: 4));
    await app.settle(2600);
    expect(app.location, '/rest', reason: '12 + 4 minutes played');
    await app.end();
  });

  testWidgets('the next place\'s round is finished first too (the place left behind does not end it)', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(cards: false)), at: '/chicks');
    await app.settle(600);
    await playRound(app);
    await app.tapLabel(Strings.goTo(Place.eggs), ms: 1200);
    await app.settle(1200);
    expect(app.location, '/eggs');
    expect(find.byKey(const ValueKey('playing')), findsOneWidget);
    app.now = app.now.add(const Duration(minutes: 15, seconds: 10));
    await app.settle(2600);
    expect(app.location, '/eggs', reason: '撿雞蛋\'s round is being played');
    app.now = app.now.add(const Duration(minutes: 1));
    await app.settle(2600);
    expect(app.location, '/rest');
    await app.end();
  });

  testWidgets('阿嬤\'s help never sends a pumpkin or a duck again after the child did it', (tester) async {
    final app = await TestApp.start(tester, at: '/garden');
    await app.settle(600);
    await playerFor(app).play();
    expect(find.byType(PumpkinView), findsOneWidget);
    Future<void> tapQuick(String key) async {
      await tester.tap(find.byKey(ValueKey(key)), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 60));
    }

    // Three misses: 阿嬤 will put the small one up herself…
    for (var i = 0; i < 3; i++) {
      await tapQuick('pumpkin-2');
    }
    // …but the child is quicker and puts all three up.
    for (var s = 0; s < 3; s++) {
      await tapQuick('pumpkin-$s');
    }
    await app.settle(1500);
    expect(app.voice.said.where((l) => Strings.pumpkinWords.contains(l)).length, 2, reason: '小的, 中的 once each (大的 ends it)');
    await app.settle(2400);
    expect(find.byType(DucksView), findsOneWidget);
    final n = tester.widget<DucksView>(find.byType(DucksView)).task.n;
    for (var i = 0; i < 3; i++) {
      await tapQuick('duck-$n');
    }
    await tapQuick('duck-1');
    await tapQuick('duck-2');
    await app.settle(1500);
    expect(find.byKey(const ValueKey('tile-2-on')), findsOneWidget, reason: 'duck 2 stays over the bridge');
    expect(app.voice.said.where((l) => l == Strings.duckGo(1)).length, 1);
    await app.end();
  });

  testWidgets('the chicks on the farm are counted only as far as the child counts', (tester) async {
    for (final (level, lined) in [(Level.small, 5), (Level.big, 8)]) {
      final app = await TestApp.start(tester, game: Game(settings: Settings(level: level), farm: const Farm(chicks: 8)));
      // 小小農夫 sees no numerals, not even on the farm's sign.
      expect(find.text(level == Level.small ? '小雞' : '小雞 8 隻'), findsOneWidget);
      expect(find.textContaining('8'), level == Level.small ? findsNothing : findsWidgets);
      await tester.tap(find.byKey(const ValueKey('chick-sign')));
      await app.settle(500);
      expect(find.byKey(ValueKey('parade-${lined - 1}')), findsOneWidget);
      expect(find.byKey(ValueKey('parade-$lined')), findsNothing, reason: '$level: lined up to $lined');
      for (var i = 0; i < lined; i++) {
        await tester.tap(find.byKey(ValueKey('parade-$i')));
        await app.settle(200);
      }
      expect(app.voice.said.last, level == Level.small ? Strings.manyChicks(5) : Strings.chicksCounted(8));
      await app.end();
    }
  });

  test('a line asked for while the voice is still setting up is said, and nothing after a stop', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('flutter_tts');
    final calls = <String>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method == 'speak' ? 'speak:${call.arguments}' : call.method);
      // The phone's speech engine takes a while to start.
      if (call.method == 'awaitSpeakCompletion') await Future<void>.delayed(const Duration(milliseconds: 80));
      return 1;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final voice = SystemVoice();
    final hello = voice.say('歡迎');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final next = voice.say('每隻小雞');
    await Future.wait([hello, next]);
    final spoken = [for (final c in calls) if (c.startsWith('speak:')) c];
    expect(spoken, ['speak:每隻小雞'], reason: 'the newer line, not cut off by the hello');
    expect(calls.indexOf('setLanguage'), lessThan(calls.indexOf('speak:每隻小雞')), reason: 'in Mandarin');
    calls.clear();
    final left = voice.say('一共');
    await voice.stop();
    await left;
    expect(calls.where((c) => c.startsWith('speak:')), isEmpty, reason: 'the screen was left before it was said');
  });

  testWidgets('a round being played is finished first, at most a minute more', (tester) async {
    final app = await TestApp.start(tester, at: '/eggs');
    app.now = app.now.add(const Duration(minutes: 15, seconds: 10));
    await app.settle(2600);
    expect(app.location, '/eggs', reason: 'the round goes on');
    app.now = app.now.add(const Duration(minutes: 1));
    await app.settle(2600);
    expect(app.location, '/rest', reason: 'but not for ever');
    await app.end();
  });

  testWidgets('leaving a screen stops its voice, but never the next screen\'s first line', (tester) async {
    final app = await TestApp.start(tester);
    app.go('/chicks');
    await app.settle(1200);
    expect(app.voice.said.last, Strings.feedHowTo);
    final stops = app.voice.stops;
    await app.tapLabel(Strings.home, ms: 1200);
    expect(app.location, '/');
    expect(app.voice.stops, stops + 1, reason: '餵小雞\'s line does not go on over the farm');
    app.go('/eggs');
    await app.settle(1200);
    expect(app.voice.stops, stops + 1, reason: 'the farm said nothing: the eggs\' first line is not cut');
    expect(app.voice.said.last, startsWith('阿嬤要'));
    await app.end();
  });

  testWidgets('the next step waits until a slow line has been said, but not for ever', (tester) async {
    final line = Completer<void>();
    var ran = 0;
    Later(const Duration(milliseconds: 500), () => ran++, after: line.future);
    await tester.pump(const Duration(seconds: 2));
    expect(ran, 0, reason: 'still speaking');
    line.complete();
    await tester.pump();
    expect(ran, 1);

    Later(const Duration(milliseconds: 500), () => ran++, after: Completer<void>().future, atMost: const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));
    expect(ran, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(ran, 2, reason: 'a voice that never says it is done does not hold the game up');

    Later(const Duration(milliseconds: 500), () => ran++).cancel();
    await tester.pump(const Duration(seconds: 1));
    expect(ran, 2);
  });

  testWidgets('a cancelled touch puts nothing in, and only the first finger counts', (tester) async {
    final app = await TestApp.start(tester, at: '/eggs');
    await app.settle(800);
    int inBox() => find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('in-')).evaluate().length;
    expect(inBox(), 0);
    final egg = tester.getCenter(find.byKey(const ValueKey('supply-0')));
    // A drag cancelled by the system (a call coming in): the egg goes back.
    final g = await tester.startGesture(egg);
    await tester.pump(const Duration(milliseconds: 50));
    await g.moveBy(const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 50));
    await g.cancel();
    await app.settle(300);
    expect(inBox(), 0, reason: 'cancelled is not dropped');
    // A second finger on the same egg while the first holds it does nothing.
    final first = await tester.startGesture(egg);
    await tester.pump(const Duration(milliseconds: 30));
    final second = await tester.startGesture(egg, pointer: 9);
    await second.up();
    await tester.pump(const Duration(milliseconds: 50));
    expect(inBox(), 0, reason: 'the second finger is not the one holding it');
    await first.up();
    await app.settle(300);
    expect(inBox(), 1);
    // A drag let go anywhere puts it in, like a tap.
    final drag = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('supply-1'))));
    await tester.pump(const Duration(milliseconds: 30));
    for (var i = 1; i <= 6; i++) {
      await drag.moveBy(const Offset(0, 40));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await drag.up();
    await app.settle(300);
    expect(inBox(), 2);
    await app.end();
  });

  testWidgets('cards a parent turned off never come, not after a round and not at the rest', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(cards: false)), at: '/share');
    await app.settle(600);
    await playRound(app);
    expect(find.byKey(const ValueKey('life-card')), findsNothing);
    expect(find.text(Strings.playAgain), findsOneWidget, reason: 'straight to again / next / home');
    expect(app.game.diary, isEmpty);
    app.change((g) => g.rest(app.now));
    await app.settle(2600);
    expect(app.location, '/rest');
    expect(find.byKey(const ValueKey('rest-card')), findsNothing);
    await app.end();
  });

  testWidgets('a place turned off is never the next place either', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(places: {Place.chicks, Place.market})), at: '/chicks');
    await app.settle(600);
    await playRound(app);
    await app.tapLabel(Strings.later, ms: 600);
    expect(find.text(Strings.goTo(Place.market)), findsOneWidget, reason: 'not 撿雞蛋, which is off');
    await app.end();
  });

  testWidgets('a card shown before midnight goes in the diary on its own day', (tester) async {
    final app = await TestApp.start(tester, at: '/garden');
    app.now = DateTime(2026, 11, 15, 23, 58);
    app.container.read(sessionStartProvider.notifier).restart();
    await app.settle(600);
    await playRound(app);
    expect(find.byKey(const ValueKey('life-card')), findsOneWidget);
    app.now = DateTime(2026, 11, 16, 0, 1);
    await app.settle(2600);
    await app.tapLabel(Strings.ok, ms: 600);
    expect(app.game.diary.single.day, '2026-11-15');
    expect(app.game.log(app.now).places, isEmpty, reason: 'the new day starts empty');
    await app.end();
  });

  testWidgets('each sound switch silences only its own sound', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(level: Level.big)), at: '/chicks');
    await app.settle(800);
    expect(app.sounds.music, Music.coop);
    void set(Settings Function(Settings s) f) => app.change((g) => g.withSettings(f(g.settings)));
    Future<(int, int, Music?)> tapChick(int i) async {
      final s = app.sounds.played.length, v = app.voice.said.length;
      await tester.tap(find.byKey(ValueKey('chick-$i')));
      await app.settle(300);
      return (app.sounds.played.length - s, app.voice.said.length - v, app.sounds.music);
    }

    set((s) => s.copyWith(sounds: false));
    await app.settle();
    var (sfx, said, music) = await tapChick(0);
    expect(sfx, 0);
    expect(said, 1);
    expect(music, Music.coop);
    set((s) => s.copyWith(sounds: true, music: false));
    await app.settle();
    (sfx, said, music) = await tapChick(1);
    expect(sfx, greaterThan(0));
    expect(said, 1);
    expect(music, isNull);
    set((s) => s.copyWith(music: true, voice: false));
    await app.settle();
    (sfx, said, music) = await tapChick(0);
    expect(sfx, greaterThan(0), reason: 'the chick shakes its head');
    expect(said, 0);
    expect(music, Music.coop);
    await app.end();
  });

  testWidgets('小農夫: too few, then too many, and the extra hops back', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(level: Level.big)), at: '/eggs');
    await app.settle(800);
    final t = tester.widget<FillView>(find.byType(FillView)).task;
    for (var i = 0; i < t.target - 1; i++) {
      await tester.tap(find.byKey(ValueKey('supply-$i')));
      await app.settle(200);
    }
    await tester.tap(find.byKey(const ValueKey('ring')));
    await app.settle(600);
    expect(app.voice.said.last, endsWith('還要一顆喔！'));
    await tester.tap(find.byKey(ValueKey('supply-${t.target - 1}')));
    await app.settle(200);
    await tester.tap(find.byKey(ValueKey('supply-${t.target}')));
    await app.settle(200);
    await tester.tap(find.byKey(const ValueKey('ring')));
    await app.settle(400);
    expect(app.voice.said.last, contains('多一顆喔'));
    await app.settle(1600);
    expect(app.sounds.played, contains('swish'));
    expect(app.game.counted[t.target], 1);
    await app.end();
  });

  group('round 1 fixes', () {
    /// Whether the app asked the phone to close it (the back key's default).
    Future<bool> back(TestApp app) async {
      var closed = false;
      app.tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemNavigator.pop') closed = true;
        return null;
      });
      await app.tester.binding.handlePopRoute();
      await app.settle(600);
      app.tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
      return closed;
    }

    testWidgets('the back key never closes the app: a place goes to the farm, the farm and the rest stay', (tester) async {
      final app = await TestApp.start(tester, at: '/eggs');
      await app.settle(800);
      expect(await back(app), isFalse);
      expect(app.location, '/', reason: 'like the home button');
      expect(await back(app), isFalse, reason: 'on the farm it does nothing');
      expect(app.location, '/');
      ParentPass.grant();
      app.go('/parent');
      await app.settle();
      expect(await back(app), isFalse);
      expect(app.location, '/', reason: 'parent mode goes to the farm');
      app.change((g) => g.rest(app.now));
      await app.settle(2600);
      expect(app.location, '/rest');
      expect(await back(app), isFalse);
      expect(app.location, '/rest', reason: 'the rest stays');
      await app.end();
    });

    testWidgets('the back key on the parent gate only closes the gate', (tester) async {
      final app = await TestApp.start(tester);
      await app.tapLabel(Strings.parent, ms: 800);
      expect(find.byKey(const ValueKey('gate-key-1')), findsOneWidget);
      expect(await back(app), isFalse);
      await app.settle(1200);
      expect(find.byKey(const ValueKey('gate-key-1')), findsNothing);
      expect(app.location, '/');
      await app.end();
    });

    testWidgets('closed and opened again within ten minutes, the sitting goes on', (tester) async {
      final first = await TestApp.start(tester);
      first.now = first.now.add(const Duration(minutes: 12));
      await first.settle(2600);
      hide(tester);
      await first.settle();
      final saved = Game.fromJson(first.store.saved);
      expect(saved.sitting, isNotNull);
      expect(saved.sitting!.used.inMinutes, 12);
      final closedAt = first.now;
      // (Frames only come with the app in sight: closed after it is back.)
      show(tester);
      await first.end();
      // Opened again five minutes later: 3 of the 15 minutes are left.
      final app = await TestApp.start(tester, game: saved, now: closedAt.add(const Duration(minutes: 5)));
      app.now = app.now.add(const Duration(minutes: 2));
      await app.settle(2600);
      expect(app.location, '/');
      app.now = app.now.add(const Duration(minutes: 2));
      await app.settle(2600);
      expect(app.location, '/rest', reason: 'closing the app gave no new 15 minutes');
      await app.end();
    });

    testWidgets('a sitting saved before going away goes on only within ten minutes', (tester) async {
      final t0 = DateTime(2026, 11, 15, 10);
      // Played 12 minutes, closed 4 minutes ago: 3 minutes are left.
      final soon = await TestApp.start(tester, game: Game(sitting: Sitting(const Duration(minutes: 12), t0.subtract(const Duration(minutes: 4)))));
      soon.now = soon.now.add(const Duration(minutes: 2));
      await soon.settle(2600);
      expect(soon.location, '/');
      soon.now = soon.now.add(const Duration(minutes: 2));
      await soon.settle(2600);
      expect(soon.location, '/rest', reason: '12 + 4 minutes: the closed time did not count, the minutes played did');
      await soon.end();
      // Closed eleven minutes ago: a new sitting.
      final late = await TestApp.start(tester, game: Game(sitting: Sitting(const Duration(minutes: 14), t0.subtract(const Duration(minutes: 11)))));
      late.now = late.now.add(const Duration(minutes: 10));
      await late.settle(2600);
      expect(late.location, '/', reason: 'ten minutes away was a rest');
      await late.end();
      // A clock moved back while it was closed gives no extra time.
      final back = await TestApp.start(tester, game: Game(sitting: Sitting(const Duration(minutes: 14), t0.add(const Duration(hours: 2)))));
      back.now = back.now.add(const Duration(minutes: 1, seconds: 10));
      await back.settle(2600);
      expect(back.location, '/rest');
      await back.end();
    });

    testWidgets('the rest begins and ends a sitting: nothing to go on with after it', (tester) async {
      final app = await TestApp.start(tester);
      app.now = app.now.add(const Duration(minutes: 16));
      await app.settle(2600);
      expect(app.location, '/rest');
      expect(app.game.sitting, isNull);
      hide(tester);
      expect(Game.fromJson(app.store.saved).sitting, isNull, reason: 'no sitting is saved while resting');
      show(tester);
      await app.end();
    });

    testWidgets('parent mode left in the background is closed: the farm, and the gate again', (tester) async {
      final app = await TestApp.start(tester);
      ParentPass.grant();
      app.go('/parent');
      await app.settle();
      expect(app.location, '/parent');
      hide(tester);
      await app.settle();
      show(tester);
      await app.settle();
      expect(app.location, '/');
      app.go('/parent');
      await app.settle();
      expect(app.location, '/', reason: 'the pass was used up');
      await app.end();
    });

    testWidgets('the parent gate closes when the app goes away, and its time is not play time', (tester) async {
      final app = await TestApp.start(tester);
      app.now = app.now.add(const Duration(minutes: 10));
      await app.settle(2600);
      await app.tapLabel(Strings.parent, ms: 800);
      expect(find.byKey(const ValueKey('gate-key-1')), findsOneWidget);
      app.now = app.now.add(const Duration(minutes: 20));
      await app.settle(2600);
      expect(app.location, '/', reason: 'twenty minutes on the gate are not play time');
      hide(tester);
      await app.settle();
      show(tester);
      await app.settle(1200);
      expect(find.byKey(const ValueKey('gate-key-1')), findsNothing, reason: 'a child finds the farm');
      app.now = app.now.add(const Duration(minutes: 4));
      await app.settle(2600);
      expect(app.location, '/');
      app.now = app.now.add(const Duration(minutes: 2));
      await app.settle(2600);
      expect(app.location, '/rest', reason: '10 + 6 minutes played');
      await app.end();
    });

    testWidgets('the gate and parent mode close by themselves after five minutes without a touch', (tester) async {
      final app = await TestApp.start(tester);
      await app.tapLabel(Strings.parent, ms: 800);
      expect(find.byKey(const ValueKey('gate-key-1')), findsOneWidget);
      await tester.pump(const Duration(minutes: 4));
      await tester.tap(find.byKey(const ValueKey('gate-key-0')));
      await tester.pump(const Duration(minutes: 4));
      expect(find.byKey(const ValueKey('gate-key-1')), findsOneWidget, reason: 'a touch starts the five minutes again');
      await tester.pump(const Duration(minutes: 1, seconds: 5));
      await app.settle(1200);
      expect(find.byKey(const ValueKey('gate-key-1')), findsNothing);
      ParentPass.grant();
      app.go('/parent');
      await app.settle();
      await tester.pump(const Duration(minutes: 5, seconds: 5));
      await app.settle();
      expect(app.location, '/');
      await app.end();
    });

    testWidgets('the rest\'s gate lets play go on but does not open parent mode', (tester) async {
      final app = await TestApp.start(tester);
      app.change((g) => g.rest(app.now));
      await app.settle(2600);
      await tester.tap(find.bySemanticsLabel(Strings.parent).last, warnIfMissed: false);
      await app.settle(800);
      expect(find.byType(ParentGatePage), findsOneWidget);
      // The gate's question is on screen: answer it.
      final q = tester.widgetList<Text>(find.textContaining('加')).first.data!;
      final answer = _answer(q);
      for (final d in '$answer'.split('')) {
        await tester.tap(find.byKey(ValueKey('gate-key-$d')));
        await app.settle(100);
      }
      await app.settle(2600);
      expect(app.location, '/');
      app.go('/parent');
      await app.settle();
      expect(app.location, '/', reason: 'no pass left over');
      await app.end();
    });

    testWidgets('the gate\'s wait grows (1, 5, 15 minutes), is kept, and a clock moved back does not lock it for ever', (tester) async {
      var lock = const GateLock();
      final t = DateTime(2026, 11, 15, 10);
      for (var i = 0; i < 3; i++) {
        lock = lock.miss(t);
      }
      expect(lock.locked(t), isTrue);
      expect(lock.left(t), const Duration(minutes: 1));
      expect(lock.locked(t.add(const Duration(minutes: 1))), isFalse);
      for (var i = 0; i < 3; i++) {
        lock = lock.miss(t.add(const Duration(minutes: 2)));
      }
      expect(lock.left(t.add(const Duration(minutes: 2))), const Duration(minutes: 5));
      for (var i = 0; i < 3; i++) {
        lock = lock.miss(t.add(const Duration(minutes: 10)));
      }
      expect(lock.left(t.add(const Duration(minutes: 10))), const Duration(minutes: 15));
      for (var i = 0; i < 3; i++) {
        lock = lock.miss(t.add(const Duration(minutes: 30)));
      }
      expect(lock.left(t.add(const Duration(minutes: 30))), const Duration(minutes: 15), reason: 'never longer than 15');
      expect(lock.locked(t.add(const Duration(minutes: 20))), isFalse, reason: 'a clock moved back is no wait');
      expect(GateLock.fromJson(lock.toJson()).left(t.add(const Duration(minutes: 31))), const Duration(minutes: 14));

      // Kept on the phone: closing the app does not end the wait.
      final app = await TestApp.start(tester);
      await app.tapLabel(Strings.parent, ms: 800);
      for (var i = 0; i < 6 && find.textContaining('請等').evaluate().isEmpty; i++) {
        await tester.tap(find.byKey(const ValueKey('gate-key-0')));
        await app.settle(100);
      }
      expect(find.textContaining('請等'), findsOneWidget);
      final saved = Game.fromJson(app.store.saved);
      expect(saved.gate.locked(app.now), isTrue);
      await app.end();
      final again = await TestApp.start(tester, game: saved);
      await again.tapLabel(Strings.parent, ms: 800);
      expect(find.textContaining('請等'), findsOneWidget, reason: 'still waiting after the app was closed');
      await again.end();
    });

    testWidgets('a quick change of music never plays the wrong tune or plays on after a stop', (tester) async {
      final loop = SlowLoop();
      final sounds = SystemSounds(loop: loop);
      final owner = Object();
      sounds.hold(owner, Music.farm);
      await tester.pump();
      expect(loop.calls, ['stop', 'play music_farm']);
      sounds.hold(owner, Music.coop);
      await tester.pump();
      sounds.hold(owner, null);
      await tester.pump();
      loop.loading!.complete();
      await tester.pump();
      expect(loop.playing, isNull, reason: 'stopped after the start that was loading, not before it');
      expect(loop.calls, ['stop', 'play music_farm', 'stop']);
      sounds.hold(owner, Music.coop);
      await tester.pump();
      loop.loading!.complete();
      await tester.pump();
      expect(loop.playing, 'music_coop');
      sounds.dispose();
    });

    for (final level in [Level.small, Level.big]) {
      testWidgets('on a short phone (360 × 640) the egg box and the market truck are not squashed (${level.name})', (tester) async {
        await tester.runAsync(loadFonts);
        tester.view.padding = const FakeViewPadding(top: 72, bottom: 144);
        final app = await TestApp.start(tester, game: Game(settings: Settings(level: level, countTo: 10)), size: const Size(1080, 1920), ratio: 3, at: '/eggs');
        final p = playerFor(app);
        for (var i = 0; i < 3 && p.kind != 'howmany'; i++) {
          await p.play();
        }
        expect(p.kind, 'howmany');
        final frame = tester.getRect(find.byType(TenFrame));
        final rows = tester.widget<TenFrame>(find.byType(TenFrame)).rows;
        expect(frame.height / frame.width, closeTo((16 + 60 * rows) / 300, .01), reason: 'shrunk whole, not squashed');
        for (final c in find.byType(ChoiceCard).evaluate()) {
          expect(frame.overlaps(tester.getRect(find.byWidget(c.widget))), isFalse, reason: 'the box is above the cards');
        }
        final hen = tester.getRect(find.byWidgetPredicate((w) => w is Art && w.path == 'animals/hen'));
        expect(frame.top, greaterThanOrEqualTo(hen.bottom - 1));
        await shoot(tester, 'small_phone', 'eggs_howmany_${level.name}');
        await app.end();
        if (level == Level.small) return;

        final market = await TestApp.start(tester, game: Game(settings: Settings(level: level, sentences: true)), size: const Size(1080, 1920), ratio: 3, at: '/market');
        final m = playerFor(market);
        for (var i = 0; i < 3 && !(m.kind == 'change' && tester.widget<ChangeView>(find.byType(ChangeView)).task.delta < 0); i++) {
          await m.play();
        }
        await tester.tap(find.byKey(const ValueKey('truck-0')));
        await market.settle(800);
        final truck = tester.getRect(find.byWidgetPredicate((w) => w is Art && w.path == 'farm/truck'));
        final sold = tester.getRect(find.descendant(of: find.byType(PopIn), matching: find.byType(ThingPic)).first);
        expect(sold.bottom, lessThanOrEqualTo(truck.top + 1), reason: 'the melon handed to 阿伯 is not on the truck');
        await shoot(tester, 'small_phone', 'market_fewer');
        await market.end();
      });
    }
  });
}
