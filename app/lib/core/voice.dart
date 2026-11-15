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
  FlutterTts? _tts;
  double? _rate;

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = _tts = FlutterTts();
    await tts.awaitSpeakCompletion(true);
    await tts.setLanguage('zh-TW');
    await tts.setPitch(1.15);
    return tts;
  }

  @override
  Future<void> say(String zh, {bool slow = false}) async {
    try {
      final tts = await _engine();
      await tts.stop();
      final rate = slow ? 0.32 : 0.45;
      if (rate != _rate) {
        _rate = rate;
        await tts.setSpeechRate(rate);
      }
      if (zh.isNotEmpty) await tts.speak(zh);
    } catch (_) {
      // No speech engine (tests, or a phone without one): the pictures and
      // the words on screen are enough.
    }
  }

  @override
  Future<void> stop() async {
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
