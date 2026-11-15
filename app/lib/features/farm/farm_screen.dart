import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/farm_layout.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/game.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../../core/speech.dart';
import '../parent/parent_gate.dart';

/// The farm (docs/design.md 「農場（首頁）」): the six places along the dirt
/// path, 阿嬤 asking where to go first, 牛牛, and what the farm has grown;
/// the chick sign lines the chicks up to be counted.
class FarmScreen extends ConsumerStatefulWidget {
  const FarmScreen({super.key});

  @override
  ConsumerState<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends ConsumerState<FarmScreen> with HushOnLeave {
  String _line = Strings.where;
  bool _parade = false;
  final _counted = <int>{};
  int _moo = 0;
  final _shake = <Place, int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(onceProvider).add('hello')) {
        _say(Strings.hello);
      }
    });
  }

  Future<void> _say(String line) {
    setState(() => _line = line);
    return speak(ref, line);
  }

  void _open(Place p) {
    final s = ref.read(gameProvider).settings;
    if (!s.open(p)) {
      setState(() => _shake[p] = (_shake[p] ?? 0) + 1);
      sfx(ref, 'cheep_q');
      _say(Strings.lockedPlace);
      return;
    }
    context.go('/${p.name}');
  }

  Future<void> _parent() async {
    if (!await showParentGate(context) || !mounted) return;
    context.go('/parent');
  }

  void _countChick(int i, int shown, int all) {
    if (_counted.contains(i)) {
      sfx(ref, 'cheep_q');
      return;
    }
    setState(() => _counted.add(i));
    final k = _counted.length;
    sfx(ref, countNote(k));
    sfx(ref, 'cheep');
    if (k < shown) {
      _say(Say.count(k));
      return;
    }
    sfx(ref, 'count_all');
    ref.read(gameProvider.notifier).change((g) => g.count(shown));
    _say(all > shown ? Strings.manyChicks : Strings.chicksCounted(all));
  }

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final s = g.settings;
    return WithMusic(
      music: Music.farm,
      child: Scaffold(
        body: ColoredBox(
          color: Inks.sky,
          child: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final b = math.min(1.3, math.max(.85, box.maxWidth / 390));
              final bar = 132.0 * b;
              final w = math.min(box.maxWidth, (box.maxHeight - bar - 4) * farmAspect);
              final h = w / farmAspect;
              final k = w / 390;
              final farmTop = (box.maxHeight - bar - h) / 2;
              return Stack(children: [
                // The grass beside the picture (on a wide screen) meets its hills.
                Positioned(left: 0, right: 0, top: farmTop + h * .3, bottom: 0, child: const ColoredBox(color: Inks.green)),
                Column(children: [
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: Stack(clipBehavior: Clip.none, children: [
                          const Positioned.fill(child: Art('farm/home', fit: BoxFit.fill)),
                          // What the farm has grown.
                          for (final (i, (x, y)) in hatchSpots.take(math.min(g.farm.chicks, hatchSpots.length)).indexed)
                            Positioned(left: x * w - 13 * k, top: y * h - 22 * k, width: 26 * k, height: 26 * k, child: Bob(phase: i * .17, amount: 1.5, child: const Art('animals/chick'))),
                          for (final (x, y) in treeFruitSpots.take(math.min(g.farm.fruit, treeFruitSpots.length)))
                            Positioned(left: x * w - 9 * k, top: y * h - 9 * k, width: 18 * k, height: 18 * k, child: const Art('food/guava')),
                          for (final (x, y) in sproutSpots.take(math.min(g.farm.veg, sproutSpots.length)))
                            Positioned(left: x * w - 11 * k, top: y * h - 14 * k, width: 22 * k, height: 22 * k, child: const Art('food/cabbage')),
                          for (final (x, y) in melonSpots.take(math.min(g.farm.melons, melonSpots.length)))
                            Positioned(left: x * w - 12 * k, top: y * h - 12 * k, width: 24 * k, height: 24 * k, child: const Art('food/melon')),
                          // The places: tap the picture or its sign.
                          for (final p in Place.values)
                            if (s.places.contains(p)) ..._place(p, s.open(p), w, h, k),
                        ]),
                      ),
                    ),
                  ),
                  // 阿嬤, 牛牛 and the chick sign.
                  SizedBox(
                    height: bar,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Expanded(child: GrandmaSays(text: _line, size: 70 * b, onTap: () => _say(_line))),
                        Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Semantics(
                            key: const ValueKey('buffalo'),
                            container: true,
                            button: true,
                            label: '牛牛',
                            excludeSemantics: true,
                            onTap: _mooed,
                            child: Pressable(onTap: _mooed, sound: null, child: SizedBox(width: 92 * b, height: 78 * b, child: Wiggle(trigger: _moo, amount: .06, child: const Art('animals/buffalo')))),
                          ),
                          Semantics(
                            key: const ValueKey('chick-sign'),
                            container: true,
                            button: true,
                            label: Strings.chickSign(g.farm.chicks),
                            excludeSemantics: true,
                            onTap: _openParade,
                            child: Pressable(onTap: _openParade, child: WoodSign(text: Strings.chickSign(g.farm.chicks), width: 104 * b, size: 17)),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ]),
                Positioned(
                  left: 10,
                  top: 8,
                  child: RoundButton(label: Strings.parent, icon: Icons.lock_outline_rounded, size: 42, onTap: _parent, color: Inks.cream),
                ),
                if (_parade) Positioned.fill(child: _paradePanel(g)),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  void _mooed() {
    setState(() => _moo++);
    sfx(ref, 'moo');
    _say(Strings.moo);
  }

  void _openParade() {
    setState(() {
      _parade = true;
      _counted.clear();
    });
    sfx(ref, 'cheep');
    _say(Strings.countChicks);
  }

  List<Widget> _place(Place p, bool open, double w, double h, double k) {
    final (x, y) = farmSpots[p.name]!;
    void go() => _open(p);
    return [
      Positioned(
        left: x * w - 60 * k,
        top: y * h - 56 * k,
        width: 120 * k,
        height: 84 * k,
        child: Listener(behavior: HitTestBehavior.translucent, child: Pressable(onTap: go, child: const SizedBox.expand())),
      ),
      Positioned(
        left: x * w - 58 * k,
        top: y * h + 30 * k,
        child: Semantics(
          key: ValueKey('place-${p.name}'),
          container: true,
          button: true,
          label: p.zh,
          excludeSemantics: true,
          onTap: go,
          child: Pressable(
            onTap: go,
            child: Wiggle(
              trigger: _shake[p] ?? 0,
              child: Stack(clipBehavior: Clip.none, children: [
                WoodSign(text: p.zh, width: 116 * k, size: 19),
                if (!open) Positioned(right: -6 * k, top: -10 * k, width: 26 * k, height: 26 * k, child: const Art('ui/lock')),
              ]),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _paradePanel(Game g) {
    final all = g.farm.chicks;
    final shown = math.min(all, 10);
    final big = g.settings.level != Level.small;
    return Panel(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(Strings.chickSign(all), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, box) {
          final size = math.min(64.0, box.maxWidth / 5 - 6);
          return Column(children: [
            for (var r = 0; r * 5 < shown; r++)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = r * 5; i < math.min(shown, r * 5 + 5); i++)
                  Semantics(
                    key: ValueKey('parade-$i'),
                    container: true,
                    button: true,
                    label: '小雞 ${i + 1}',
                    excludeSemantics: true,
                    onTap: () => _countChick(i, shown, all),
                    child: Pressable(
                      onTap: () => _countChick(i, shown, all),
                      sound: null,
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
                          Hop(trigger: _counted.contains(i) ? 1 : 0, child: ThingPic(_counted.contains(i) ? 'animals/chick_happy' : 'animals/chick', size: size)),
                          if (big && _counted.contains(i))
                            Positioned(
                              top: -8,
                              child: Text('${_counted.toList().indexOf(i) + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Inks.red)),
                            ),
                        ]),
                      ),
                    ),
                  ),
              ]),
          ]);
        }),
        const SizedBox(height: 10),
        CountTiles(n: shown, lit: _counted.length, numerals: big, width: 300),
        const SizedBox(height: 14),
        PillButton(label: Strings.back, color: Inks.red, icon: Icons.close_rounded, onTap: () => setState(() => _parade = false)),
      ]),
    );
  }
}
