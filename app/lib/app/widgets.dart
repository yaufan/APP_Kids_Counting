import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/providers.dart';
import '../core/rounds.dart';
import '../core/sounds.dart';
import '../core/voice.dart';
import 'strings.dart';
import 'theme.dart';

/// A drawing from assets/art/ (nothing at all if it is missing).
class Art extends StatelessWidget {
  const Art(this.path, {super.key, this.fit = BoxFit.contain, this.alignment = Alignment.center});

  /// Under assets/art/, without ".svg" (food/egg).
  final String path;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/art/$path.svg', fit: fit, alignment: alignment, excludeFromSemantics: true, errorBuilder: (_, _, _) => const SizedBox.expand());
}

/// The screen that spoke last (its WidgetRef), so a screen going away
/// hushes only its own line, never the next screen's first one.
Object? _speaker;

/// Says [text] out loud (if the parent left the voice on), slower if the
/// parent asked. Completes when the line has been said (or cut off by the
/// next one).
Future<void> speak(WidgetRef ref, String text) {
  final s = ref.read(gameProvider).settings;
  if (!s.voice) return Future.value();
  _speaker = ref;
  return ref.read(voiceProvider).say(text, slow: s.slow);
}

/// A screen that stops its own voice when the child leaves it, so a line
/// does not go on over the next screen.
mixin HushOnLeave<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final Voice _hush;
  late final Object _me;

  @override
  void initState() {
    super.initState();
    _hush = ref.read(voiceProvider);
    _me = ref;
  }

  @override
  void dispose() {
    if (identical(_speaker, _me)) {
      _speaker = null;
      _hush.stop();
    }
    super.dispose();
  }
}

/// Runs [then] after [min], and not before the line [after] has been said
/// (at most [atMost] of waiting for it), so a slow voice is not cut off by
/// the next line; [cancel] stops it.
class Later {
  Later(Duration min, VoidCallback then, {Future<void>? after, Duration atMost = const Duration(seconds: 10)}) : _then = then {
    _timer = Timer(min, () {
      _timeUp = true;
      _fire();
    });
    if (after == null) {
      _heard = true;
    } else {
      after.timeout(atMost).then((_) => _hear(), onError: (_) => _hear());
    }
  }

  final VoidCallback _then;
  late final Timer _timer;
  var _timeUp = false, _heard = false, _over = false;

  void _hear() {
    _heard = true;
    _fire();
  }

  void _fire() {
    if (_over || !_timeUp || !_heard) return;
    _over = true;
    _then();
  }

  void cancel() {
    _over = true;
    _timer.cancel();
  }
}

void sfx(WidgetRef ref, String name) => ref.read(soundsProvider).play(name);

/// Shrinks a little while pressed and fires when the finger lifts on it
/// (raw pointer events: a touch counts at once, no gesture to wait for).
/// Only the first finger counts; a cancelled touch does nothing.
class Pressable extends ConsumerStatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.sound = 'tap'});

  final Widget child;
  final VoidCallback? onTap;
  final String? sound;

  @override
  ConsumerState<Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<Pressable> {
  int? _pointer;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: enabled && _pointer == null ? (e) => setState(() => _pointer = e.pointer) : null,
      onPointerCancel: (e) {
        if (e.pointer == _pointer) setState(() => _pointer = null);
      },
      onPointerUp: (e) {
        if (e.pointer != _pointer) return;
        setState(() => _pointer = null);
        final box = context.findRenderObject() as RenderBox?;
        if (!enabled || box == null || !(Offset.zero & box.size).inflate(12).contains(e.localPosition)) return;
        final s = widget.sound;
        if (s != null) ref.read(soundsProvider).play(s);
        widget.onTap!();
      },
      child: AnimatedScale(scale: _pointer != null ? 0.93 : 1, duration: const Duration(milliseconds: 90), child: widget.child),
    );
  }
}

/// Something the child puts somewhere (an egg, a fruit, a melon, corn): a tap
/// picks it, and so does dragging it and letting go anywhere (docs/design.md:
/// 拖到哪裡放開都算放進去). It follows the first finger while dragged; a
/// cancelled touch puts it back and does nothing.
class Pickable extends StatefulWidget {
  const Pickable({super.key, required this.child, this.onPick});

  final Widget child;
  final VoidCallback? onPick;

  /// A finger that moved further than this is a drag (else a tap that must
  /// lift on the thing).
  static const slop = 14.0;

  @override
  State<Pickable> createState() => _PickableState();
}

class _PickableState extends State<Pickable> {
  int? _pointer;
  Offset _start = Offset.zero, _drag = Offset.zero;

