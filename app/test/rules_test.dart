import 'dart:math' as math;

import 'package:counting_farm/app/strings.dart';
import 'package:counting_farm/core/content.dart';
import 'package:counting_farm/core/game.dart';
import 'package:counting_farm/core/rounds.dart';
import 'package:counting_farm/core/speech.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rules (docs/design.md): numbers said right, every level's amounts in
/// range, dots that never touch, fair shares, one answer per pattern, and
/// what is kept on the phone.
void main() {
  group('how numbers are said', () {
    test('counting says 二, an amount says 兩', () {
      expect(Say.upTo(5), '一、二、三、四、五');
      expect(Say.count(2), '二');
      expect(Say.amount(2), '兩');
      expect(Say.qty(2, Things.chick), '兩隻小雞');
      expect(Say.qty(7, Things.egg), '七顆蛋');
      expect(Say.qty(6, Things.melon), '六個西瓜');
      expect(Say.qty(4, Things.fruit.first), '四顆芭樂');
      expect(Say.qty(2, Things.fruit[1]), '兩根香蕉');
      expect(Say.count(10), '十');
      expect(Say.count(12), '十二');
      expect(Say.amount(12), '十二', reason: '十二隻, never 十兩隻');
      expect(Say.count(20), '二十');
      expect(Say.amount(20), '二十', reason: '二十隻, never 兩十隻');
    });

    test('the number sentence is only shown, and adds up', () {
      expect(Say.sentence(4, 1), '4 ＋ 1 ＝ 5');
      expect(Say.sentence(5, -1), '5 － 1 ＝ 4');
    });

    test('no line for the voice has a digit in it', () {
      final lines = <String>[
        Strings.hello,
        for (var n = 1; n <= 10; n++) ...[
          Strings.fedAll(n),
          Strings.sameNow(n),
          Strings.peekAll(n),
          Strings.eggOrder(n),
          Strings.melonOrder(n),
          Strings.fruitOrder(Animal.sheep, n, Things.fruit[n % 6]),
          Strings.rightAmount(n),
          Strings.filled(n, Things.egg, null),
          Strings.all(n, Things.egg),
          Strings.chicksCounted(n),
          Strings.manyChicks(n),
          Strings.duckGo(n),
          Strings.ducksDone(n),
          Strings.moreAsk(n),
          Strings.fewerAsk(n),
          Strings.moreDone(n, n + 1),
          Strings.fewerDone(n, n - 1),
          Strings.same(n, '顆'),
          Strings.shared(Animal.pig, n, Things.snacks.first),
          for (var m = 0; m < n; m++) Strings.notYet(m, n, '顆'),
          Strings.tooMany(n + 1, n, Things.egg, null),
          Strings.tooMany(n + 2, n, Things.fruit.first, Animal.rabbit),
          Strings.compared(Animal.sheep, n, Animal.duck, n + 2, Things.fruit.first, true),
        ],
        for (final c in lifeCards) c.text,
        Strings.restSay,
      ];
      expect([for (final l in lines) if (Say.hasDigit(l)) l], isEmpty);
      expect(lines.where((l) => RegExp(r'(?<![十])二[隻顆個根條]').hasMatch(l)), isEmpty, reason: '兩隻, never 二隻 (十二隻 is fine)');
    });

    test('小小農夫 is never asked who has fewer', () {
      final r = math.Random(5);
      for (var i = 0; i < 200; i++) {
        for (final t in roundFor(Place.fruit, const Ask(Level.small, 5), r).whereType<CompareTask>()) {
          expect(t.askMore, isTrue);
        }
      }
    });
  });

  group('dots and the ten-frame', () {
    test('dots for 1 to 10 sit inside the card and never touch', () {
      for (var n = 1; n <= 10; n++) {
        final pts = dotLayout(n);
        expect(pts.length, n);
        for (final (x, y) in pts) {
          expect(x, inInclusiveRange(.05, .95));
          expect(y, inInclusiveRange(.05, .95));
        }
        for (var i = 0; i < n; i++) {
          for (var j = i + 1; j < n; j++) {
            final d = math.sqrt(math.pow(pts[i].$1 - pts[j].$1, 2) + math.pow(pts[i].$2 - pts[j].$2, 2));
            expect(d, greaterThan(n > 6 ? .17 : .25), reason: 'dots $i and $j of $n');
          }
        }
      }
    });

    test('a five above the rest: 7 is a full row and two', () {
      final seven = dotLayout(7);
      expect(seven.where((p) => p.$2 < .5).length, 5);
      expect(frameSlot(0), (0, 0));
      expect(frameSlot(4), (4, 0));
      expect(frameSlot(5), (0, 1));
      expect(frameSlot(9), (4, 1));
    });
  });

  group('every round, at every level', () {
    const asks = [Ask(Level.small, 5), Ask(Level.small, 10), Ask(Level.big, 10), Ask(Level.big, 5)];

    void each(void Function(Place p, Ask a, List<Task> round) f) {
      for (final a in asks) {
        for (final p in Place.values) {
          final r = math.Random(a.maxN * 31 + p.index + (a.small ? 0 : 7));
          for (var i = 0; i < 150; i++) {
            f(p, a, roundFor(p, a, r));
          }
        }
      }
    }

    test('amounts stay within how far the child counts', () {
      each((p, a, round) {
        expect(round.length, inInclusiveRange(3, 4));
        for (final t in round) {
          switch (t) {
            case FeedTask(:final chicks, :final corn):
              expect(chicks, inInclusiveRange(2, a.maxN));
              expect(corn, t.short ? chicks - 1 : chicks);
              if (a.small) expect(t.short, isFalse, reason: '夠不夠 is for 小農夫');
            case PeekTask(:final n, :final choices):
              expect(n, inInclusiveRange(1, a.small ? 3 : 5));
              expect(choices.toSet().length, 3);
              expect(choices, contains(n));
            case FillTask(:final target, :final supply):
              expect(target, inInclusiveRange(1, a.maxN));
              expect(supply - target, inInclusiveRange(2, 3), reason: 'enough to put one too many');
            case HowManyTask(:final n, :final choices):
              expect(n, inInclusiveRange(1, a.maxN));
              expect(choices.toSet().length, 3);
              expect(choices, contains(n));
              expect(choices.every((c) => c >= 1 && c <= a.maxN), isTrue);
            case CompareTask(:final a, :final b):
              expect(a, isNot(b));
              expect(math.max(a, b), lessThanOrEqualTo(10));
              final d = (a - b).abs();
              if (round.length == 3) {
                expect(d, greaterThanOrEqualTo(3), reason: '小小農夫: far apart');
              } else {
                expect(d, inInclusiveRange(1, 2), reason: '小農夫: one or two apart');
              }
            case ShareTask(:final eaters, :final each, :final total):
              expect(eaters, a.small ? 2 : inInclusiveRange(2, 3));
              expect(each, greaterThanOrEqualTo(1));
              expect(total, lessThanOrEqualTo(math.min(a.small ? 6 : 9, a.maxN)));
              expect(total % eaters, 0, reason: 'shared out evenly, nothing left over');
            case PatternTask():
              break;
            case DucksTask(:final standing):
              expect(standing.toSet(), {for (var i = 1; i <= standing.length; i++) i});
              expect(standing.length, a.small ? 3 : math.min(5, a.maxN));
            case PumpkinTask(:final standing):
              expect(standing.toSet(), {0, 1, 2});
              expect(standing, isNot([0, 1, 2]));
            case ChangeTask(:final start, :final delta, :final choices):
              expect(a.small, isFalse, reason: '多一個、少一個 is for 小農夫');
              expect(delta.abs(), 1);
              expect(t.result, inInclusiveRange(1, a.maxN));
              expect(start, inInclusiveRange(1, a.maxN));
              expect(choices, contains(t.result));
              expect(choices.toSet().length, 3);
          }
        }
      });
    });

    test('小小農夫 set to count to 10 counts past five in 餵小雞, 摘水果 and 去市場 too', () {
      for (final maxN in [5, 10]) {
        final most = <Place, int>{};
        for (final p in [Place.chicks, Place.fruit, Place.market]) {
          final r = math.Random(maxN + p.index);
          for (var i = 0; i < 200; i++) {
            for (final t in roundFor(p, Ask(Level.small, maxN), r)) {
              final n = switch (t) {
                FeedTask(:final chicks) => chicks,
                FillTask(:final target) => target,
                _ => 0,
              };
              most[p] = math.max(most[p] ?? 0, n);
            }
          }
        }
        for (final p in [Place.chicks, Place.fruit, Place.market]) {
          if (maxN == 5) {
            expect(most[p], 5, reason: '$p counts to five');
          } else {
            expect(most[p], greaterThan(5), reason: '$p: a parent set it to count to 10');
          }
        }
      }
    });

    test('the amounts to fill differ within a round', () {
      each((p, a, round) {
        final fills = [for (final t in round) if (t is FillTask) t.target];
        expect(fills.toSet().length, fills.length, reason: '$p $fills');
      });
    });

    test('a pattern has exactly one right seed', () {
      each((p, a, round) {
        for (final t in round.whereType<PatternTask>()) {
          expect(a.small ? ['AB'] : ['AB', 'AAB', 'ABB'], contains(t.kind));
          final unit = t.kind.length;
          final full = [...t.row, t.answer];
          for (var i = unit; i < full.length; i++) {
            expect(full[i], full[i - unit], reason: 'the row repeats its unit');
          }
          expect(full.toSet().length, 2, reason: 'two vegetables in the row');
          expect(t.options.toSet().length, 3);
          expect(t.options.where((o) => o == t.answer).length, 1);
          expect(t.row.length, inInclusiveRange(4, 5));
        }
      });
    });

    test('the rounds are what the design lists', () {
      List<Type> kinds(Place p, Ask a) => [for (final t in roundFor(p, a, math.Random(1))) t.runtimeType];
      const small = Ask(Level.small, 5), big = Ask(Level.big, 10);
      expect(kinds(Place.chicks, small), [FeedTask, PeekTask, FeedTask, PeekTask]);
      expect(kinds(Place.eggs, big), [FillTask, FillTask, HowManyTask]);
      expect(kinds(Place.fruit, small), [FillTask, FillTask, CompareTask]);
      expect(kinds(Place.fruit, big), [FillTask, CompareTask, FillTask, CompareTask]);
      expect(kinds(Place.share, small), [ShareTask, ShareTask, ShareTask]);
      expect(kinds(Place.garden, small), [PatternTask, PumpkinTask, DucksTask]);
      expect(kinds(Place.garden, big), [PatternTask, DucksTask, PatternTask]);
      expect(kinds(Place.market, small), [FillTask, FillTask, FillTask]);
      expect(kinds(Place.market, big), [FillTask, ChangeTask, ChangeTask]);
      final feeds = roundFor(Place.chicks, big, math.Random(1)).whereType<FeedTask>().toList();
      expect([for (final f in feeds) f.short], [false, true], reason: '小農夫: 夠不夠 second');
    });
  });

  group('the game kept on the phone', () {
    test('settings: what a parent turned off stays off; one place is always left', () {
      var s = const Settings();
      s = s.copyWith(places: {Place.share});
      expect(s.places, {Place.share});
      s = s.copyWith(places: {});
      expect(s.places, {Place.chicks}, reason: 'never nothing to play');
      final free = const Settings(full: false).copyWith(places: {Place.garden, Place.market});
      expect(free.places, containsAll([Place.garden, Place.market, Place.chicks]), reason: 'a free place stays playable');
      expect(free.enabled(Place.garden), isFalse);
      expect(free.enabled(Place.chicks), isTrue);
      final back = Settings.fromJson(const Settings(cards: false, hints: false, sentences: true, countTo: 10, places: {Place.eggs}).toJson());
      expect(back.cards, isFalse);
      expect(back.hints, isFalse);
      expect(back.sentences, isTrue);
      expect(back.countTo, 10);
      expect(back.places, {Place.eggs});
      expect(back.maxN, 10);
      expect(const Settings(level: Level.big).maxN, 10);
      expect(const Settings().maxN, 5);
      expect(const Settings(countTo: 10).copyWith(byLevel: true).countTo, isNull);
      expect(Settings.fromJson(const {'minutes': 7, 'countTo': 20, 'places': ['nope']}).minutes, 15);
    });

    test('progress, the farm and the diary survive a save', () {
      final now = DateTime(2026, 11, 15, 10);
      var g = const Game().count(5).count(5).count(3).glance(4, true).glance(4, false).shared(true).shared(false).planted('AB');
      g = g.finished(Place.chicks, now).finished(Place.eggs, now).finished(Place.garden, now);
      g = g.keep(lifeCards.first, Days.key(now)).keep(lifeCards.first, Days.key(now)).tick(0, true);
      final back = Game.fromJson(g.toJson());
      expect(back.counted, {5: 2, 3: 1});
      expect(back.glances[4]!.asked, 2);
      expect(back.glances[4]!.right, 1);
      expect(back.shares, 2);
      expect(back.fairShares, 1);
      expect(back.patterns, {'AB'});
      expect(back.farm.chicks, 5);
      expect(back.farm.veg, 1);
      expect(back.diary.length, 1, reason: 'the same card on the same day once');
      expect(back.diary.single.done, isTrue);
      expect(back.log(now).places, {Place.chicks, Place.eggs, Place.garden});
      expect(Game.fromJson(const {'farm': {'chicks': -4}, 'counted': {'99': 3, 'x': 1}, 'diary': [{'card': 'nope', 'day': '2026-11-15'}]}).toJson()['counted'], isEmpty);
      expect(Game.fromJson(const {'farm': {'chicks': 1}}).farm.chicks, 3);
    });

    test('the cards go round, five a place', () {
      var g = const Game();
      final seen = <String>[];
      for (var i = 0; i < 6; i++) {
        seen.add(g.cardFor(Place.market).id);
        g = g.cardShown(Place.market);
      }
      expect(seen.take(5).toSet().length, 5);
      expect(seen[5], seen[0]);
      for (final p in Place.values) {
        expect(cardsOf(p).length, 5);
      }
      expect(lifeCards.map((c) => c.id).toSet().length, lifeCards.length);
    });

    test('the diary keeps the last sixty', () {
      var g = const Game();
      for (var d = 1; d <= 70; d++) {
        g = g.keep(lifeCards[d % lifeCards.length], Days.key(DateTime(2026, 1, 1).add(Duration(days: d))));
      }
      expect(g.diary.length, Game.maxDiary);
      expect(Game.fromJson(g.toJson()).diary.length, Game.maxDiary);
      expect(g.diary.last.day, '2026-03-12');
    });

    test('today\'s minutes start again on a new day', () {
      final g = const Game().played(DateTime(2026, 11, 15, 23, 50), 300);
      expect(g.log(DateTime(2026, 11, 15, 23, 59)).seconds, 300);
      expect(g.log(DateTime(2026, 11, 16, 0, 1)).seconds, 0);
      expect(g.played(DateTime(2026, 11, 16, 0, 1), 60).log(DateTime(2026, 11, 16, 0, 2)).seconds, 60);
    });

    test('the rest lasts an hour; a clock moved back does not lock the app', () {
      final at = DateTime(2026, 11, 15, 10);
      final g = const Game().rest(at);
      expect(g.resting(at.add(const Duration(minutes: 59))), isTrue);
      expect(g.resting(at.add(const Duration(minutes: 61))), isFalse);
      expect(g.resting(at.subtract(const Duration(minutes: 5))), isFalse);
      expect(g.playOn().restSince, isNull);
    });

    test('the farm only grows', () {
      var f = const Farm();
      for (final p in Place.values) {
        f = f.grow(p);
      }
      expect(f.chicks, 5);
      expect([f.fruit, f.meals, f.veg, f.melons], [1, 1, 1, 1]);
    });
  });
}
