import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/rounds.dart';
import '../../core/sounds.dart';
import '../../core/speech.dart';
import '../place/task_host.dart';

/// 餵小雞 (docs/design.md): one corn for each chick. Tap a chick and a corn
/// hops to it; a chick that has eaten shakes its head. With one corn short
/// (夠不夠？, 小農夫) the last chick waits until a corn is pulled from the field.
class FeedView extends StatefulWidget {
  const FeedView({super.key, required this.task, required this.host});

  final FeedTask task;
  final TaskHost host;

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final _fed = <int>[];
  final _shake = <int, int>{};
  bool _pulled = false, _waiting = false, _over = false;

  FeedTask get _t => widget.task;
  TaskHost get _h => widget.host;
  int get _corn => _t.corn + (_pulled ? 1 : 0) - _fed.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _h.say(_t.short ? Strings.shortHowTo : (_h.explain('feed') ? Strings.feedHowTo : Strings.feedShort));
    });
  }

  void _feed(int i) {
    if (_over) return;
    if (_fed.contains(i)) {
      setState(() => _shake[i] = (_shake[i] ?? 0) + 1);
      _h.sfx('cheep_q');
      _h.say(Strings.fedAlready);
      return;
    }
    if (_corn <= 0) {
      setState(() => _shake[i] = (_shake[i] ?? 0) + 1);
      _h.sfx('cheep_q');
      _h.say(Strings.notEnough);
      return;
    }
    setState(() => _fed.add(i));
    final k = _fed.length;
    _h.sfx('pop');
    _h.sfx(countNote(k));
    _h.sfx('cheep');
    if (k == _t.chicks) {
      _over = true;
      _h.sfx('count_all');
      _h.record((g) => g.count(k));
      _h.done(_h.say(_pulled ? Strings.sameNow(k) : Strings.fedAll(k)));
      return;
    }
    if (_corn == 0) {
      setState(() => _waiting = true);
      _h.say('${Say.count(k)}！${Strings.notEnough}');
      return;
    }
    _h.say(Say.count(k));
  }

  void _pull() {
    if (!_waiting) return;
    _h.sfx('rustle');
    setState(() {
      _pulled = true;
      _waiting = false;
    });
    _h.say(Strings.pulled);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final n = _t.chicks;
        final per = n > 5 ? 5 : n;
        final rows = (n + 4) ~/ 5;
        final size = math.min(box.maxWidth / (per + .6), (box.maxHeight - 190) / (rows * 1.35));
        Widget chick(int i) {
          final fed = _fed.contains(i);
          return Semantics(
            key: ValueKey('chick-$i'),
            container: true,
            button: true,
            label: '小雞',
            excludeSemantics: true,
            onTap: () => _feed(i),
            child: Pressable(
              onTap: () => _feed(i),
              sound: null,
              child: SizedBox(
                width: size,
                height: size * 1.3,
                child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                  Positioned(
                    bottom: 0,
                    child: Wiggle(
                      trigger: _shake[i] ?? 0,
                      child: Hop(trigger: fed ? 1 : 0, child: ThingPic(fed ? 'animals/chick_happy' : 'animals/chick', size: size)),
                    ),
                  ),
                  if (fed) Positioned(bottom: -size * .04, right: size * .02, child: PopIn(child: ThingPic('food/corn', size: size * .32))),
                  if (fed && _h.ask.numerals)
                    Positioned(
                      top: 0,
                      child: PopIn(
                        child: Container(
                          width: size * .38,
                          height: size * .38,
                          alignment: Alignment.center,
                          decoration: inkBox(Inks.orange, radius: size * .08, edge: 1.6, shadow: false),
                          child: Text('${_fed.indexOf(i) + 1}', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: size * .24, fontWeight: FontWeight.w700, color: Inks.cream, height: 1)),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          );
        }

        return Column(children: [
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var r = 0; r < rows; r++)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = r * 5; i < math.min(n, r * 5 + 5); i++) chick(i)]),
            ]),
          ),
          SizedBox(
            height: 92,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(width: 80, height: 80, child: Art('farm/bucket')),
              const SizedBox(width: 8),
              if (_waiting)
                Glow(on: true, round: false, child: PillButton(key: const ValueKey('pull'), label: Strings.pullCorn, color: Inks.green, icon: Icons.grass_rounded, onTap: _pull, sound: null))
              else
                Flexible(
                  child: Wrap(spacing: 2, runSpacing: 2, children: [
                    for (var k = 0; k < math.max(0, _corn); k++) const SizedBox(width: 24, height: 24, child: Art('food/corn')),
                  ]),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: CountTiles(n: n, lit: _fed.length, numerals: _h.ask.numerals, width: math.min(box.maxWidth - 24, 360)),
          ),
        ]);
      });
}

