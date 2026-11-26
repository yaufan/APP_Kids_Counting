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

/// The order at the top: the numeral (小農夫), the dots, the thing.
class OrderSign extends StatelessWidget {
  const OrderSign({super.key, required this.n, required this.thing, required this.numerals, this.stamped = false, this.height = 96});

  final int n;
  final Thing thing;
  final bool numerals;
  final bool stamped;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
        key: const ValueKey('order'),
        container: true,
        label: '$n',
        excludeSemantics: true,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: height * .14, vertical: height * .1),
            decoration: inkBox(Inks.cream, radius: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (numerals) ...[
                Text('$n', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: height * .62, fontWeight: FontWeight.w700, color: Inks.red, height: 1)),
                SizedBox(width: height * .1),
              ],
              SizedBox(width: height * (n > 6 ? 1.3 : .8), height: height * .8, child: DotFace(n: n)),
              SizedBox(width: height * .08),
              ThingPic(thing.picture, size: height * .5),
            ]),
          ),
          if (stamped)
            Positioned(
              right: -height * .2,
              top: -height * .15,
              child: PopIn(
                child: Transform.rotate(
                  angle: -.25,
                  child: SizedBox(
                    width: height * .8,
                    height: height * .8,
                    child: Stack(alignment: Alignment.center, children: [
                      const Positioned.fill(child: Art('ui/stamp')),
                      Text(Strings.done.substring(0, 2), textScaler: TextScaler.noScaling, style: TextStyle(fontSize: height * .22, fontWeight: FontWeight.w700, color: const Color(0xFFC23B32))),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      );
}

/// Where the things wait to be picked (the nests, the tree, the melon field):
/// [n] of them at spots inside a picture; [taken] ones are gone.
class _Supply extends StatelessWidget {
  const _Supply({required this.thing, required this.n, required this.taken, required this.onPick, required this.width, required this.height});

  final Thing thing;
  final int n;
  final Set<int> taken;
  final void Function(int i) onPick;
  final double width, height;

  /// The spots (fractions of the picture) and the picture, by thing.
  (String, double, List<(double, double)>) _where() {
    switch (thing.id) {
      case 'egg':
        // Three nests in a row, eggs in little heaps on them.
        // Never on top of each other: each egg is its own thing to tap.
        const heap = [(0.0, 0.0), (-.102, .0), (.102, .0), (-.051, -.23), (.051, -.23)];
        return ('', .5, [for (var i = 0; i < n; i++) (.18 + .32 * (i % 3) + heap[(i ~/ 3) % 5].$1, .6 + heap[(i ~/ 3) % 5].$2)]);
      case 'melon':
        return ('farm/field', 70 / 300, [for (var i = 0; i < n; i++) (.08 + .84 * ((i % 7) / 6), i < 7 ? .78 : .26)]);
      default:
        // On the tree's crown, in rings from the middle.
        final spots = <(double, double)>[];
        const ring = [(0.0, 0.0), (-.18, -.1), (.18, -.1), (-.22, .1), (.22, .1), (0.0, -.2), (0.0, .18), (-.3, -.02), (.3, -.02), (-.12, .25), (.12, .25), (-.12, -.27), (.12, -.27)];
        for (var i = 0; i < n; i++) {
          spots.add((.5 + ring[i % ring.length].$1, .4 + ring[i % ring.length].$2));
        }
        return ('farm/tree', 250 / 240, spots);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final (art, aspect, spots) = _where();
        final w = math.min(math.min(width, box.maxWidth), math.min(height, box.maxHeight) / aspect);
        return _picture(art, w, w * aspect, spots);
      });

  Widget _picture(String art, double w, double h, List<(double, double)> spots) {
    final size = thing.id == 'egg' ? w * .095 : (thing.id == 'melon' ? w * .105 : w * .13);
    return SizedBox(
      width: w,
      height: h,
      child: Stack(clipBehavior: Clip.none, children: [
        if (thing.id == 'egg')
          for (final x in [.18, .5, .82]) Positioned(left: (x - .15) * w, top: h * .62, width: w * .3, height: w * .13, child: const Art('farm/nest', fit: BoxFit.fill))
        else
          Positioned.fill(child: Art(art, fit: BoxFit.fill)),
        for (var i = 0; i < n; i++)
          if (!taken.contains(i))
            Positioned(
              left: spots[i].$1 * w - size / 2,
              top: spots[i].$2 * h - size / 2,
              width: size,
              height: size,
              child: Semantics(
                key: ValueKey('supply-$i'),
                container: true,
                button: true,
                label: thing.zh,
                excludeSemantics: true,
                onTap: () => onPick(i),
                child: Pickable(onPick: () => onPick(i), child: ThingPic(thing.picture, size: size)),
              ),
            ),
      ]),
    );
  }
}

/// Fruit in the basket: rows of five above the rim.
class BasketRow extends StatelessWidget {
  const BasketRow({super.key, required this.thing, required this.n, required this.width, this.hop = 0, this.glow = const {}});

  final Thing thing;
  final int n;
  final double width;
  final int hop;
  final Set<int> glow;

  @override
  Widget build(BuildContext context) {
    final s = width * .17;
    final rows = (n + 4) ~/ 5;
    final h = width * 90 / 160;
    return SizedBox(
      width: width,
      height: h + s * math.max(1, rows) * .8,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(left: 0, right: 0, bottom: 0, height: h, child: const Art('farm/basket', fit: BoxFit.fill)),
        for (var i = 0; i < n; i++)
          Positioned(
            left: width * .1 + (i % 5) * width * .16,
            bottom: h * .72 + (i ~/ 5) * s * .75,
            width: s,
            height: s,
            child: PopIn(key: ValueKey('in-$i'), child: Glow(on: glow.contains(i), child: Hop(trigger: i == n - 1 ? hop : 0, child: ThingPic(thing.picture, size: s)))),
          ),
      ]),
    );
  }
}

/// 撿雞蛋, 摘水果 and 去市場's loading (docs/design.md): put the number on the
/// order into the box, the basket or the truck. 小小農夫: done as soon as it
/// is right. 小農夫: press 「好了！」; too few, 阿嬤 counts with you and says
/// how many more; too many, the extra hop back.
class FillView extends StatefulWidget {
  const FillView({super.key, required this.task, required this.host});

  final FillTask task;
  final TaskHost host;

  @override
  State<FillView> createState() => _FillViewState();
}

class _FillViewState extends State<FillView> {
  final _taken = <int>[];
  var _over = false, _stamped = false, _driving = false;
  int _hop = 0;
  Later? _later;

  FillTask get _t => widget.task;
  TaskHost get _h => widget.host;
  Thing get _thing => _t.thing;
  bool get _small => _h.ask.small;
  int get _slots => _thing.id == 'egg' || _thing.id == 'melon' ? (_rows * 5) : 10;
  int get _rows => _h.ask.frame10 || _t.target > 5 ? 2 : 1;

  String get _sound => switch (_thing.id) {
        'egg' => 'knock',
        'melon' => 'plonk',
        _ => 'thud',
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final who = _t.customer;
      if (who != null) _h.sfx(who.sound);
      if (_thing.id == 'egg') _h.sfx('cluck');
      final ask = switch (_thing.id) {
        'egg' => Strings.eggOrder(_t.target),
        'melon' => Strings.melonOrder(_t.target),
        _ => Strings.fruitOrder(who ?? Animal.sheep, _t.target, _thing),
      };
      _h.say(!_small && _h.explain('fill') ? '$ask${Strings.pressDone}' : ask);
    });
  }

  @override
  void dispose() {
    _later?.cancel();
    super.dispose();
  }

  void _put(int i) {
    if (_over || _taken.contains(i)) return;
    if (_taken.length >= _slots) {
      _h.sfx('swish');
      _h.say(Strings.full);
      return;
    }
    setState(() {
      _taken.add(i);
      _hop++;
    });
    final k = _taken.length;
    _h.sfx(_sound);
    _h.sfx(countNote(k));
    if (_small && k == _t.target) {
      _complete();
      return;
    }
    _h.say(Say.count(k));
  }

  void _ring() {
    if (_over) return;
    final k = _taken.length;
    _h.sfx('bell');
    if (k == _t.target) {
      _complete();
    } else if (k < _t.target) {
      _h.say(Strings.notYet(k, _t.target, _thing.unit));
    } else {
      _over = true;
      final said = _h.say(Strings.tooMany(k, _t.target, _thing, _t.customer));
      _later = Later(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _h.sfx('swish');
        setState(() => _taken.removeRange(_t.target, _taken.length));
        final again = _h.say(Strings.rightAmount(_t.target));
        _later = Later(const Duration(milliseconds: 900), () => _complete(already: true), after: again);
      }, after: said);
    }
  }

  void _complete({bool already = false}) {
    if (!mounted) return;
    _over = true;
    _h.sfx('stamp');
    _h.sfx('count_all');
    final who = _t.customer;
    if (who != null) _h.sfx(who.sound);
    if (_thing.id == 'melon') {
      _h.sfx('honk');
      _h.sfx('engine');
    }
    _h.record((g) => g.count(_t.target));
    setState(() {
      _stamped = true;
      _driving = _thing.id == 'melon';
    });
    _h.done(_h.say(Strings.filled(_t.target, _thing, who)));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = math.min(box.maxWidth - 24, 380.0);
        final who = _t.customer;
        final head = math.min(92.0, box.maxHeight * .18);
        final frameW = math.min(w, 340.0);
        final frame = TenFrame(
          rows: _rows,
          width: frameW,
          item: (i, s) => i < _taken.length ? PopIn(key: ValueKey('in-$i'), child: Hop(trigger: i == _taken.length - 1 ? _hop : 0, child: ThingPic(_thing.picture, size: s))) : null,
        );
        final Widget dest = switch (_thing.id) {
          'egg' => frame,
          'melon' => AnimatedSlide(
              offset: _driving ? const Offset(1.6, 0) : Offset.zero,
              duration: const Duration(milliseconds: 1800),
              curve: Curves.easeIn,
              child: SizedBox(
                width: w,
                height: w * 172 / 360 + frameW * .1,
                child: Stack(clipBehavior: Clip.none, alignment: Alignment.topLeft, children: [
                  Positioned(left: 0, right: 0, bottom: 0, child: AspectRatio(aspectRatio: 360 / 172, child: const Art('farm/truck'))),
                  Positioned(left: w * .02, bottom: w * 172 / 360 * .2, child: SizedBox(width: w * .66, child: FittedBox(child: frame))),
                ]),
              ),
            ),
          _ => BasketRow(thing: _thing, n: _taken.length, width: math.min(w * .8, 300), hop: _hop),
        };
        return Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: OrderSign(n: _t.target, thing: _thing, numerals: _h.ask.numerals, stamped: _stamped, height: head))),
            const SizedBox(width: 10),
            SizedBox(width: head, height: head, child: Art(who != null ? who.picture : (_thing.id == 'egg' ? 'animals/hen' : 'farm/stall'))),
          ]),
          Expanded(child: Center(child: _Supply(thing: _thing, n: _t.supply, taken: _taken.toSet(), onPick: _put, width: w, height: box.maxHeight * .34))),
          dest,
          const SizedBox(height: 6),
          if (!_small)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: PillButton(
                key: const ValueKey('ring'),
                label: Strings.done,
                color: Inks.gold,
                icon: Icons.notifications_active_rounded,
                height: 52,
                sound: null,
                onTap: _over ? null : _ring,
              ),
            ),
        ]);
      });
}

