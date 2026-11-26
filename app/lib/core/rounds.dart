import 'dart:math' as math;

import 'content.dart';

/// What a round needs from the settings: the level, and how far it counts
/// (5 or 10; a parent can change it apart from the level).
class Ask {
  const Ask(this.level, this.maxN);

  final Level level;
  final int maxN;

  bool get small => level == Level.small;

  /// Egg boxes and the truck's bed are a ten-frame (two rows of five) when
  /// counting goes past five, one row of five otherwise.
  bool get frame10 => maxN > 5;

  /// Numerals show at 小農夫; 小小農夫 sees dots and things only.
  bool get numerals => !small;
}

/// One thing to do in a round (docs/design.md 「畫面和玩法」).
sealed class Task {
  const Task();
}

/// 餵小雞: one corn for each chick. With [corn] one short (夠不夠？) the last
/// chick has none until the child pulls one more from the field.
class FeedTask extends Task {
  const FeedTask(this.chicks, this.corn);

  final int chicks;
  final int corn;

  bool get short => corn < chicks;
}

/// 小雞躲貓貓: [n] chicks peek out like the dots of a die, then hide; which
/// dot card was it? Any card is fine: they all come out and are counted.
class PeekTask extends Task {
  const PeekTask(this.n, this.choices);

  final int n;
  final List<int> choices;
}

/// Put [target] things in (撿雞蛋 into the box, 摘水果 into the basket,
/// 去市場 onto the truck), from [supply] that are there.
class FillTask extends Task {
  const FillTask(this.target, this.thing, this.supply, {this.customer});

  final int target;
  final Thing thing;
  final int supply;

  /// Who asked for them (摘水果's customer with the sign).
  final Animal? customer;
}

/// 盒子裡有幾顆？ [n] things already in the box; three cards to pick from.
class HowManyTask extends Task {
  const HowManyTask(this.n, this.choices, this.thing);

  final int n;
  final List<int> choices;
  final Thing thing;
}

/// 比一比: two customers' fruit lined up one to one. [askMore]: 「誰的多？」,
/// else 「誰的少？」 (never at 小小農夫).
class CompareTask extends Task {
  const CompareTask(this.left, this.right, this.a, this.b, this.fruit, this.askMore);

  final Animal left, right;
  final int a, b;
  final Thing fruit;
  final bool askMore;

  /// Who has more (0 left, 1 right).
  int get more => a > b ? 0 : 1;
}

/// 分點心: [eaters] animals, [each] snacks each, shared in turns.
class ShareTask extends Task {
  const ShareTask(this.eater, this.eaters, this.each, this.snack);

  final Animal eater;
  final int eaters;
  final int each;
  final Thing snack;

  int get total => eaters * each;
}

/// 菜園的規律: [row] is planted, the next spot is empty; [answer] belongs
/// there; three seed boxes [options].
class PatternTask extends Task {
  const PatternTask(this.kind, this.row, this.answer, this.options);

  /// 'AB', 'AAB' or 'ABB'.
  final String kind;
  final List<Thing> row;
  final Thing answer;
  final List<Thing> options;
}

/// 鴨子過橋: ducks with numbers 1..n standing in [standing] order; tap them
/// in order and they cross.
class DucksTask extends Task {
  const DucksTask(this.standing);

  final List<int> standing;

  int get n => standing.length;
}

/// 南瓜排排站: three pumpkins (sizes 0 small, 1, 2 big) standing in
/// [standing] order; tap them from small to big.
class PumpkinTask extends Task {
  const PumpkinTask(this.standing);

  final List<int> standing;
}

/// 去市場 at 小農夫: [start] melons on the truck, one more put on ([delta]
/// 1) or one sold to the man (−1); 「現在有幾個？」 from [choices].
class ChangeTask extends Task {
  const ChangeTask(this.start, this.delta, this.choices);

  final int start;
  final int delta;
  final List<int> choices;

  int get result => start + delta;
}

