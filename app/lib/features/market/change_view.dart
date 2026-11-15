import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/rounds.dart';
import '../../core/speech.dart';
import '../place/task_host.dart';

/// 去市場's 多一個 and 少一個 (小農夫, docs/design.md): one more melon put on
/// the truck, or one handed to 阿伯 who buys it; 「現在有幾個？」 from three
/// cards, whichever card: counted together and the answer shows. With the
/// parent's switch on, the number sentence (4 ＋ 1 ＝ 5) shows under it.
class ChangeView extends StatefulWidget {
  const ChangeView({super.key, required this.task, required this.host});

  final ChangeTask task;
  final TaskHost host;

  @override
  State<ChangeView> createState() => _ChangeViewState();
}

class _ChangeViewState extends State<ChangeView> with CountAlong {
  late int _onTruck = widget.task.start;
  var _moved = false, _asking = false, _shown = false;
  int? _picked;
  int _lit = 0;

  ChangeTask get _t => widget.task;
  TaskHost get _h => widget.host;
  bool get _more => _t.delta > 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _h.sfx('bell');
      _h.say(_more ? Strings.moreAsk(_t.start) : Strings.fewerAsk(_t.start));
    });
  }

  void _addOne() {
    if (!_more || _moved) return;
    _h.sfx('plonk');
    setState(() {
      _moved = true;
      _onTruck++;
      _asking = true;
    });
    _h.say(Strings.nowHowMany);
  }

  void _sell(int i) {
    if (_more || _moved) return;
    _h.sfx('bell');
    _h.sfx('whoosh');
    setState(() {
      _moved = true;
      _onTruck--;
      _asking = true;
    });
    _h.say('${Strings.thanksUncle}${Strings.leftHowMany}');
  }

  void _pick(int k) {
    if (!_asking || _picked != null) return;
    _h.record((g) => g.glance(_t.result, k == _t.result));
    setState(() => _picked = k);
    countAlong(_h, _t.result, (k) => setState(() => _lit = k), () {
      _h.sfx('count_all');
      _h.record((g) => g.count(_t.result));
      setState(() => _shown = true);
      _h.done(_h.say(_more ? Strings.moreDone(_t.start, _t.result) : Strings.fewerDone(_t.start, _t.result)));
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = math.min(box.maxWidth - 16, 420.0);
        final frameW = w * .66;
        final cards = math.min(100.0, (box.maxWidth - 60) / 3);
        // The melons on the truck fill the ten-frame from the top left (one
        // sold: the rest close up, so they are still easy to count).
        final frame = TenFrame(
          rows: 2,
          width: 300,
          item: (i, s) {
            if (i >= _onTruck) return null;
            final idx = i;
            final isNew = _more && _moved && i == _onTruck - 1;
            return Semantics(
              key: ValueKey('truck-$i'),
              container: true,
              button: !_more && !_moved,
              label: Things.melon.zh,
              excludeSemantics: true,
              onTap: () => _sell(i),
              child: Pickable(
                onPick: !_more && !_moved ? () => _sell(i) : null,
                child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                  Glow(on: isNew, child: Hop(trigger: idx < _lit ? 1 : 0, child: ThingPic(Things.melon.picture, size: s))),
                  if (idx < _lit && _h.ask.numerals) Text('${idx + 1}', style: TextStyle(fontSize: s * .4, fontWeight: FontWeight.w700, color: Inks.cream, shadows: const [Shadow(color: Inks.ink, blurRadius: 3)])),
                ]),
              ),
            );
          },
        );
        return Column(children: [
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
              if (_more)
                Semantics(
                  key: const ValueKey('field-melon'),
                  container: true,
                  button: !_moved,
                  label: Things.melon.zh,
                  excludeSemantics: true,
                  onTap: _addOne,
                  child: SizedBox(
                    width: w * .4,
                    child: Stack(alignment: Alignment.center, children: [
                      const AspectRatio(aspectRatio: 300 / 70, child: Art('farm/field', fit: BoxFit.fill)),
                      if (!_moved) Pickable(onPick: _addOne, child: Glow(on: true, child: ThingPic(Things.melon.picture, size: w * .14))),
                    ]),
                  ),
                )
              else
                Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: w * .3, height: w * .36, child: const Art('animals/uncle')),
                  if (_moved) PopIn(child: ThingPic(Things.melon.picture, size: w * .12)),
                ]),
              const SizedBox(width: 10),
              const SizedBox(width: 90, height: 80, child: Art('farm/stall')),
            ]),
          ),
          SizedBox(
            width: w,
            height: w * 172 / 360 + frameW * .1,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(left: 0, right: 0, bottom: 0, child: AspectRatio(aspectRatio: 360 / 172, child: const Art('farm/truck'))),
              Positioned(left: w * .02, bottom: w * 172 / 360 * .2, child: SizedBox(width: frameW, child: FittedBox(child: frame))),
            ]),
          ),
          const SizedBox(height: 8),
          if (_shown && _h.settings.sentences)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(Say.sentence(_t.start, _t.delta), key: const ValueKey('sentence'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Inks.blue)),
            ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _asking ? 1 : .3,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final k in _t.choices)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: ChoiceCard(n: k, numerals: _h.ask.numerals, size: cards, ring: _picked == k ? Inks.yellow : (_shown && k == _t.result ? Inks.green : null), onTap: _asking && _picked == null ? () => _pick(k) : null),
                ),
            ]),
          ),
          const SizedBox(height: 6),
        ]);
      });
}