/// 小雞躲貓貓 (一眼看出): a few chicks peek out of the hay like the dots of a
/// die, and hide again; which card was it? Whichever card: they all come
/// out and are counted together (it is never wrong; the parent sees how it
/// went).
class PeekView extends StatefulWidget {
  const PeekView({super.key, required this.task, required this.host});

  final PeekTask task;
  final TaskHost host;

  /// How long the chicks show.
  static const showFor = Duration(milliseconds: 2000);

  @override
  State<PeekView> createState() => _PeekViewState();
}

class _PeekViewState extends State<PeekView> with CountAlong {
  var _shown = false, _out = false, _asked = false;
  int _lit = 0;
  int? _picked;
  Later? _later;

  PeekTask get _t => widget.task;
  TaskHost get _h => widget.host;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final said = _h.say(Strings.peekHowTo);
      _later = Later(const Duration(milliseconds: 700), _peek, after: said, atMost: const Duration(seconds: 6));
    });
  }

  @override
  void dispose() {
    _later?.cancel();
    super.dispose();
  }

  void _peek() {
    if (!mounted) return;
    _h.sfx('peek');
    setState(() => _shown = true);
    _later = Later(PeekView.showFor, () {
      if (!mounted || _out) return;
      _h.sfx('hide');
      setState(() {
        _shown = false;
        _asked = true;
      });
      _h.say(Strings.peekAsk);
    });
  }

  void _pick(int k) {
    if (_picked != null) return;
    _later?.cancel();
    final right = k == _t.n;
    _h.record((g) => g.glance(_t.n, right));
    setState(() {
      _picked = k;
      _out = true;
      _shown = true;
    });
    _h.sfx('peek');
    final said = _h.say(Strings.peekCount);
    _later = Later(const Duration(milliseconds: 500), () {
      countAlong(_h, _t.n, (k) => setState(() => _lit = k), () {
        _h.sfx('count_all');
        _h.record((g) => g.count(_t.n));
        _h.done(_h.say('${Strings.peekAll(_t.n)}${right ? Strings.peekRight : ''}'));
      });
    }, after: said, atMost: const Duration(seconds: 4));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final hayW = math.min(box.maxWidth - 24, 380.0);
        final hayH = hayW * 110 / 220;
        final area = Size(hayW * .7, hayH * .9);
        final chick = math.min(area.width, area.height) * .32;
        final cards = math.min(108.0, (box.maxWidth - 60) / 3);
        return Column(children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: hayW,
                height: hayH + area.height * .2,
                child: Stack(clipBehavior: Clip.none, children: [
                  // The chicks, laid out like a die, behind the front of the hay.
                  for (final (i, (x, y)) in dotLayout(_t.n).indexed)
                    AnimatedPositioned(
                      key: ValueKey('peek-$i'),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      left: (hayW - area.width) / 2 + x * area.width - chick / 2,
                      top: _shown ? y * area.height - chick * .6 + (_out ? hayH * .25 : 0) : hayH * .55,
                      width: chick,
                      height: chick,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _shown ? 1 : 0,
                        child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
                          Hop(trigger: i < _lit ? 1 : 0, child: ThingPic(i < _lit ? 'animals/chick_happy' : 'animals/chick', size: chick)),
                          if (i < _lit && _h.ask.numerals)
                            Positioned(top: -chick * .3, child: Text('${i + 1}', style: TextStyle(fontSize: chick * .32, fontWeight: FontWeight.w700, color: Inks.red))),
                        ]),
                      ),
                    ),
                  Positioned(left: 0, right: 0, bottom: 0, height: _out ? hayH * .5 : hayH, child: const Art('farm/haystack', fit: BoxFit.fill)),
                ]),
              ),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _asked || _out ? 1 : .35,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final k in _t.choices)
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: ChoiceCard(n: k, numerals: false, size: cards, ring: _picked == k ? Inks.yellow : null, onTap: _asked && _picked == null ? () => _pick(k) : null),
                  ),
              ]),
            ),
          ),
          if (_out) CountTiles(n: _t.n, lit: _lit, numerals: _h.ask.numerals, width: math.min(box.maxWidth - 24, 360)) else const SizedBox(height: 4),
        ]);
      });
}