/// Where the dots of [n] (1 to 10) go in a 1 × 1 card: like a die up to 6,
/// then a row of five over the rest (as in the egg box).
List<(double, double)> dotLayout(int n) {
  const a = .22, m = .5, b = .78;
  switch (n) {
    case 1:
      return const [(m, m)];
    case 2:
      return const [(a, a), (b, b)];
    case 3:
      return const [(a, a), (m, m), (b, b)];
    case 4:
      return const [(a, a), (b, a), (a, b), (b, b)];
    case 5:
      return const [(a, a), (b, a), (m, m), (a, b), (b, b)];
    case 6:
      return const [(a, a), (b, a), (a, m), (b, m), (a, b), (b, b)];
  }
  if (n < 1 || n > 10) throw RangeError.range(n, 1, 10);
  return [for (var i = 0; i < n; i++) (.1 + .2 * (i % 5), i < 5 ? .3 : .7)];
}

/// Where slot [i] of an egg box or truck bed is: (column 0..4, row 0..1).
(int, int) frameSlot(int i) => (i % 5, i ~/ 5);

/// The round for [place] (docs/design.md: each place's own list).
List<Task> roundFor(Place place, Ask ask, math.Random r) => switch (place) {
      Place.chicks => _chicks(ask, r),
      Place.eggs => _eggs(ask, r),
      Place.fruit => _fruit(ask, r),
      Place.share => _share(ask, r),
      Place.garden => _garden(ask, r),
      Place.market => _market(ask, r),
    };

/// A number from [lo] to [hi] not in [used] (if one is left), added to it.
int _pick(math.Random r, int lo, int hi, Set<int> used) {
  final free = [for (var i = lo; i <= hi; i++) if (!used.contains(i)) i];
  final v = free.isEmpty ? lo + r.nextInt(hi - lo + 1) : free[r.nextInt(free.length)];
  used.add(v);
  return v;
}

/// [n] and two other numbers from [lo]..[hi] near it, shuffled.
List<int> choicesFor(int n, int lo, int hi, math.Random r) {
  int far(int x) => (x - n).abs() * 2 + (x < n ? 1 : 0);
  final near = [for (var i = lo; i <= hi; i++) if (i != n) i]..sort((x, y) => far(x).compareTo(far(y)));
  final others = near.take(3).toList()..shuffle(r);
  return [n, ...others.take(2)]..shuffle(r);
}

T _one<T>(List<T> list, math.Random r, [T? not]) {
  final from = [for (final x in list) if (x != not) x];
  return from[r.nextInt(from.length)];
}

List<Task> _chicks(Ask ask, math.Random r) {
  final used = <int>{};
  final peekMax = ask.small ? 3 : 5;
  final peeks = <int>{};
  PeekTask peek() {
    final n = _pick(r, 1, peekMax, peeks);
    return PeekTask(n, choicesFor(n, 1, peekMax, r));
  }

  if (ask.small) {
    // As far as it counts (a parent can set 小小農夫 to count to 10).
    final a = _pick(r, 2, ask.maxN, used), b = _pick(r, 2, ask.maxN, used);
    return [FeedTask(a, a), peek(), FeedTask(b, b), peek()];
  }
  final a = _pick(r, 3, ask.maxN, used), b = _pick(r, 3, ask.maxN, used);
  return [FeedTask(a, a), peek(), FeedTask(b, b - 1), peek()];
}

List<Task> _eggs(Ask ask, math.Random r) {
  final used = <int>{};
  final lo = ask.small ? 2 : 3;
  final a = _pick(r, lo, ask.maxN, used), b = _pick(r, lo, ask.maxN, used);
  final h = _pick(r, ask.small ? 1 : 3, ask.maxN, used);
  return [
    FillTask(a, Things.egg, a + 2 + r.nextInt(2)),
    FillTask(b, Things.egg, b + 2 + r.nextInt(2)),
    HowManyTask(h, choicesFor(h, 1, ask.maxN, r), Things.egg),
  ];
}