  void _reset() => setState(() {
        _pointer = null;
        _drag = Offset.zero;
      });

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPick != null;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: enabled && _pointer == null
          ? (e) => setState(() {
                _pointer = e.pointer;
                _start = e.position;
                _drag = Offset.zero;
              })
          : null,
      onPointerMove: (e) {
        if (e.pointer == _pointer) setState(() => _drag = e.position - _start);
      },
      onPointerCancel: (e) {
        if (e.pointer == _pointer) _reset();
      },
      onPointerUp: (e) {
        if (e.pointer != _pointer) return;
        final dragged = _drag.distance > Pickable.slop;
        _reset();
        final box = context.findRenderObject() as RenderBox?;
        final onIt = box != null && (Offset.zero & box.size).inflate(12).contains(e.localPosition);
        if (widget.onPick != null && (dragged || onIt)) widget.onPick!();
      },
      child: Transform.translate(
        offset: _drag,
        child: AnimatedScale(scale: _pointer != null ? 1.12 : 1, duration: const Duration(milliseconds: 90), child: widget.child),
      ),
    );
  }
}

/// A flat printed block: one ink colour with a dark ink edge, no shine.
BoxDecoration inkBox(Color color, {double radius = 18, double edge = 2.4, Color? ring, bool shadow = true}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: ring ?? Inks.edge(color), width: ring == null ? edge : 4),
      boxShadow: shadow ? [BoxShadow(color: Inks.ink.withValues(alpha: .14), offset: const Offset(2, 3))] : null,
    );

/// A round button with an icon.
class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.label, required this.icon, this.onTap, this.size = 50, this.color = Inks.cream, this.sound = 'tap'});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final String? sound;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          onTap: onTap,
          sound: sound,
          child: Container(
            width: size,
            height: size,
            decoration: inkBox(color, radius: size / 2),
            child: Icon(icon, size: size * 0.54, color: color.computeLuminance() > .55 ? Inks.ink : Inks.cream),
          ),
        ),
      );
}

/// A wide printed button with a word.
class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, this.onTap, this.color = Inks.green, this.icon, this.height = 58, this.sound = 'tap', this.expand = false});

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final double height;
  final String? sound;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final fg = color.computeLuminance() > .5 ? Inks.ink : Inks.cream;
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        sound: sound,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: height * 0.4),
          decoration: inkBox(color, radius: height / 2),
          child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, size: height * 0.46, color: fg), const SizedBox(width: 8)],
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: height * 0.36, fontWeight: FontWeight.w700, color: fg)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A speech bubble (tap to hear it again).
class Bubble extends StatelessWidget {
  const Bubble({super.key, required this.text, this.onTap, this.size = 18});

  final String text;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: onTap != null,
        label: text,
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          onTap: onTap,
          sound: null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            decoration: inkBox(Inks.cream, radius: 20, edge: 2),
            child: Text(text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: Inks.ink, height: 1.35)),
          ),
        ),
      );
}

/// Words on a wooden sign (the place names, the top bar).
class WoodSign extends StatelessWidget {
  const WoodSign({super.key, required this.text, this.width = 120, this.size = 18, this.color});

  final String text;
  final double width;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: width * .35,
        child: Stack(alignment: Alignment.center, children: [
          const Positioned.fill(child: Art('ui/sign', fit: BoxFit.fill)),
          if (color != null)
            Positioned(left: width * .07, top: width * .07, bottom: width * .07, width: width * .05, child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * .1),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, textScaler: TextScaler.noScaling, style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: Inks.ink))),
          ),
        ]),
      );
}

/// The bar at the top of a place: home, its name on a sign, hear it again.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.onHome, this.onSpeak});

  final String title;
  final VoidCallback? onHome;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
        child: Row(children: [
          onHome == null ? const SizedBox(width: 48) : RoundButton(label: Strings.home, icon: Icons.home_rounded, onTap: onHome, size: 48, color: Inks.red),
          Expanded(child: Center(child: WoodSign(text: title, width: 150, size: 21))),
          onSpeak == null ? const SizedBox(width: 48) : RoundButton(label: Strings.again, icon: Icons.volume_up_rounded, onTap: onSpeak, size: 46, color: Inks.orange, sound: null),
        ]),
      );
}

/// The paper with the carved sky at the top and the hills at the bottom.
class PaperBg extends StatelessWidget {
  const PaperBg({super.key, required this.child, this.sky = true, this.hills = true});

  final Widget child;
  final bool sky, hills;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Inks.paper,
        child: Stack(fit: StackFit.expand, children: [
          if (sky) const Positioned(left: 0, right: 0, top: 0, height: 240, child: Art('farm/sky', fit: BoxFit.cover, alignment: Alignment.topCenter)),
          if (hills) const Positioned(left: 0, right: 0, bottom: 0, height: 150, child: Art('farm/hills', fit: BoxFit.fill)),
          child,
        ]),
      );
}

