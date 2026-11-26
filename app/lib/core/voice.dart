import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads things out for children who cannot read yet, in Taiwanese Mandarin
/// (only Mandarin: docs/design.md, the user's 8a).
abstract interface class Voice {
  /// Says [zh] (numbers written in characters, core/speech.dart); [slow]
  /// for a slower voice. Completes when the line has been said.
  Future<void> say(String zh, {bool slow = false});
  Future<void> stop();
}

class SystemVoice implements Voice {
  /// Quiet while the app is out of sight: what was being said stops, and
  /// nothing new is said until it is back.
  SystemVoice() {
    _life = AppLifecycleListener(
      onHide: () {
        _hidden = true;
        stop();
      },
      onShow: () => _hidden = false,
    );
  }

  late final AppLifecycleListener _life;
  var _hidden = false;
  FlutterTts? _tts;
  Future<FlutterTts>? _setUp;
  double? _rate;

  /// Counts the lines asked for (and the stops): only the newest is said.
  var _turn = 0;

  /// The engine, set up once. Every line waits for the whole set-up, so a
  /// line asked for while the first one (the farm's hello) is still setting
  /// up is not said in the wrong language and then cut off by the first
  /// one's late stop(): the newer line is the one that is said.
  Future<FlutterTts> _engine() => _setUp ??= () async {
        final tts = _tts = FlutterTts();
        await tts.awaitSpeakCompletion(true);
        await tts.setLanguage('zh-TW');
        await tts.setPitch(1.15);
        return tts;
      }();

  @override
  Future<void> say(String zh, {bool slow = false}) async {
    final turn = ++_turn;
    if (_hidden) return;
    try {
      final tts = await _engine();
      if (turn != _turn) return;
      await tts.stop();
      final rate = slow ? 0.32 : 0.45;
      if (rate != _rate) {
        _rate = rate;
        await tts.setSpeechRate(rate);
      }
      // A newer line, or a screen that was left, while this one waited.
      if (turn != _turn || _hidden || zh.isEmpty) return;
      await tts.speak(zh);
    } catch (_) {
      // No speech engine (tests, or a phone without one): the pictures and
      // the words on screen are enough.
    }
  }

  void dispose() => _life.dispose();

  @override
  Future<void> stop() async {
    _turn++;
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

class SilentVoice implements Voice {
  const SilentVoice();

  @override
  Future<void> say(String zh, {bool slow = false}) async {}

  @override
  Future<void> stop() async {}
}

/// Remembers what was said, and how often it was stopped (tests).
class RecordingVoice implements Voice {
  final said = <String>[];
  var stops = 0;

  @override
  Future<void> say(String zh, {bool slow = false}) async => said.add(zh);

  @override
  Future<void> stop() async => stops++;
}
