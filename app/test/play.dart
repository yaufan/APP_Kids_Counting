import 'dart:math' as math;

import 'package:counting_farm/core/rounds.dart';
import 'package:counting_farm/features/chicks/chick_views.dart';
import 'package:counting_farm/features/eggs/fill_view.dart';
import 'package:counting_farm/features/fruit/compare_view.dart';
import 'package:counting_farm/features/garden/garden_views.dart';
import 'package:counting_farm/features/market/change_view.dart';
import 'package:counting_farm/features/share/share_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plays whatever task is on screen as a child would (the flow test and the
/// demo video use it). [tap] touches a finder, [wait] lets the screen go on.
class Player {
  Player(this.tester, {required this.tap, required this.wait});

  final WidgetTester tester;
  final Future<void> Function(Finder f) tap;
  final Future<void> Function(int ms) wait;

  Finder key(String k) => find.byKey(ValueKey(k));

  bool on<T>() => find.byType(T).evaluate().isNotEmpty;

  /// The kind of task on screen ('feed', 'peek', …), or null.
  String? get kind {
    if (on<FeedView>()) return 'feed';
    if (on<PeekView>()) return 'peek';
    if (on<FillView>()) return 'fill';
    if (on<HowManyView>()) return 'howmany';
    if (on<CompareView>()) return 'compare';
    if (on<ShareView>()) return 'share';
    if (on<PatternView>()) return 'pattern';
    if (on<DucksView>()) return 'ducks';
    if (on<PumpkinView>()) return 'pumpkin';
    if (on<ChangeView>()) return 'change';
    return null;
  }

  /// Plays the task on screen. [mistakes]: a miss or two first (one too
  /// many, a wrong seed…), nothing is ever lost. [midway] is called halfway
  /// (for a screenshot).
  Future<String> play({bool mistakes = false, Future<void> Function()? midway}) async {
    final k = kind;
    Future<void> half() async => midway == null ? null : await midway();
    switch (k) {
      case 'feed':
        final t = tester.widget<FeedView>(find.byType(FeedView)).task;
        await wait(700);
        for (var i = 0; i < t.chicks; i++) {
          await tap(key('chick-$i'));
          await wait(250);
          if (mistakes && i == 0) {
            await tap(key('chick-0'));
            await wait(400);
          }
          if (t.short && i == t.corn - 1) {
            await wait(400);
            if (midway != null) await half();
            await tap(key('pull'));
            await wait(400);
          } else if (i == t.chicks ~/ 2 && !t.short) {
            await half();
          }
        }
        await wait(2600);
      case 'peek':
        final t = tester.widget<PeekView>(find.byType(PeekView)).task;
        await wait(1400);
        await half();
        await wait(2200);
        final pick = mistakes ? t.choices.firstWhere((c) => c != t.n) : t.n;
        await tap(key('card-$pick'));
        await wait(700 * t.n + 2800);
      case 'fill':
        final t = tester.widget<FillView>(find.byType(FillView)).task;
        final ring = key('ring');
        final bell = ring.evaluate().isNotEmpty;
        await wait(700);
        var put = 0;
        Future<void> putOne() async {
          await tap(key('supply-$put'));
          put++;
          await wait(260);
        }

        if (mistakes && bell) {
          while (put < t.target - 1) {
            await putOne();
          }
          await tap(ring);
          await wait(900);
          await half();
          await putOne();
          await putOne();
          await tap(ring);
          await wait(3200);
        } else {
          while (put < t.target) {
            await putOne();
            if (put == (t.target + 1) ~/ 2) await half();
          }
          if (bell) await tap(ring);
        }
        await wait(3000);
      case 'howmany':
        final t = tester.widget<HowManyView>(find.byType(HowManyView)).task;
        await wait(600);
        final pick = mistakes ? t.choices.firstWhere((c) => c != t.n) : t.n;
        await tap(key('card-$pick'));
        await wait(700 * (t.n ~/ 2));
        await half();
        await wait(700 * t.n + 2400);
      case 'compare':
        final t = tester.widget<CompareView>(find.byType(CompareView)).task;
        await wait(600);
        await tap(key('row-${mistakes ? 1 - t.more : t.more}'));
        await wait(2400);
        await half();
        final many = math.max(t.a, t.b), few = math.min(t.a, t.b);
        // 小農夫 then makes them the same (小小農夫's question is over by now).
        if (on<CompareView>() && identical(tester.widget<CompareView>(find.byType(CompareView)).task, t)) {
          if (mistakes) {
            await tap(key('fruit-${t.more}-0'));
            await wait(500);
          }
          for (var i = many - 1; i >= few; i--) {
            if (key('fruit-${t.more}-$i').evaluate().isEmpty) break;
            await tap(key('fruit-${t.more}-$i'));
            await wait(450);
          }
        }
        await wait(2600);
      case 'share':
        final t = tester.widget<ShareView>(find.byType(ShareView)).task;
        await wait(600);
        var given = 0;
        if (mistakes) {
          await tap(key('eater-0'));
          await wait(350);
          await tap(key('eater-0'));
          await wait(600);
          given = 2;
        }
        while (given < t.total) {
          await tap(key('basket'));
          given++;
          await wait(300);
          if (given == t.total ~/ 2) await half();
        }
        await wait(2600);
      case 'pattern':
        final t = tester.widget<PatternView>(find.byType(PatternView)).task;
        await wait(600);
        if (mistakes) {
          final wrong = t.options.firstWhere((o) => o != t.answer);
          await tap(key('seed-${wrong.id}'));
          await wait(500);
          await half();
          await wait(1400);
        } else {
          await half();
        }
        await tap(key('seed-${t.answer.id}'));
        await wait(2600);
      case 'ducks':
        final t = tester.widget<DucksView>(find.byType(DucksView)).task;
        await wait(600);
        if (mistakes) {
          await tap(key('duck-${t.n}'));
          await wait(600);
        }
        for (var d = 1; d <= t.n; d++) {
          await tap(key('duck-$d'));
          await wait(380);
          if (d == (t.n + 1) ~/ 2) await half();
        }
        await wait(2600);
      case 'pumpkin':
        await wait(600);
        if (mistakes) {
          await tap(key('pumpkin-2'));
          await wait(600);
        }
        for (var s = 0; s < 3; s++) {
          await tap(key('pumpkin-$s'));
          await wait(380);
          if (s == 1) await half();
        }
        await wait(2400);
      case 'change':
        final t = tester.widget<ChangeView>(find.byType(ChangeView)).task;
        await wait(700);
        await tap(t.delta > 0 ? key('field-melon') : key('truck-0'));
        await wait(900);
        await half();
        final pick = mistakes ? t.choices.firstWhere((c) => c != t.result) : t.result;
        await tap(key('card-$pick'));
        await wait(700 * t.result + 2800);
      default:
        throw StateError('no task on screen');
    }
    return k!;
  }
}

/// Which kind of task each view is (for the flow's checks).
Type viewOf(Task t) => switch (t) {
      FeedTask() => FeedView,
      PeekTask() => PeekView,
      FillTask() => FillView,
      HowManyTask() => HowManyView,
      CompareTask() => CompareView,
      ShareTask() => ShareView,
      PatternTask() => PatternView,
      DucksTask() => DucksView,
      PumpkinTask() => PumpkinView,
      ChangeTask() => ChangeView,
    };
