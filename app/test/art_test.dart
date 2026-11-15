import 'dart:io';

import 'package:counting_farm/app/farm_layout.dart';
import 'package:counting_farm/core/content.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every picture and sound the program asks for exists (docs/art.md), and
/// no picture uses what flutter_svg cannot draw.
void main() {
  bool has(String path) => File('assets/art/$path.svg').existsSync();
  final code = [for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) if (f.path.endsWith('.dart')) f.readAsStringSync()].join('\n');

  test('every picture the screens ask for is drawn', () {
    final wanted = <String>{
      for (final m in RegExp(r"""Art\(\s*'([a-z_/0-9]+)'""").allMatches(code)) m.group(1)!,
      for (final m in RegExp(r"""'((?:animals|food|farm|ui)/[a-z_0-9]+)'""").allMatches(code)) m.group(1)!,
      for (final t in [Things.egg, Things.corn, Things.chick, Things.melon, Things.pumpkin, ...Things.fruit, ...Things.snacks, ...Things.veg]) t.picture,
      for (final a in Animal.values) a.picture,
      for (final c in lifeCards) c.picture,
    };
    expect(wanted.length, greaterThan(50));
    expect([for (final p in wanted) if (!has(p)) p], isEmpty, reason: 'draw these in design/art/');
  });

  test('the six places and what grows sit inside the farm picture', () {
    expect(farmSpots.keys.toSet(), {for (final p in Place.values) p.name});
    for (final (x, y) in [...farmSpots.values, ...hatchSpots, ...treeFruitSpots, ...sproutSpots, ...melonSpots]) {
      expect(x, inInclusiveRange(.03, .97));
      expect(y, inInclusiveRange(.03, .97));
    }
    expect(hatchSpots.length, 10);
  });

  test('no picture uses what flutter_svg cannot draw, and none is too big', () {
    final bad = <String>[];
    var n = 0;
    for (final f in Directory('assets/art').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.svg')) continue;
      n++;
      final text = f.readAsStringSync();
      if (f.lengthSync() > 80 * 1024) bad.add('${f.path} too big');
      for (final no in ['<filter', '<mask', '<clipPath', 'clip-path', '<style', 'style=', '<text', '<image', '<pattern', 'mix-blend']) {
        if (text.contains(no)) bad.add('${f.path} uses $no');
      }
      if (!text.trimRight().endsWith('</svg>')) bad.add('${f.path} is cut off');
    }
    expect(n, greaterThan(70));
    expect(bad, isEmpty);
  });

  test('every sound the app plays is there', () {
    final names = <String>{
      for (final m in RegExp(r"""(?:sfx\((?:ref, )?|_h\.sfx\(|host\.sfx\(|\.play\()'([a-z_0-9]+)'""").allMatches(code)) m.group(1)!,
      for (final a in Animal.values) a.sound,
      'tap', // every button's own sound (Pressable)
      'knock', 'thud', 'plonk', // an egg, a fruit, a melon put in (FillView)
      for (var n = 1; n <= 10; n++) 'count_$n',
      'count_all',
      for (final m in ['farm', 'coop', 'orchard', 'garden', 'market', 'rest']) 'music_$m',
    };
    expect(names.length, greaterThan(35));
    expect([for (final s in names) if (!File('assets/sounds/$s.wav').existsSync()) s], isEmpty);
    // And no sound file nobody plays.
    final files = {for (final f in Directory('assets/sounds').listSync()) f.uri.pathSegments.last.replaceAll('.wav', '')};
    expect(files.difference(names), isEmpty, reason: 'made but never played');
  });

  test('the font is there, with its licence', () {
    expect(File('assets/fonts/jf-openhuninn-2.1.ttf').existsSync(), isTrue);
    expect(File('assets/fonts/OFL-jf-openhuninn.txt').existsSync(), isTrue);
  });
}
