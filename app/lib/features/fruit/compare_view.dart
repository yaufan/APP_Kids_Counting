import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/rounds.dart';
import '../place/task_host.dart';

/// 比一比 (docs/design.md): two customers' fruit lined up one to one, so the
/// extra ones stand out. 「誰的多？」 (小農夫 also 「誰的少？」); whichever is
/// tapped, the extra ones glow and 阿嬤 says who has more. 小農夫 then makes
/// them the same: tap the extra ones and they go back to the tree.
class CompareView extends StatefulWidget {
  const CompareView({super.key, required this.task, required this.host});

  final CompareTask task;
  final TaskHost host;

  @override
  State<CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<CompareView> {
  late final _counts = [widget.task.a, widget.task.b];
  var _answered = false, _evening = false, _over = false;
  final _shake = <String, int>{};
  Later? _later;

  CompareTask get _t => widget.task;
  TaskHost get _h => widget.host;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _h.say(_t.askMore ? Strings.compareMore(_t.left, _t.right) : Strings.compareFewer(_t.left, _t.right));
    });
  }

  @override
  void dispose() {
    _later?.cancel();
    super.dispose();
  }

  void _pick(int row) {
    if (_answered) return;
    _h.sfx((row == 0 ? _t.left : _t.right).sound);
    setState(() => _answered = true);
    final said = _h.say(Strings.compared(_t.left, _t.a, _t.right, _t.b, _t.fruit, _t.askMore));
    if (_h.ask.small) {
      _over = true;
      _h.done(said);
      return;
    }
    _later = Later(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _evening = true);
      _h.say(Strings.makeSame);
    }, after: said);
  }

  void _tapFruit(int row, int i) {
    if (!_evening || _over) return;
    final low = math.min(_counts[0], _counts[1]);
    if (_counts[row] > low && i >= low) {
      _h.sfx('whoosh');
      setState(() => _counts[row]--);
      if (_counts[0] == _counts[1]) {
        _over = true;
        _h.sfx('count_all');
        _h.record((g) => g.count(_counts[0]));
        _h.done(_h.say(Strings.same(_counts[0], _t.fruit.unit)));
      }
      return;
    }
    setState(() => _shake['$row-$i'] = (_shake['$row-$i'] ?? 0) + 1);
    _h.sfx('cheep_q');
    _h.say(Strings.notExtra);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = math.min(box.maxWidth - 16, 600.0);
        final most = math.max(_t.a, _t.b);
        final animal = math.min(84.0, w * .2);
        final fruit = math.min(56.0, (w - animal - 32) / math.max(most, 5));
        final low = math.min(_counts[0], _counts[1]);
        Widget row(int r) {
          final who = r == 0 ? _t.left : _t.right;
          return Semantics(
            key: ValueKey('row-$r'),
            container: true,
            button: !_answered,
            label: who.zh,
            onTap: () => _pick(r),
            child: Pressable(
              onTap: _answered ? null : () => _pick(r),
              sound: null,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(6),
                decoration: inkBox(Inks.cream.withValues(alpha: .85), radius: 20, edge: 1.6, shadow: false),
                child: Row(children: [
                  SizedBox(width: animal, height: animal, child: Art(who.picture)),
                  const SizedBox(width: 8),
                  for (var i = 0; i < _counts[r]; i++)
                    Semantics(
                      key: ValueKey('fruit-$r-$i'),
                      container: true,
                      button: _evening,
                      label: _t.fruit.zh,
                      excludeSemantics: true,
                      onTap: () => _tapFruit(r, i),
                      child: Pressable(
                        onTap: _evening ? () => _tapFruit(r, i) : null,
                        sound: null,
                        child: Wiggle(
                          trigger: _shake['$r-$i'] ?? 0,
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: Glow(on: _answered && i >= low, child: ThingPic(_t.fruit.picture, size: fruit - 2)),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          );
        }

        return Center(
          child: SizedBox(
            width: w,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              row(0),
              // The lines that pair them up, one to one.
              SizedBox(
                height: 18,
                child: Row(children: [
                  SizedBox(width: animal + 14),
                  for (var i = 0; i < low; i++) SizedBox(width: fruit, child: Center(child: Container(width: 3, height: 18, color: Inks.brown.withValues(alpha: .5)))),
                ]),
              ),
              row(1),
              if (_evening) const Padding(padding: EdgeInsets.only(top: 12), child: SizedBox(width: 120, height: 120, child: Art('farm/tree'))),
            ]),
          ),
        );
      });
}
