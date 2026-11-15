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
import 'package:counting_farm/features/parent/parent_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'play.dart';

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
}
