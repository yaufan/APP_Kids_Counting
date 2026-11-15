import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/rounds.dart';
import '../../core/sounds.dart';
import '../../core/speech.dart';
import '../place/task_host.dart';

/// 阿嬤's help when the same thing is missed (docs/design.md 「做錯的時候」):
/// after two misses the right one glows, after three she does it. A parent
/// can turn the help off.
mixin Hints<T extends StatefulWidget> on State<T> {
  int misses = 0;

  TaskHost get hintHost;

  bool get glowHint => hintHost.settings.hints && misses >= 2;

  bool get doIt => hintHost.settings.hints && misses >= 3;
}

/// 菜園的規律: the row is planted by a rule; which seed box goes in the empty
/// spot? A wrong one grows crooked and hops back, and 阿嬤 chants the row.
class PatternView extends StatefulWidget {
  const PatternView({super.key, required this.task, required this.host});

  final PatternTask task;
  final TaskHost host;

  @override
  State<PatternView> createState() => _PatternViewState();
}

class _PatternViewState extends State<PatternView> with Hints {
  Thing? _crooked;
  var _planted = false;
  final _shake = <String, int>{};
  Later? _later;

  PatternTask get _t => widget.task;

  @override
  TaskHost get hintHost => widget.host;
  TaskHost get _h => widget.host;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _h.say(Strings.patternAsk(_t.row));
    });
  }

  @override
  void dispose() {
    _later?.cancel();
    super.dispose();
  }

  void _plant(Thing seed) {
    if (_planted || _crooked != null) return;
    if (seed == _t.answer) {
      _grow(Strings.patternRight([..._t.row, _t.answer]));
      return;
    }
    misses++;
    _h.sfx('boing');
    setState(() {
      _crooked = seed;
      _shake[seed.id] = (_shake[seed.id] ?? 0) + 1;
    });
    final said = _h.say(Strings.patternAgain(_t.row));
    _later = Later(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _crooked = null);
      if (doIt) _grow(Strings.patternHelp(_t.answer));
    }, after: said);
  }

  void _grow(String line) {
    _h.sfx('rustle');
    _h.sfx('count_all');
    if (misses == 0) _h.record((g) => g.planted(_t.kind));
    setState(() => _planted = true);
    _h.done(_h.say(line));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = math.min(box.maxWidth - 16, 560.0);
        final cells = _t.row.length + 1;
        final cell = math.min(w / cells, 76.0);
        final crate = math.min(110.0, (box.maxWidth - 50) / 3);
        Widget plantAt(int i) {
          if (i < _t.row.length) return ThingPic(_t.row[i].picture, size: cell * .9);
          if (_planted) return PopIn(child: ThingPic(_t.answer.picture, size: cell * .9));
          if (_crooked != null) return ThingPic(_crooked!.picture, size: cell * .9, angle: .7);
          return Container(
            key: const ValueKey('gap'),
            width: cell * .8,
            height: cell * .8,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Inks.cream.withValues(alpha: .6), border: Border.all(color: Inks.brown, width: 2.5)),
            child: Text('?', style: TextStyle(fontSize: cell * .45, fontWeight: FontWeight.w700, color: Inks.brown)),
          );
        }

        return Column(children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: cell * cells + 16,
                height: cell * 1.5,
                child: Stack(alignment: Alignment.bottomCenter, children: [
                  Positioned(left: 0, right: 0, bottom: 0, height: cell * .7, child: const Art('farm/bed', fit: BoxFit.fill)),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: cell * .2,
                    child: Row(children: [for (var i = 0; i < cells; i++) SizedBox(width: cell, child: Center(child: plantAt(i)))]),
                  ),
                ]),
              ),
            ),
          ),
          Text(Strings.chant([..._t.row, ...(_planted ? [_t.answer] : [])]).replaceAll('、', ' ・ '),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Inks.inkSoft)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final seed in _t.options)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Semantics(
                  key: ValueKey('seed-${seed.id}'),
                  container: true,
                  button: true,
                  label: seed.zh,
                  excludeSemantics: true,
                  onTap: () => _plant(seed),
                  child: Pressable(
                    onTap: () => _plant(seed),
                    sound: null,
                    child: Wiggle(
                      trigger: _shake[seed.id] ?? 0,
                      child: Glow(
                        on: glowHint && seed == _t.answer && !_planted,
                        child: SizedBox(
                          width: crate,
                          height: crate,
                          child: Stack(alignment: Alignment.bottomCenter, children: [
                            Positioned(left: 0, right: 0, bottom: 0, height: crate * .8, child: const Art('farm/crate')),
                            Positioned(top: 0, child: ThingPic(seed.picture, size: crate * .62)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 10),
        ]);
      });
}

/// A duck with a number on its vest (dots at 小小農夫).
class Duck extends StatelessWidget {
  const Duck({super.key, required this.n, required this.size, required this.numerals});

  final int n;
  final double size;
  final bool numerals;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size * 1.1,
        child: Stack(children: [
          const Positioned.fill(child: Art('animals/duck')),
          Positioned(
            left: size * .38,
            top: size * 1.1 * .58,
            width: size * .24,
            height: size * .24,
            child: numerals
                ? FittedBox(child: Text('$n', textScaler: TextScaler.noScaling, style: const TextStyle(fontWeight: FontWeight.w700, color: Inks.ink, height: 1)))
                : DotFace(n: n, color: Inks.blue),
          ),
        ]),
      );
}

/// 鴨子過橋: the ducks wear numbers and stand all mixed up; tap 1, then 2…
/// and they cross the bridge in order. The wrong duck shakes its head.
class DucksView extends StatefulWidget {
  const DucksView({super.key, required this.task, required this.host});

  final DucksTask task;
  final TaskHost host;

  @override
  State<DucksView> createState() => _DucksViewState();
}

class _DucksViewState extends State<DucksView> with Hints {
  int _crossed = 0;
  final _shake = <int, int>{};
  var _over = false;
  Later? _later;

  DucksTask get _t => widget.task;

  @override
  TaskHost get hintHost => widget.host;
  TaskHost get _h => widget.host;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _h.sfx('quack');
      _h.say(Strings.ducksHowTo(_t.n));
    });
  }

  @override
  void dispose() {
    _later?.cancel();
    super.dispose();
  }

  void _tap(int d) {
    if (_over || d <= _crossed) return;
    final want = _crossed + 1;
    if (d != want) {
      misses++;
      setState(() => _shake[d] = (_shake[d] ?? 0) + 1);
      _h.sfx('quack');
      final said = _h.say(Strings.duckWrong(d, want));
      if (doIt) {
        // 阿嬤 sends the right duck over, unless the child already has.
        _later?.cancel();
        _later = Later(const Duration(milliseconds: 800), () {
          if (mounted && !_over && _crossed + 1 == want) _go(want);
        }, after: said);
      }
      return;
    }
    _go(d);
  }

  void _go(int d) {
    _later?.cancel();
    misses = 0;
    setState(() => _crossed = d);
    _h.sfx('whoosh');
    _h.sfx(countNote(d));
    if (d == _t.n) {
      _over = true;
      _h.sfx('quack');
      _h.sfx('count_all');
      _h.record((g) => g.count(_t.n));
      _h.done(_h.say(Strings.ducksDone(_t.n)));
      return;
    }
    _h.say(Strings.duckGo(d));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = math.min(box.maxWidth - 16, 560.0);
        final size = math.min(w / (_t.n + .8), box.maxHeight * .24);
        final numerals = _h.ask.numerals;
        return Column(children: [
          Expanded(
            child: Center(
              child: Wrap(alignment: WrapAlignment.center, spacing: size * .1, children: [
                for (final d in _t.standing)
                  Semantics(
                    key: ValueKey('duck-$d'),
                    container: true,
                    button: d > _crossed,
                    label: '$d 號鴨子',
                    excludeSemantics: true,
                    onTap: () => _tap(d),
                    child: Pressable(
                      onTap: d > _crossed ? () => _tap(d) : null,
                      sound: null,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: d > _crossed ? 1 : 0,
                        child: Wiggle(
                          trigger: _shake[d] ?? 0,
                          child: Glow(on: glowHint && d == _crossed + 1, child: Duck(n: d, size: size, numerals: numerals)),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          SizedBox(
            width: w,
            height: w * 120 / 390,
            child: Stack(clipBehavior: Clip.none, children: [
              const Positioned.fill(child: Art('farm/river', fit: BoxFit.fill)),
              for (var d = 1; d <= _crossed; d++)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  left: w * (66 + 256 * (d - .5) / _t.n) / 390 - size * .4,
                  top: -size * .45,
                  child: PopIn(child: Duck(n: d, size: size * .8, numerals: numerals)),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          CountTiles(n: _t.n, lit: _crossed, numerals: numerals, width: math.min(w, 360), color: Inks.blue),
          const SizedBox(height: 6),
        ]);
      });
}

/// 南瓜排排站 (小小農夫): three pumpkins, small to big, onto the shelf.
class PumpkinView extends StatefulWidget {
  const PumpkinView({super.key, required this.task, required this.host});

  final PumpkinTask task;
  final TaskHost host;

  static const scales = [.5, .72, 1.0];

  @override
  State<PumpkinView> createState() => _PumpkinViewState();
}

class _PumpkinViewState extends State<PumpkinView> with Hints {
  int _placed = 0;
  final _shake = <int, int>{};
  var _over = false;
  Later? _later;

  PumpkinTask get _t => widget.task;

  @override
  TaskHost get hintHost => widget.host;
  TaskHost get _h => widget.host;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _h.say(Strings.pumpkinHowTo);
    });
  }

  @override
  void dispose() {
    _later?.cancel();
    super.dispose();
  }

  void _tap(int s) {
    if (_over || s < _placed) return;
    if (s != _placed) {
      misses++;
      setState(() => _shake[s] = (_shake[s] ?? 0) + 1);
      _h.sfx('boing');
      final said = _h.say(Strings.pumpkinWrong);
      if (doIt) {
        // 阿嬤 puts the right one up, unless the child already has.
        final want = _placed;
        _later?.cancel();
        _later = Later(const Duration(milliseconds: 800), () {
          if (mounted && !_over && _placed == want) _put(want);
        }, after: said);
      }
      return;
    }
    _put(s);
  }

  void _put(int s) {
    _later?.cancel();
    misses = 0;
    setState(() => _placed = s + 1);
    _h.sfx('thud');
    _h.sfx(countNote(s + 1));
    if (_placed == 3) {
      _over = true;
      _h.sfx('count_all');
      _h.done(_h.say(Strings.pumpkinDone));
      return;
    }
    _h.say(Strings.pumpkinWords[s]);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = math.min(box.maxWidth - 16, 480.0);
        final big = math.min(w / 3.4, box.maxHeight * .3);
        return Column(children: [
          const SizedBox(height: 10),
          SizedBox(
            width: w,
            height: big + 30,
            child: Stack(alignment: Alignment.bottomCenter, children: [
              Positioned(left: 0, right: 0, bottom: 0, height: w * 40 / 300, child: const Art('farm/shelf', fit: BoxFit.fill)),
              Positioned(
                left: 0,
                right: 0,
                bottom: w * 40 / 300 * .55,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (var s = 0; s < 3; s++)
                    SizedBox(width: big, height: big, child: Align(alignment: Alignment.bottomCenter, child: s < _placed ? PopIn(child: ThingPic('food/pumpkin', size: big * PumpkinView.scales[s])) : null)),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
              for (final s in _t.standing)
                Semantics(
                  key: ValueKey('pumpkin-$s'),
                  container: true,
                  button: s >= _placed,
                  label: Strings.pumpkinWords[s],
                  excludeSemantics: true,
                  onTap: () => _tap(s),
                  child: Pressable(
                    onTap: s >= _placed ? () => _tap(s) : null,
                    sound: null,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: s >= _placed ? 1 : 0,
                      child: Wiggle(
                        trigger: _shake[s] ?? 0,
                        child: Glow(on: glowHint && s == _placed, child: ThingPic('food/pumpkin', size: big * PumpkinView.scales[s])),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          Text(Say.upTo(_placed).isEmpty ? ' ' : Strings.pumpkinWords.take(_placed).join('、'), style: const TextStyle(fontSize: 18, color: Inks.inkSoft)),
          const SizedBox(height: 10),
        ]);
      });
}
