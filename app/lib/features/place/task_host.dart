import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/widgets.dart';
import '../../core/game.dart';
import '../../core/rounds.dart';
import '../../core/sounds.dart';
import '../../core/speech.dart';

/// What a task's view gets from the place screen around it: the settings,
/// the voice (through the screen, so leaving the screen hushes it), the
/// sounds, saving progress, and 「this task is done」.
abstract interface class TaskHost {
  Ask get ask;
  Settings get settings;
  math.Random get random;

  /// Whether to say the whole how-to: 小小農夫 every time, 小農夫 the first
  /// time per app start (docs/design.md 「阿嬤說明」).
  bool explain(String kind);

  /// 阿嬤 says [line] (it shows in her bubble too); completes when said.
  Future<void> say(String line);
  void sfx(String name);
  void record(Game Function(Game g) f);

  /// The task is done; the next one comes once [said] has been said.
  void done(Future<void> said);
}

/// Counting things together, one by one, out loud: each number is said and
/// its note played before the next (never faster than [step], and never
/// over a slow voice for long).
mixin CountAlong<T extends StatefulWidget> on State<T> {
  Later? _step;

  void countAlong(TaskHost host, int n, void Function(int k) mark, VoidCallback then, {int from = 1, Duration step = const Duration(milliseconds: 620)}) {
    void go(int k) {
      if (!mounted) return;
      if (k > n) {
        then();
        return;
      }
      mark(k);
      host.sfx(countNote(k));
      final said = host.say(Say.count(k));
      _step = Later(step, () => go(k + 1), after: said, atMost: const Duration(seconds: 2));
    }

    go(from);
  }

  void stopCounting() => _step?.cancel();

  @override
  void dispose() {
    _step?.cancel();
    super.dispose();
  }
}