/// 盒子裡有幾顆？ Eggs already in the box; pick a card; whichever card, they
/// are counted together and the answer shows.
class HowManyView extends StatefulWidget {
  const HowManyView({super.key, required this.task, required this.host});

  final HowManyTask task;
  final TaskHost host;

  @override
  State<HowManyView> createState() => _HowManyViewState();
}

class _HowManyViewState extends State<HowManyView> with CountAlong {
  int? _picked;
  int _lit = 0;

  HowManyTask get _t => widget.task;
  TaskHost get _h => widget.host;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _h.say(Strings.howMany(_t.thing));
    });
  }

  void _pick(int k) {
    if (_picked != null) return;
    _h.record((g) => g.glance(_t.n, k == _t.n));
    setState(() => _picked = k);
    countAlong(_h, _t.n, (k) => setState(() => _lit = k), () {
      _h.sfx('count_all');
      _h.record((g) => g.count(_t.n));
      _h.done(_h.say(Strings.all(_t.n, _t.thing)));
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = math.min(box.maxWidth - 24, 360.0);
        final rows = _h.ask.frame10 || _t.n > 5 ? 2 : 1;
        // On a short phone (360 × 640) the hen, the cards and the number
        // blocks are smaller, and the box is shrunk whole (never squashed).
        final short = box.maxHeight < 520;
        final cards = math.min(math.min(104.0, (box.maxWidth - 60) / 3), short ? box.maxHeight * .2 : 104.0);
        final hen = short ? math.max(56.0, box.maxHeight * .17) : 100.0;
        final per = _t.n > 5 ? 5 : _t.n;
        final tiles = short ? math.min(w, 5 * box.maxHeight * .085 + 8 * per) : w;
        return Column(children: [
          const SizedBox(height: 8),
          SizedBox(width: hen * 1.1, height: hen, child: const Art('animals/hen')),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: TenFrame(
                rows: rows,
                width: w,
                item: (i, s) => i < _t.n
                    ? Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                        Hop(trigger: i < _lit ? 1 : 0, child: ThingPic(_t.thing.picture, size: s)),
                        if (i < _lit && _h.ask.numerals) Text('${i + 1}', style: TextStyle(fontSize: s * .38, fontWeight: FontWeight.w700, color: Inks.red)),
                      ])
                    : null,
                ),
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final k in _t.choices)
              Padding(
                padding: const EdgeInsets.all(6),
                child: ChoiceCard(n: k, numerals: _h.ask.numerals, size: cards, ring: _picked == k ? Inks.yellow : (_picked != null && k == _t.n && _lit == _t.n ? Inks.green : null), onTap: _picked == null ? () => _pick(k) : null),
              ),
          ]),
          const SizedBox(height: 6),
          CountTiles(n: _t.n, lit: _lit, numerals: _h.ask.numerals, width: tiles),
          const SizedBox(height: 4),
        ]);
      });
}
