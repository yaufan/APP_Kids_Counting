import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game.dart';
import 'sounds.dart';
import 'store.dart';
import 'voice.dart';

/// What time it is (tests and screenshots set it): the play-time limit, the
/// rest's card and parent mode's minutes use it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Dice (tests give a seeded one).
final randomProvider = Provider<math.Random>((ref) => math.Random());

final storeProvider = Provider<GameStore>((ref) => MemoryStore());
final savedGameProvider = Provider<Game>((ref) => const Game());
final soundsProvider = Provider<Sounds>((ref) => const SilentSounds());
final voiceProvider = Provider<Voice>((ref) => const SilentVoice());

/// The game; every change is saved straight away.
final gameProvider = NotifierProvider<GameNotifier, Game>(GameNotifier.new);

class GameNotifier extends Notifier<Game> {
  @override
  Game build() => ref.read(savedGameProvider);

  void change(Game Function(Game g) f) {
    final next = f(state);
    if (identical(next, state)) return;
    state = next;
    ref.read(storeProvider).write(next.toJson());
  }

  void settings(Settings Function(Settings s) f) => change((g) => g.withSettings(f(g.settings)));
}

/// When this sitting started (reset when a parent lets play go on).
final sessionStartProvider = NotifierProvider<SessionStart, DateTime>(SessionStart.new);

class SessionStart extends Notifier<DateTime> {
  @override
  DateTime build() => ref.read(clockProvider)();

  void restart() => state = ref.read(clockProvider)();

  /// Time [d] a parent spent in parent mode is not the child's: the sitting
  /// starts that much later (never later than now).
  void pause(Duration d) {
    if (d.isNegative) return;
    final now = ref.read(clockProvider)(), later = state.add(d);
    state = later.isAfter(now) ? now : later;
  }
}

/// Whether a round is being played (the rest waits for it, at most a
/// minute: docs/design.md 「正在做的那一輪會先做完」). A plain flag, so a
/// screen can set it as it comes and goes.
final roundBusyProvider = Provider<RoundBusy>((ref) => RoundBusy());

class RoundBusy {
  bool busy = false;
}

/// Things said only once per app start (the welcome, 小農夫's first how-to).
final onceProvider = Provider<Set<String>>((ref) => <String>{});