/// Plays [music] while this is on screen.
class WithMusic extends ConsumerStatefulWidget {
  const WithMusic({super.key, required this.music, required this.child});

  final Music music;
  final Widget child;

  @override
  ConsumerState<WithMusic> createState() => _WithMusicState();
}

class _WithMusicState extends ConsumerState<WithMusic> {
  late final Sounds _sounds = ref.read(soundsProvider);

  @override
  void initState() {
    super.initState();
    _sounds.hold(this, widget.music);
  }

  @override
  void dispose() {
    _sounds.release(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shakes its child side to side once each time [trigger] changes (a chick
/// shaking its head, a duck saying 「not me」).
class Wiggle extends StatefulWidget {
  const Wiggle({super.key, required this.trigger, required this.child, this.amount = 0.12});

  final int trigger;
  final Widget child;
  final double amount;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void didUpdateWidget(Wiggle old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          return Transform.rotate(angle: math.sin(t * math.pi * 4) * (1 - t) * widget.amount, child: child);
        },
        child: widget.child,
      );
}

/// Jumps up once each time [trigger] changes (a thing being counted).
class Hop extends StatefulWidget {
  const Hop({super.key, required this.trigger, required this.child, this.height = 20});

  final int trigger;
  final Widget child;
  final double height;

  @override
  State<Hop> createState() => _HopState();
}

class _HopState extends State<Hop> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));

  @override
  void didUpdateWidget(Hop old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          final up = math.sin(t * math.pi) * widget.height;
          return Transform.translate(offset: Offset(0, -up), child: child);
        },
        child: widget.child,
      );
}

/// A gentle bob up and down.
class Bob extends StatefulWidget {
  const Bob({super.key, required this.child, this.phase = 0, this.amount = 3, this.period = 2400});

  final Widget child;
  final double phase;
  final double amount;
  final int period;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.period))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(offset: Offset(0, math.sin((_c.value + widget.phase) * 2 * math.pi) * widget.amount), child: child),
        child: widget.child,
      );
}

/// Pops in from nothing the first time it is built (a thing landing in the box).
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: .2, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.elasticOut,
        builder: (_, s, c) => Transform.scale(scale: s, child: c),
        child: child,
      );
}

/// A soft glowing ring behind something to tap (阿嬤's hint, the new melon).
class Glow extends StatefulWidget {
  const Glow({super.key, required this.on, required this.child, this.color = Inks.yellow, this.round = true});

  final bool on;
  final Widget child;
  final Color color;

  /// A circle (a thing), or a rounded box (a basket, a button).
  final bool round;

  @override
  State<Glow> createState() => _GlowState();
}

class _GlowState extends State<Glow> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.on) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => DecoratedBox(
        decoration: BoxDecoration(
            shape: widget.round ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.round ? null : BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: widget.color.withValues(alpha: .55 + .35 * _c.value), blurRadius: 10 + 8 * _c.value, spreadRadius: 4 + 4 * _c.value)]),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// 農場阿嬤.
class Grandma extends StatelessWidget {
  const Grandma({super.key, this.size = 80, this.happy = false});

  final double size;
  final bool happy;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size * 140 / 120, child: Art(happy ? 'animals/grandma_happy' : 'animals/grandma'));
}

/// 阿嬤 with what she just said beside her (tap to hear it again).
class GrandmaSays extends StatelessWidget {
  const GrandmaSays({super.key, required this.text, this.onTap, this.size = 64, this.happy = false});

  final String text;
  final VoidCallback? onTap;
  final double size;
  final bool happy;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Semantics(
          container: true,
          button: onTap != null,
          label: '阿嬤',
          excludeSemantics: true,
          onTap: onTap,
          child: Pressable(onTap: onTap, sound: null, child: Bob(child: Grandma(size: size, happy: happy))),
        ),
        const SizedBox(width: 6),
        Flexible(child: Padding(padding: const EdgeInsets.only(bottom: 10), child: Bubble(text: text, onTap: onTap, size: 17))),
      ]);
}

/// Dots for [n] (1 to 10) laid out as on the cards (core/rounds.dart dotLayout).
class DotFace extends StatelessWidget {
  const DotFace({super.key, required this.n, this.color = Inks.red, this.lit});

  final int n;
  final Color color;

  /// How many of the dots are lit (all if null).
  final int? lit;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DotsPainter(n, color, lit ?? n), size: Size.infinite);
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.n, this.color, this.lit);

  final int n;
  final Color color;
  final int lit;

  @override
  void paint(Canvas canvas, Size size) {
    if (n < 1) return;
    final s = math.min(size.width, size.height);
    final off = Offset((size.width - s) / 2, (size.height - s) / 2);
    final r = s * (n > 6 ? .075 : .1);
    final pts = dotLayout(n);
    for (var i = 0; i < pts.length; i++) {
      final (x, y) = pts[i];
      final c = off + Offset(x * s, y * s);
      canvas.drawCircle(c, r, Paint()..color = i < lit ? color : Inks.line);
      canvas.drawCircle(c, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, r * .22)
        ..color = Inks.edge(i < lit ? color : Inks.line));
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.n != n || old.color != color || old.lit != lit;
}

