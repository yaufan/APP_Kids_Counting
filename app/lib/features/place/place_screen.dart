import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/game.dart';
import '../../core/providers.dart';
import '../../core/rounds.dart';
import '../../core/sounds.dart';
import '../chicks/chick_views.dart';
import '../eggs/fill_view.dart';
import '../fruit/compare_view.dart';
import '../garden/garden_views.dart';
import '../market/change_view.dart';
import '../share/share_view.dart';
import 'task_host.dart';

enum _Phase { playing, cheer, card, end }

/// One place on the farm (docs/design.md 「畫面和玩法」): a round of its
/// tasks one after the other, then 「做完了！」 and the farm grows, then the
/// 回真實生活 card (if a parent left the cards on), then again / the next
/// place / home.
class PlaceScreen extends ConsumerStatefulWidget {
  const PlaceScreen({super.key, required this.place});

  final Place place;

  @override
  ConsumerState<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends ConsumerState<PlaceScreen> with HushOnLeave implements TaskHost {
  late List<Task> _tasks;
  int _i = 0, _round = 0, _party = 0;
  var _phase = _Phase.playing;
  String _line = '';
  LifeCard? _card;
  String _cardDay = '';
  Later? _next;
  late final RoundBusy _busy = ref.read(roundBusyProvider);

  Place get _place => widget.place;

  @override
  void initState() {
    super.initState();
    _tasks = roundFor(_place, ask, random);
    _busy.start(this);
  }

  @override
  void dispose() {
    _next?.cancel();
    _busy.end(this);
    super.dispose();
  }

  // ---- TaskHost

  @override
  Settings get settings => ref.read(gameProvider).settings;

  @override
  Ask get ask => settings.ask;

  @override
  math.Random get random => ref.read(randomProvider);

  @override
  bool explain(String kind) {
    if (settings.level == Level.small) return true;
    return ref.read(onceProvider).add('howto-$kind');
  }

  @override
  Future<void> say(String line) {
    if (mounted) setState(() => _line = line);
    return speak(ref, line);
  }

  @override
  void sfx(String name) => ref.read(soundsProvider).play(name);

  @override
  void record(Game Function(Game g) f) => ref.read(gameProvider.notifier).change(f);

  @override
  void done(Future<void> said) {
    _next?.cancel();
    _next = Later(const Duration(milliseconds: 1300), _advance, after: said);
  }

  // ---- the round

  void _advance() {
    if (!mounted) return;
    if (_i + 1 < _tasks.length) {
      sfx('whoosh');
      setState(() => _i++);
      return;
    }
    _finish();
  }

  void _finish() {
    record((g) => g.finished(_place, ref.read(clockProvider)()));
    _busy.end(this);
    sfx('done');
    setState(() {
      _phase = _Phase.cheer;
      _party++;
    });
    final said = say(Strings.roundDone(_place));
    _next = Later(const Duration(milliseconds: 1800), _afterCheer, after: said);
  }

  void _afterCheer() {
    if (!mounted) return;
    if (!settings.cards) {
      setState(() => _phase = _Phase.end);
      return;
    }
    final card = ref.read(gameProvider).cardFor(_place);
    record((g) => g.cardShown(_place));
    sfx('card');
    setState(() {
      _card = card;
      _cardDay = Days.key(ref.read(clockProvider)());
      _phase = _Phase.card;
    });
    say(card.text);
  }

  void _cardAnswer(bool keep) {
    final card = _card;
    if (keep && card != null) record((g) => g.keep(card, _cardDay));
    setState(() => _phase = _Phase.end);
    if (keep) say('${Strings.ok}記得去做做看喔！');
  }

  void _again() {
    _next?.cancel();
    setState(() {
      _tasks = roundFor(_place, ask, random);
      _i = 0;
      _round++;
      _phase = _Phase.playing;
    });
    _busy.start(this);
  }

  Place? get _nextPlace {
    final s = settings;
    for (var k = 1; k < Place.values.length; k++) {
      final p = Place.values[(_place.index + k) % Place.values.length];
      if (s.enabled(p)) return p;
    }
    return null;
  }

  Widget _view(Task t) => switch (t) {
        FeedTask() => FeedView(task: t, host: this),
        PeekTask() => PeekView(task: t, host: this),
        FillTask() => FillView(task: t, host: this),
        HowManyTask() => HowManyView(task: t, host: this),
        CompareTask() => CompareView(task: t, host: this),
        ShareTask() => ShareView(task: t, host: this),
        PatternTask() => PatternView(task: t, host: this),
        DucksTask() => DucksView(task: t, host: this),
        PumpkinTask() => PumpkinView(task: t, host: this),
        ChangeTask() => ChangeView(task: t, host: this),
      };

  @override
  Widget build(BuildContext context) {
    final next = _nextPlace;
    return WithMusic(
      music: Music.of(_place),
      child: Scaffold(
        body: PaperBg(
          child: SafeArea(
            child: Stack(children: [
              // On a tablet the page is laid out like a big phone and scaled up,
              // so the things to count stay big and in the same places.
              LayoutBuilder(builder: (context, box) {
                // At least 460 wide and 760 high, as on a phone.
                final scale = box.maxWidth > 560 ? math.max(1.0, math.min(box.maxWidth / 460, box.maxHeight / 760)) : 1.0;
                return SizedBox(
                  width: box.maxWidth,
                  height: box.maxHeight,
                  child: FittedBox(
                    child: SizedBox(
                      width: box.maxWidth / scale,
                      height: box.maxHeight / scale,
                      child: Column(children: [
                    TopBar(title: _place.zh, onHome: () => context.go('/'), onSpeak: _line.isEmpty ? null : () => say(_line)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                      child: Align(alignment: Alignment.centerLeft, child: GrandmaSays(text: _line.isEmpty ? ' ' : _line, size: 54, happy: _phase != _Phase.playing, onTap: () => say(_line))),
                    ),
                    Expanded(child: KeyedSubtree(key: ValueKey('task-$_round-$_i'), child: _view(_tasks[_i]))),
                    // A marker for the tests: the round is still being played.
                    if (_phase == _Phase.playing) const SizedBox(key: ValueKey('playing')),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 2),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (var k = 0; k < _tasks.length; k++)
                          Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: k < _i || _phase != _Phase.playing ? Inks.green : (k == _i ? Inks.yellow : Inks.cream),
                              border: Border.all(color: Inks.edge(Inks.wood), width: 1.6),
                            ),
                          ),
                      ]),
                    ),
                  ]),
                    ),
                  ),
                );
              }),
              Positioned.fill(child: Confetti(trigger: _party)),
              if (_phase == _Phase.card && _card != null) Positioned.fill(child: _cardPanel(_card!)),
              if (_phase == _Phase.end)
                Positioned.fill(
                  child: Panel(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Bob(child: Grandma(size: 96, happy: true)),
                      const SizedBox(height: 6),
                      Text(Strings.roundDone(_place), textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 1.4)),
                      const SizedBox(height: 14),
                      PillButton(label: Strings.playAgain, color: Inks.orange, icon: Icons.replay_rounded, expand: true, onTap: _again),
                      if (next != null) ...[
                        const SizedBox(height: 10),
                        PillButton(label: Strings.goTo(next), color: Inks.blue, icon: Icons.arrow_forward_rounded, expand: true, onTap: () => context.go('/${next.name}')),
                      ],
                      const SizedBox(height: 10),
                      PillButton(label: Strings.home, color: Inks.red, icon: Icons.home_rounded, expand: true, onTap: () => context.go('/')),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _cardPanel(LifeCard card) => Panel(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: inkBox(Inks.green, radius: 16, shadow: false, edge: 2),
              child: const Text(Strings.lifeTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Inks.cream)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(width: 120, height: 120, child: Art(card.picture)),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: card.text,
            excludeSemantics: true,
            child: Text(card.text, key: const ValueKey('life-card'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, height: 1.45, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: PillButton(label: Strings.later, color: Inks.cream, onTap: () => _cardAnswer(false))),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: PillButton(label: Strings.ok, color: Inks.orange, icon: Icons.thumb_up_alt_rounded, onTap: () => _cardAnswer(true))),
          ]),
        ]),
      );
}
