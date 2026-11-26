import 'dart:io';

import 'package:counting_farm/app/strings.dart';
import 'package:counting_farm/core/content.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:counting_farm/core/game.dart';
import 'package:counting_farm/core/sounds.dart';
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

  test('the phone\'s speech engine can be found, and nothing is backed up or moved to another phone', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('<action android:name="android.intent.action.TTS_SERVICE" />'), reason: 'Android 11+ hides the speech engine otherwise');
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="false"'));
    expect(manifest, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml').readAsStringSync();
    for (final part in ['cloud-backup', 'device-transfer']) {
      final m = RegExp('<$part>(.*?)</$part>', dotAll: true).firstMatch(rules);
      expect(m, isNotNull, reason: part);
      for (final domain in ['root', 'file', 'database', 'sharedpref', 'external']) {
        expect(m![1], contains('<exclude domain="$domain" />'), reason: '$part leaves out $domain');
      }
    }
    for (final w in ['app.yml', 'release.yml']) {
      final flow = File('../.github/workflows/$w').readAsStringSync();
      for (final p in ['INTERNET', 'LOCATION', 'AD_ID', 'CAMERA', 'RECORD_AUDIO', 'READ_CONTACTS', 'READ_MEDIA_', 'READ_EXTERNAL_STORAGE']) {
        expect(flow, contains(p), reason: '$w stops an APK that asks for $p');
      }
    }
  });

  test('sounds play on the media stream (heard on vibrate), never taking the audio focus', () {
    expect(soundContext.android.usageType, AndroidUsageType.media);
    expect(soundContext.android.contentType, AndroidContentType.music);
    expect(soundContext.android.audioFocus, AndroidAudioFocus.none, reason: 'sounds never stop one another or the voice');
    expect(soundContext.iOS.category, AVAudioSessionCategory.ambient, reason: 'iPhone: mixes in, as before');
    final code = File('lib/core/sounds.dart').readAsStringSync();
    expect(code, isNot(contains('respectSilence: true')), reason: 'on Android that is the ringtone stream');
    expect(code, contains('audioContext: soundContext'), reason: 'every sound gets it');
    expect(code, contains('setAudioContext(soundContext)'));
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
    expect(find.text(Strings.chickSign(3, numerals: false)), findsOneWidget, reason: 'an unknown page is the farm');
    await app.end();
  });

  testWidgets('the parent gate asks a sum written in characters and locks after three misses', (tester) async {
    final app = await TestApp.start(tester);
    await app.tapLabel(Strings.parent, ms: 600);
    await app.settle(800);
    expect(find.textContaining('加'), findsOneWidget);
    expect(find.byKey(const ValueKey('gate-key-1')), findsOneWidget);
    // Only 0s: never a right answer (the sums are 6 to 18), so each one or
    // two keys are a miss. (1 then 0 was 10, right one time in ten.)
    for (var i = 0; i < 6 && find.textContaining('請等').evaluate().isEmpty; i++) {
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
