import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/game.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../parent/parent_gate.dart';

/// The play time is up (docs/design.md 「每次玩多久」): dusk on the farm, the
/// chicks back in the hen house, 牛牛 dozing, and 「換你去做了！去數數家裡的
/// 湯匙吧！」 with today's 回真實生活 card (unless a parent turned the cards
/// off). Only a parent (through the gate) or an hour's wait lets play go on.
class RestScreen extends ConsumerStatefulWidget {
  const RestScreen({super.key});

  @override
  ConsumerState<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends ConsumerState<RestScreen> with HushOnLeave {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      sfx(ref, 'night');
      speak(ref, Strings.restSay);
    });
  }

  Future<void> _parent() async {
    if (!await showParentGate(context) || !mounted) return;
    ref.read(gameProvider.notifier).change((g) => g.playOn());
    ref.read(sessionStartProvider.notifier).restart();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final card = g.settings.cards ? Game.restCard(ref.read(clockProvider)()) : null;
    return WithMusic(
      music: Music.rest,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Inks.dusk1, Inks.dusk2])),
          child: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final w = math.min(box.maxWidth, 600.0);
              return Center(
                child: SizedBox(
                  width: w,
                  child: Stack(children: [
                    for (final (x, y, s) in [(.08, .05, 18.0), (.3, .12, 14.0), (.52, .04, 16.0), (.14, .26, 12.0), (.6, .2, 12.0), (.86, .3, 16.0)])
                      Positioned(left: w * x, top: box.maxHeight * y, width: s, height: s, child: Bob(amount: 2, phase: x, child: const Art('farm/star'))),
                    Positioned(right: w * .06, top: 14, width: w * .18, height: w * .18, child: const Art('farm/moon')),
                    Positioned(left: 0, right: 0, bottom: 0, height: box.maxHeight * .34, child: const Opacity(opacity: .55, child: Art('farm/hills', fit: BoxFit.fill))),
                    Positioned(left: w * .06, bottom: box.maxHeight * .06, width: w * .3, height: w * .26, child: const Art('farm/coop')),
                    Positioned(
                      right: w * .06,
                      bottom: box.maxHeight * .05,
                      width: w * .34,
                      height: w * .3,
                      child: Stack(clipBehavior: Clip.none, children: [
                        const Positioned.fill(child: Art('animals/buffalo_sleep')),
                        Positioned(right: 0, top: -w * .04, child: Text('Z z z', style: TextStyle(fontSize: w * .05, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: .85)))),
                      ]),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      top: box.maxHeight * .1,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                        decoration: inkBox(Inks.cream, radius: 24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Grandma(size: 64),
                            const SizedBox(width: 8),
                            Flexible(child: Text(Strings.restTitle, style: TextStyle(fontSize: math.min(30, w * .075), fontWeight: FontWeight.w700, color: Inks.red))),
                          ]),
                          const SizedBox(height: 6),
                          const Text(Strings.restLine, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, height: 1.45, fontWeight: FontWeight.w700)),
                          if (card != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: inkBox(Inks.paper, radius: 16, edge: 1.6, shadow: false),
                              child: Row(children: [
                                SizedBox(width: 64, height: 64, child: Art(card.picture)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Text(Strings.lifeTitle, style: TextStyle(fontSize: 13, color: Inks.leaf, fontWeight: FontWeight.w700)),
                                    Text(card.text, key: const ValueKey('rest-card'), style: const TextStyle(fontSize: 16, height: 1.4)),
                                  ]),
                                ),
                              ]),
                            ),
                          ],
                        ]),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 10,
                      child: Center(
                        child: Semantics(
                          container: true,
                          button: true,
                          label: Strings.parent,
                          excludeSemantics: true,
                          onTap: _parent,
                          child: Pressable(
                            onTap: _parent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              decoration: inkBox(Inks.cream.withValues(alpha: .92), radius: 22, shadow: false, edge: 1.6),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.lock_outline_rounded, color: Inks.inkSoft, size: 20),
                                SizedBox(width: 6),
                                Text(Strings.restParent, style: TextStyle(fontSize: 16, color: Inks.inkSoft)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