List<Task> _fruit(Ask ask, math.Random r) {
  final used = <int>{};
  Thing? last;
  Thing fruit() {
    final f = _one(Things.fruit, r, last);
    last = f;
    return f;
  }

  Animal? who;
  Animal customer() {
    final a = _one(Animal.customers, r, who);
    who = a;
    return a;
  }

  FillTask pick() {
    // At most 8 in the basket, whatever the level (as far as it counts).
    final n = _pick(r, ask.small ? 2 : 3, math.min(8, ask.maxN), used);
    return FillTask(n, fruit(), n + 2 + r.nextInt(2), customer: customer());
  }

  CompareTask compare() {
    final two = [...Animal.customers]..shuffle(r);
    final int a, b;
    if (ask.small) {
      // Far apart: 1 and 4, 2 and 5…
      final lo = 1 + r.nextInt(2), hi = lo + 3;
      (a, b) = r.nextBool() ? (lo, hi) : (hi, lo);
    } else {
      final lo = 2 + r.nextInt(math.max(1, math.min(6, ask.maxN - 3))), d = 1 + r.nextInt(2);
      (a, b) = r.nextBool() ? (lo, lo + d) : (lo + d, lo);
    }
    return CompareTask(two[0], two[1], a, b, fruit(), ask.small || r.nextBool());
  }

  return ask.small ? [pick(), pick(), compare()] : [pick(), compare(), pick(), compare()];
}

List<Task> _share(Ask ask, math.Random r) {
  final out = <Task>[];
  Thing? last;
  final seen = <(int, int)>{};
  for (var i = 0; i < 3; i++) {
    final eater = i == 0 ? Animal.pig : _one(Animal.eaters, r);
    final snack = _one(Things.snacks, r, last);
    last = snack;
    int k, each;
    var tries = 0;
    do {
      k = ask.small ? 2 : 2 + r.nextInt(2);
      final most = math.min(ask.small ? 6 : 9, ask.maxN) ~/ k;
      each = 1 + r.nextInt(math.max(1, most));
      if (!ask.small && each == 1 && most > 1) each = 2;
    } while (!seen.add((k, each)) && ++tries < 8);
    out.add(ShareTask(eater, k, each, snack));
  }
  return out;
}

PatternTask _pattern(Ask ask, math.Random r) {
  final kinds = ask.small ? const ['AB'] : const ['AB', 'AAB', 'ABB'];
  final kind = kinds[r.nextInt(kinds.length)];
  final veg = [...Things.veg]..shuffle(r);
  final a = veg[0], b = veg[1], c = veg[2];
  final unit = [for (final ch in kind.split('')) ch == 'A' ? a : b];
  final length = 5 + r.nextInt(2);
  final row = [for (var i = 0; i < length - 1; i++) unit[i % unit.length]];
  final answer = unit[(length - 1) % unit.length];
  final options = [a, b, c]..shuffle(r);
  return PatternTask(kind, row, answer, options);
}

List<int> _shuffled(int n, math.Random r) {
  final sorted = [for (var i = 1; i <= n; i++) i];
  List<int> s;
  do {
    s = [...sorted]..shuffle(r);
  } while (_same(s, sorted));
  return s;
}

bool _same(List<int> a, List<int> b) => a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);

List<Task> _garden(Ask ask, math.Random r) {
  if (ask.small) {
    return [_pattern(ask, r), PumpkinTask([for (final s in _shuffled(3, r)) s - 1]), DucksTask(_shuffled(3, r))];
  }
  final first = _pattern(ask, r);
  var second = _pattern(ask, r);
  for (var i = 0; i < 6 && second.kind == first.kind && second.answer == first.answer; i++) {
    second = _pattern(ask, r);
  }
  return [first, DucksTask(_shuffled(math.min(5, ask.maxN), r)), second];
}

List<Task> _market(Ask ask, math.Random r) {
  final used = <int>{};
  FillTask load(int lo, int hi) {
    final n = _pick(r, lo, hi, used);
    return FillTask(n, Things.melon, n + 2 + r.nextInt(2));
  }

  if (ask.small) {
    final hi = ask.maxN;
    return [load(2, hi), load(1, hi), load(2, hi)];
  }
  final more = 2 + r.nextInt(ask.maxN - 2); // 2..maxN-1, so one more is at most maxN
  final fewer = 2 + r.nextInt(ask.maxN - 1); // 2..maxN, so one fewer is at least 1
  return [
    load(4, ask.maxN),
    ChangeTask(more, 1, choicesFor(more + 1, 1, ask.maxN, r)),
    ChangeTask(fewer, -1, choicesFor(fewer - 1, 1, ask.maxN, r)),
  ];
}