/// A card to pick a number with: dots (小小農夫) or a numeral (小農夫).
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({super.key, required this.n, required this.numerals, this.onTap, this.size = 92, this.ring});

  final int n;
  final bool numerals;
  final VoidCallback? onTap;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) => Semantics(
        key: ValueKey('card-$n'),
        container: true,
        button: true,
        label: '$n',
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          onTap: onTap,
          sound: 'tap',
          child: Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * .1),
            decoration: inkBox(Inks.cream, radius: size * .18, ring: ring),
            child: numerals
                ? Center(child: Text('$n', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: size * .56, fontWeight: FontWeight.w700, color: Inks.ink, height: 1)))
                : DotFace(n: n),
          ),
        ),
      );
}

/// The wooden number blocks under a count: [n] of them, [lit] lit. 小小農夫
/// sees round beads instead of numerals (docs/design.md: no numerals).
class CountTiles extends StatelessWidget {
  const CountTiles({super.key, required this.n, required this.lit, required this.numerals, this.width = 360, this.color = Inks.orange});

  final int n;
  final int lit;
  final bool numerals;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final per = n > 5 ? 5 : n;
    final size = math.min(52.0, (width - 8 * per) / math.max(per, 5));
    Widget tile(int i) {
      final on = i < lit;
      return AnimatedContainer(
        key: ValueKey('tile-${i + 1}${on ? '-on' : ''}'),
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: inkBox(on ? color : Inks.cream, radius: numerals ? size * .2 : size / 2, shadow: on, edge: 2),
        child: numerals
            ? Text('${i + 1}', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: size * .55, height: 1, fontWeight: FontWeight.w700, color: on ? Inks.cream : Inks.line))
            : null,
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (var r = 0; r * 5 < n; r++) Row(mainAxisSize: MainAxisSize.min, children: [for (var i = r * 5; i < math.min(n, r * 5 + 5); i++) tile(i)]),
    ]);
  }
}

/// The wooden egg box / truck bed: a ten-frame of [rows] rows of five holes
/// (assets/art/ui/tray5.svg, tray10.svg); [item] puts something in hole i.
class TenFrame extends StatelessWidget {
  const TenFrame({super.key, required this.rows, required this.width, required this.item});

  final int rows;
  final double width;
  final Widget? Function(int i, double size) item;

  @override
  Widget build(BuildContext context) {
    final hUnits = 16.0 + 60 * rows;
    final k = width / 300;
    final s = 52 * k;
    return SizedBox(
      width: width,
      height: hUnits * k,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: Art(rows == 1 ? 'ui/tray5' : 'ui/tray10', fit: BoxFit.fill)),
        for (var i = 0; i < rows * 5; i++)
          if (item(i, s) case final w?)
            Positioned(left: (30 + 60 * (i % 5)) * k - s / 2, top: (38 + 60 * (i ~/ 5)) * k - s / 2, width: s, height: s, child: w),
      ]),
    );
  }
}

/// A thing's picture that can be picked (or just shown).
class ThingPic extends StatelessWidget {
  const ThingPic(this.picture, {super.key, required this.size, this.angle = 0});

  final String picture;
  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: Transform.rotate(angle: angle, child: Art(picture)));
}

/// Little bits of paper flying up when a round is done.
class Confetti extends StatefulWidget {
  const Confetti({super.key, required this.trigger});

  final int trigger;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didUpdateWidget(Confetti old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => _c.isAnimating ? CustomPaint(painter: _ConfettiPainter(_c.value, widget.trigger), size: Size.infinite) : const SizedBox.expand(),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.seed);

  final double t;
  final int seed;

  static const colors = [Inks.red, Inks.yellow, Inks.blue, Inks.green, Inks.pink, Inks.orange];

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed);
    for (var i = 0; i < 32; i++) {
      final x0 = size.width * (.2 + .6 * r.nextDouble());
      final vx = (r.nextDouble() - .5) * size.width * .9;
      final vy = -size.height * (.6 + .5 * r.nextDouble());
      final x = x0 + vx * t;
      final y = size.height * .62 + vy * t + size.height * 1.3 * t * t;
      final p = Paint()..color = colors[i % colors.length].withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 8 + i);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -3, 10, 6), const Radius.circular(1)), p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// A card over a dimmed screen (the end of a round, the 回真實生活 card).
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        color: Inks.ink.withValues(alpha: .35),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Container(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), decoration: inkBox(Inks.cream, radius: 26), child: child),
          ),
        ),
      );
}
