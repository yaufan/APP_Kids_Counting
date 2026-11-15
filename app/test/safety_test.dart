import 'dart:io';

import 'package:counting_farm/app/strings.dart';
import 'package:counting_farm/core/content.dart';
import 'package:counting_farm/core/game.dart';
import 'package:counting_farm/features/parent/parent_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Privacy, the parent gate and the free version (docs/design.md: no
/// network, nothing leaves the phone, parent mode only through the gate).
void main() {
  test('the app asks for no permissions and takes no links from other apps', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, isNot(contains('uses-permission')), reason: 'no internet, camera, microphone, location…');
    expect(manifest, contains('android:name="flutter_deeplinking_enabled" android:value="false"'));
    expect(manifest, contains('android:label="數數小農場"'));
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>FlutterDeepLinkingEnabled</key>\n\t<false/>'));
    expect(plist, contains('<string>數數小農場</string>'));
    expect(plist, isNot(contains('UsageDescription')), reason: 'no camera, microphone… prompts');
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('source: system')));
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "com.yaufan.countingfarm"'));
    expect(gradle, contains('System.getenv("COUNTING_FARM_KEYSTORE")'));
    expect(gradle, contains('System.getenv("COUNTING_FARM_KEYSTORE_PASSWORD")'));
    expect(gradle, contains('keyAlias = "kidspaint"'));
    expect(File('android/app/src/main/kotlin/com/yaufan/counting_farm/MainActivity.kt').readAsStringSync(), contains('package com.yaufan.counting_farm'));
  });

  testWidgets('parent mode and unknown pages cannot be opened without the gate', (tester) async {
    final app = await TestApp.start(tester);
    app.go('/parent');
    await app.settle();
    expect(app.location, '/', reason: 'no pass from the gate');
    ParentPass.grant();
    app.go('/parent');
    await app.settle();
    expect(app.location, '/parent', reason: 'right after the gate');
    app.go('/');
    await app.settle();
    app.go('/parent');
    await app.settle();
    expect(app.location, '/', reason: 'the pass is used up');
    app.go('/nowhere');
    await app.settle();
    expect(find.text(Strings.chickSign(3)), findsOneWidget, reason: 'an unknown page is the farm');
    await app.end();
  });

  testWidgets('the parent gate asks a sum written in characters and locks after three misses', (tester) async {
    final app = await TestApp.start(tester);
    await app.tapLabel(Strings.parent, ms: 600);
    await app.settle(800);
    expect(find.textContaining('加'), findsOneWidget);
    expect(find.byKey(const ValueKey('gate-key-1')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('gate-key-1')));
      await app.settle(100);
      await tester.tap(find.byKey(const ValueKey('gate-key-0')));
      await app.settle(100);
    }
    expect(find.textContaining('請等'), findsOneWidget);
    expect(app.location, '/');
    await app.end();
  });

  testWidgets('the free version: 分點心, 排排隊 and 去市場 stay closed', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(full: false)));
    for (final p in [Place.share, Place.garden, Place.market]) {
      app.go('/${p.name}');
      await app.settle();
      expect(app.location, '/', reason: '$p is in the full version');
    }
    await tester.tap(find.byKey(const ValueKey('place-market')));
    await app.settle();
    expect(app.location, '/');
    expect(app.voice.said.last, Strings.lockedPlace);
    await tester.tap(find.byKey(const ValueKey('place-eggs')));
    await app.settle(700);
    expect(app.location, '/eggs');
    await app.end();
  });

  testWidgets('a place a parent turned off is not on the farm and cannot be opened', (tester) async {
    final app = await TestApp.start(tester, game: const Game(settings: Settings(places: {Place.chicks, Place.fruit})));
    expect(find.byKey(const ValueKey('place-eggs')), findsNothing);
    expect(find.byKey(const ValueKey('place-fruit')), findsOneWidget);
    app.go('/eggs');
    await app.settle();
    expect(app.location, '/');
    await app.end();
  });

  testWidgets('the rest ends after an hour, and a clock moved back does not lock the app', (tester) async {
    final app = await TestApp.start(tester);
    app.change((g) => g.rest(app.now));
    await app.settle(2600);
    expect(app.location, '/rest');
    app.now = app.now.subtract(const Duration(hours: 3));
    await app.settle(2600);
    expect(app.location, '/', reason: 'the clock went back: counts as rested');
    expect(app.game.restSince, isNull);
    await app.end();
  });

  testWidgets('only through the gate does the rest end early', (tester) async {
    final app = await TestApp.start(tester);
    app.change((g) => g.rest(app.now));
    await app.settle(2600);
    expect(app.location, '/rest');
    app.go('/');
    await app.settle(2600);
    expect(app.location, '/rest', reason: 'still resting');
    await app.end();
  });
}
