import 'package:counting_farm/app/strings.dart';
import 'package:counting_farm/core/content.dart';
import 'package:counting_farm/core/speech.dart';
import 'package:counting_farm/features/parent/parent_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'play.dart';

/// A visit as a child (and a parent) would play it: every place at both
/// levels, on a phone and a tablet, with screenshots in
/// `build/screenshots/<device>/`.
void main() {
  setUpAll(loadFonts);

  for (final MapEntry(key: device, value: (size, ratio)) in {'phone': (const Size(1080, 2340), 2.75), 'tablet': (const Size(1620, 2160), 2.0)}.entries) {
    testWidgets('a day on the farm ($device)', (tester) async {
      final app = await TestApp.start(tester, size: size, ratio: ratio, seed: 3);
      Future<void> shot(String name) => shoot(tester, device, name);
      late final Player player;
      player = Player(tester, tap: (f) async {
        if (f.evaluate().isEmpty) {
          final keys = find.byWidgetPredicate((w) => w.key is ValueKey<String>).evaluate().map((e) => (e.widget.key! as ValueKey<String>).value).toList();
          fail('nothing to tap: $f (${player.kind}, ${app.location}) keys: $keys');
        }
        await tester.tap(f.last, warnIfMissed: false);
        await app.settle(120);
      }, wait: (ms) => app.settle(ms));
      var n = 0;
      String no() => (++n).toString().padLeft(2, '0');

      // The farm: 阿嬤 says hello, 牛牛 moos, the chicks line up to be counted.
      expect(app.location, '/');
      await app.settle(600);
      expect(app.voice.said.last, Strings.hello);
      await shot('${no()}_farm');
      await tester.tap(find.byKey(const ValueKey('buffalo')));
      await app.settle();
      expect(app.sounds.played.last, 'moo');
      await tester.tap(find.byKey(const ValueKey('chick-sign')));
      await app.settle(500);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(ValueKey('parade-$i')));
        await app.settle(300);
      }
      expect(app.voice.said.last, Strings.chicksCounted(3));
      await shot('${no()}_farm_chicks');
      await app.tapLabel(Strings.back);

      // Every place at 小小農夫, then at 小農夫 (with a few misses).
      for (final level in Level.values) {
        app.change((g) => g.withSettings(g.settings.copyWith(level: level)));
        await app.settle();
        for (final place in Place.values) {
          await tester.tap(find.byKey(ValueKey('place-${place.name}')));
          await app.settle(900);
          expect(app.location, '/${place.name}');
          final seen = <String>{};
          var tasks = 0;
          while (find.byKey(const ValueKey('playing')).evaluate().isNotEmpty) {
            final first = seen.add(player.kind!);
            await player.play(
              mistakes: level == Level.big && tasks == 0,
              midway: first ? () => shot('${no()}_${level.name}_${place.name}_${player.kind}') : null,
            );
            tasks++;
            expect(tasks, lessThan(6), reason: 'a round is three or four tasks');
          }
          // 做完了 → the farm grows → the 回真實生活 card → again / next / home.
          await app.settle(2400);
          expect(find.byKey(const ValueKey('life-card')), findsOneWidget, reason: '$place');
          if (level == Level.small && place == Place.chicks) await shot('${no()}_life_card');
          await app.tapLabel(Strings.ok, ms: 700);
          if (level == Level.small && place == Place.chicks) await shot('${no()}_round_done');
          await app.tapLabel(Strings.home, ms: 900);
          expect(app.location, '/');
        }
        await shot('${no()}_farm_${level.name}_grown');
      }
      expect(app.game.farm.chicks, 3 + 4, reason: '餵小雞 and 撿雞蛋 twice each');
      expect(app.game.farm.veg, 2);
      expect(app.game.diary.length, 12);
      expect(app.game.counted.isNotEmpty, isTrue);
      expect(app.game.shares, 6, reason: "three 分點心 tasks a round");

      // Parent mode: the progress and the farm diary.
      ParentPass.grant();
      app.go('/parent');
      await app.settle(800);
      await shot('${no()}_parent');
      await tester.scrollUntilVisible(find.byKey(const ValueKey('diary')), 300, scrollable: find.byType(Scrollable).first);
      await app.settle(300);
      await shot('${no()}_parent_diary');
      await tester.tap(find.byKey(const ValueKey('diary-11')));
      await app.settle();
      expect(app.game.diary.last.done, isTrue);
      app.go('/');
      await app.settle(2600);

      // The play time runs out: dusk on the farm.
      app.now = app.now.add(const Duration(minutes: 16));
      await app.settle(2600);
      expect(app.location, '/rest');
      expect(app.voice.said.last, Strings.restSay);
      await shot('${no()}_rest');
      expect(app.game.log(app.now).seconds, greaterThan(0));

      // Never a digit for the voice (numbers are said as 一、兩、三).
      expect(app.voice.said.where(Say.hasDigit), isEmpty);
      await app.end();
    }, timeout: const Timeout(Duration(minutes: 20)));
  }
}
