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

  /// Moves the start of the sitting by [d] (never later than now): later by
  /// the time that was not the child's (parent mode, the background),
  /// earlier by as much as the phone's clock was moved back, so that gives
  /// no extra time.
  void shift(Duration d) {
    final now = ref.read(clockProvider)(), moved = state.add(d);
    state = moved.isAfter(now) ? now : moved;
  }
}

/// Whether a round is being played (the rest waits for it, at most a
/// minute: docs/design.md 「正在做的那一輪會先做完」). The screen playing it
/// holds it, so the place left behind (still going away while the next
/// place starts its round) cannot let go of the next place's round.
final roundBusyProvider = Provider<RoundBusy>((ref) => RoundBusy());

class RoundBusy {
  Object? _owner;

  bool get busy => _owner != null;

  /// [owner] is playing a round.
  void start(Object owner) => _owner = owner;

  /// [owner]'s round is over (or it went away); another screen's round goes on.
  void end(Object owner) {
    if (identical(_owner, owner)) _owner = null;
  }
}

/// Things said only once per app start (the welcome, 小農夫's first how-to).
final onceProvider = Provider<Set<String>>((ref) => <String>{});
