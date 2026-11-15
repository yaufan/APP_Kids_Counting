import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/rounds.dart';
import '../place/task_host.dart';

/// 分點心 (docs/design.md): the snacks go round one at a time, 「你一個、你一
/// 個……」. Tap the basket and the next one in turn gets one; tap an animal
/// to give it one, but if it already has more it says 「give the one next to
/// me」 and the snack goes to the one with fewest (never stuck, never wrong).
class ShareView extends StatefulWidget {
  const ShareView({super.key, required this.task, required this.host});

  final ShareTask task;
  final TaskHost host;

  @override
  State<ShareView> createState() => _ShareViewState();
}

class _ShareViewState extends State<ShareView> {
  late final _plates = List.filled(widget.task.eaters, 0);
  final _shake = <int, int>{};
  final _hop = <int, int>{};
  var _fair = true, _over = false;

  ShareTask get _t => widget.task;
  TaskHost get _h => widget.host;
  int get _left => _t.total - _plates.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _h.sfx(_t.eater.sound);
      _h.say(Strings.shareHowTo(_t.eater, _t.snack));
    });
  }

  int get _fewest {
    final low = _plates.reduce(math.min);
    return _plates.indexOf(low);
  }

  void _give(int? to) {
    if (_over || _left <= 0) return;
    var i = to ?? _fewest;
    final low = _plates.reduce(math.min);
    final grab = to != null && _plates[to] > low;
    if (grab) {
      _fair = false;
      setState(() => _shake[to] = (_shake[to] ?? 0) + 1);
      _h.sfx('cheep_q');
      _h.say(Strings.iHaveMore);
      i = _fewest;
    }
    setState(() {
      _plates[i]++;
      _hop[i] = (_hop[i] ?? 0) + 1;
    });
    _h.sfx('tick');
    _h.sfx(_t.eater.sound);
    if (_left == 0) {
      _over = true;
      _h.sfx('count_all');
      _h.record((g) => g.shared(_fair).count(_t.each));
      _h.done(_h.say(Strings.shared(_t.eater, _t.each, _t.snack)));
      return;
    }
    if (!grab) _h.say(Strings.youOne);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = math.min(box.maxWidth - 16, 600.0);
        final h = box.maxHeight;
        final col = w / _t.eaters;
        final animal = math.min(col * .75, h * .2);
        final snack = math.min(math.min(col * .3, 40.0), h * .07);
        final basket = math.min(math.min(w * .6, 240.0), h * .38);
        Widget eater(int i) => Semantics(
              key: ValueKey('eater-$i'),
              container: true,
              button: true,
              label: _t.eater.zh,
              excludeSemantics: true,
              onTap: () => _give(i),
              child: Pressable(
                onTap: () => _give(i),
                sound: null,
                child: SizedBox(
                  width: col,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Wiggle(trigger: _shake[i] ?? 0, child: Hop(trigger: _hop[i] ?? 0, height: 10, child: SizedBox(width: animal, height: animal, child: Art(_t.eater.picture)))),
                    SizedBox(
                      width: col * .9,
                      height: snack * 1.9,
                      child: Stack(alignment: Alignment.center, children: [
                        Positioned(left: 0, right: 0, bottom: 0, height: col * .9 * 44 / 120, child: const Art('farm/plate', fit: BoxFit.fill)),
                        Positioned(
                          bottom: col * .9 * 44 / 120 * .35,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            for (var k = 0; k < _plates[i]; k++) Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: PopIn(child: ThingPic(_t.snack.picture, size: math.min(snack, col * .85 / math.max(_t.each, 1) - 2)))),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    AnimatedOpacity(
                      opacity: _over ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: inkBox(Inks.cream, radius: 10, edge: 1.6, shadow: false),
                        child: _h.ask.numerals
                            ? Center(child: Text('${_plates[i]}', textScaler: TextScaler.noScaling, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Inks.red, height: 1)))
                            : DotFace(n: math.max(1, _plates[i])),
                      ),
                    ),
                  ]),
                ),
              ),
            );
        return Column(children: [
          const SizedBox(height: 4),
          SizedBox(width: w, height: math.min(w * 60 / 390, h * .1), child: const Art('farm/fence', fit: BoxFit.fill)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = 0; i < _t.eaters; i++) eater(i)]),
          const Spacer(),
          Semantics(
            key: const ValueKey('basket'),
            container: true,
            button: true,
            label: '籃子',
            excludeSemantics: true,
            onTap: () => _give(null),
            child: Pressable(
              onTap: () => _give(null),
              sound: null,
              child: Glow(
                round: false,
                on: _plates.every((p) => p == 0),
                child: SizedBox(
                  width: basket,
                  child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                    const AspectRatio(aspectRatio: 160 / 90, child: Art('farm/basket')),
                    Positioned(
                      bottom: basket * 90 / 160 * .7,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        for (var k = 0; k < _left; k++) Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: ThingPic(_t.snack.picture, size: math.min(36, basket / math.max(_left, 5) - 2))),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          const Spacer(),
          CountTiles(n: _t.total, lit: _t.total - _left, numerals: _h.ask.numerals, width: math.min(w, 360), color: Inks.pink),
          const SizedBox(height: 6),
        ]);
      });
}
