import 'dart:math' as math;

import 'content.dart';
import 'rounds.dart';

/// What a parent set (parent mode).
class Settings {
  const Settings({
    this.level = Level.small,
    this.minutes = 15,
    this.countTo,
    this.places = const {...Place.values},
    this.sentences = false,
    this.cards = true,
    this.hints = true,
    this.voice = true,
    this.slow = false,
    this.music = true,
    this.sounds = true,
    this.full = true,
  });

  final Level level;

  /// How long one sitting may be before a rest.
  final int minutes;

  /// How far it counts (5 or 10); null: as the level says.
  final int? countTo;

  /// The places to play (at least one that can be played).
  final Set<Place> places;

  /// The number sentence (4 ＋ 1 ＝ 5) under 多一個、少一個 (off unless a parent turns it on).
  final bool sentences;

  /// The 回真實生活 card after each round and at the rest.
  final bool cards;

  /// 阿嬤's help after two misses (the right one glows, then she does it).
  final bool hints;
  final bool voice;

  /// A slower voice.
  final bool slow;
  final bool music;
  final bool sounds;

  /// The full version (everything); on while testing.
  final bool full;

  static const minuteChoices = [5, 10, 15, 20, 30];
  static const countChoices = [5, 10];

  int get maxN => countTo ?? level.countTo;

  Ask get ask => Ask(level, maxN);

  bool open(Place p) => full || Place.free.contains(p);

  /// Turned on by the parent and in this version.
  bool enabled(Place p) => places.contains(p) && open(p);

  /// Places a parent turned off stay off; at least one that can be played
  /// is always on (in the free version, a free one: with only full-version
  /// places left on, nothing could be played at all).
  static Set<Place> tidy(Set<Place> s, {bool full = true}) {
    final out = {...s};
    if (!out.any((p) => full || Place.free.contains(p))) out.add(Place.chicks);
    return out;
  }

  Settings copyWith({
    Level? level,
    int? minutes,
    int? countTo,
    bool byLevel = false,
    Set<Place>? places,
    bool? sentences,
    bool? cards,
    bool? hints,
    bool? voice,
    bool? slow,
    bool? music,
    bool? sounds,
    bool? full,
  }) =>
      Settings(
        level: level ?? this.level,
        minutes: minutes ?? this.minutes,
        countTo: byLevel ? null : (countTo ?? this.countTo),
        places: tidy(places ?? this.places, full: full ?? this.full),
        sentences: sentences ?? this.sentences,
        cards: cards ?? this.cards,
        hints: hints ?? this.hints,
        voice: voice ?? this.voice,
        slow: slow ?? this.slow,
        music: music ?? this.music,
        sounds: sounds ?? this.sounds,
        full: full ?? this.full,
      );

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'minutes': minutes,
        if (countTo != null) 'countTo': countTo,
        'places': [for (final p in Place.values) if (places.contains(p)) p.name],
        'sentences': sentences,
        'cards': cards,
        'hints': hints,
        'voice': voice,
        'slow': slow,
        'music': music,
        'sounds': sounds,
        'full': full,
      };

  factory Settings.fromJson(Map<String, dynamic> j) {
    final m = j['minutes'], c = j['countTo'], pl = j['places'];
    bool flag(String k, bool d) => j[k] is bool ? j[k] as bool : d;
    final full = flag('full', true);
    return Settings(
      level: Level.values.asNameMap()[j['level']] ?? Level.small,
      minutes: m is int && minuteChoices.contains(m) ? m : 15,
      countTo: c is int && countChoices.contains(c) ? c : null,
      places: pl is List
          ? tidy({
              for (final n in pl) ?Place.values.asNameMap()[n],
            }, full: full)
          : const {...Place.values},
      sentences: flag('sentences', false),
      cards: flag('cards', true),
      hints: flag('hints', true),
      voice: flag('voice', true),
      slow: flag('slow', false),
      music: flag('music', true),
      sounds: flag('sounds', true),
      full: full,
    );
  }
}

/// How the farm has grown (docs/design.md 「農場會慢慢變熱鬧」): it only
/// ever grows.
class Farm {
  const Farm({this.chicks = 3, this.fruit = 0, this.meals = 0, this.veg = 0, this.melons = 0});

  final int chicks;
  final int fruit;
  final int meals;
  final int veg;
  final int melons;

  static const most = 999;

  /// A round of [p] was played.
  Farm grow(Place p) {
    int up(int v) => math.min(most, v + 1);
    return switch (p) {
      Place.chicks || Place.eggs => Farm(chicks: up(chicks), fruit: fruit, meals: meals, veg: veg, melons: melons),
      Place.fruit => Farm(chicks: chicks, fruit: up(fruit), meals: meals, veg: veg, melons: melons),
      Place.share => Farm(chicks: chicks, fruit: fruit, meals: up(meals), veg: veg, melons: melons),
      Place.garden => Farm(chicks: chicks, fruit: fruit, meals: meals, veg: up(veg), melons: melons),
      Place.market => Farm(chicks: chicks, fruit: fruit, meals: meals, veg: veg, melons: up(melons)),
    };
  }

  Map<String, dynamic> toJson() => {'chicks': chicks, 'fruit': fruit, 'meals': meals, 'veg': veg, 'melons': melons};

  factory Farm.fromJson(dynamic j) {
    if (j is! Map) return const Farm();
    int v(String k, int d) => j[k] is int && (j[k] as int) >= 0 ? math.min(most, j[k] as int) : d;
    return Farm(chicks: math.max(3, v('chicks', 3)), fruit: v('fruit', 0), meals: v('meals', 0), veg: v('veg', 0), melons: v('melons', 0));
  }
}

/// A 回真實生活 card the child said 「好！」 to, for the parent's 農場日記.
class DiaryEntry {
  const DiaryEntry(this.card, this.day, {this.done = false});

  final String card;

  /// The day the card was shown (even if 「好！」 was pressed after midnight).
  final String day;

  /// A parent ticked 「做過了」.
  final bool done;

  Map<String, dynamic> toJson() => {'card': card, 'day': day, 'done': done};

  static DiaryEntry? fromJson(dynamic j) {
    if (j is! Map || j['card'] is! String || cardById(j['card'] as String) == null) return null;
    if (j['day'] is! String || Days.parse(j['day'] as String) == null) return null;
    return DiaryEntry(j['card'] as String, j['day'] as String, done: j['done'] == true);
  }
}

/// 小雞躲貓貓 and 盒子裡有幾顆 for one amount: asked, and picked right.
class Glance {
  const Glance([this.asked = 0, this.right = 0]);

  final int asked;
  final int right;

  Map<String, dynamic> toJson() => {'asked': asked, 'right': right};

  static Glance fromJson(dynamic j) {
    if (j is! Map) return const Glance();
    final a = j['asked'], r = j['right'];
    final asked = a is int && a > 0 ? math.min(a, 9999) : 0;
    return Glance(asked, r is int && r > 0 ? math.min(r, asked) : 0);
  }
}

/// What was played today (parent mode): minutes and places.
class DayLog {
  const DayLog(this.day, {this.seconds = 0, this.places = const {}});

  final String day;
  final int seconds;
  final Set<Place> places;

  Map<String, dynamic> toJson() => {'day': day, 'seconds': seconds, 'places': [for (final p in places) p.name]};

  static DayLog? fromJson(dynamic j) {
    if (j is! Map || j['day'] is! String || Days.parse(j['day'] as String) == null) return null;
    final s = j['seconds'], p = j['places'];
    return DayLog(j['day'] as String, seconds: s is int && s > 0 ? s : 0, places: {
      if (p is List)
        for (final n in p) ?Place.values.asNameMap()[n],
    });
  }
}

abstract final class Days {
  static String key(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? parse(String k) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(k);
    if (m == null) return null;
    final d = DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    return key(d) == k ? d : null;
  }

  /// Days since 1 January 2000 (the rest's card changes every day).
  static int number(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2000)).inDays;
}

/// Everything kept on the phone. One small file (store.dart).
class Game {
  const Game({
    this.settings = const Settings(),
    this.counted = const {},
    this.glances = const {},
    this.shares = 0,
    this.fairShares = 0,
    this.patterns = const {},
    this.farm = const Farm(),
    this.nextCard = const {},
    this.diary = const [],
    this.today,
    this.restSince,
  });

  final Settings settings;

  /// How many times each amount (1 to 20) was counted to the end.
  final Map<int, int> counted;

  /// Seeing amounts at a glance (小雞躲貓貓, 盒子裡有幾顆).
  final Map<int, Glance> glances;

  /// 分點心 rounds, and the ones shared in turns all the way (no snack
  /// tapped for one who already had more).
  final int shares;
  final int fairShares;

  /// The kinds of 菜園的規律 planted right ('AB', 'AAB', 'ABB').
  final Set<String> patterns;
  final Farm farm;

  /// Which of each place's cards comes next.
  final Map<Place, int> nextCard;

  /// 農場日記, oldest first.
  final List<DiaryEntry> diary;
  final DayLog? today;

  /// When the play time ran out (null: playing).
  final DateTime? restSince;

  static const restLength = Duration(hours: 1);
  static const maxDiary = 60;
  static const _most = 9999;

  /// Resting for an hour after the time ran out. A clock moved back (now
  /// before the rest began) does not lock the app: it counts as rested.
  bool resting(DateTime now) {
    final since = restSince;
    if (since == null) return false;
    final d = now.difference(since);
    return !d.isNegative && d < restLength;
  }

  Game copyWith({
    Settings? settings,
    Map<int, int>? counted,
    Map<int, Glance>? glances,
    int? shares,
    int? fairShares,
    Set<String>? patterns,
    Farm? farm,
    Map<Place, int>? nextCard,
    List<DiaryEntry>? diary,
    DayLog? today,
    DateTime? restSince,
    bool clearRest = false,
  }) =>
      Game(
        settings: settings ?? this.settings,
        counted: counted ?? this.counted,
        glances: glances ?? this.glances,
        shares: shares ?? this.shares,
        fairShares: fairShares ?? this.fairShares,
        patterns: patterns ?? this.patterns,
        farm: farm ?? this.farm,
        nextCard: nextCard ?? this.nextCard,
        diary: diary ?? this.diary,
        today: today ?? this.today,
        restSince: clearRest ? null : (restSince ?? this.restSince),
      );

  Game withSettings(Settings s) => copyWith(settings: s);

  // ---- what was counted (parent mode's progress)

  /// [n] things were counted to the end.
  Game count(int n) {
    if (n < 1 || n > 20) return this;
    return copyWith(counted: {...counted, n: math.min(_most, (counted[n] ?? 0) + 1)});
  }

  /// [n] was shown at a glance; [right]: the card picked was [n].
  Game glance(int n, bool right) {
    if (n < 1 || n > 20) return this;
    final g = glances[n] ?? const Glance();
    return copyWith(glances: {...glances, n: Glance(math.min(_most, g.asked + 1), math.min(_most, g.right + (right ? 1 : 0)))});
  }

  /// A 分點心 round shared out; [fair]: in turns all the way.
  Game shared(bool fair) => copyWith(shares: math.min(_most, shares + 1), fairShares: math.min(_most, fairShares + (fair ? 1 : 0)));

  Game planted(String kind) => patterns.contains(kind) ? this : copyWith(patterns: {...patterns, kind});

  /// A round of [p] finished: the farm grows, and today's log knows.
  Game finished(Place p, DateTime now) {
    final d = log(now);
    return copyWith(farm: farm.grow(p), today: DayLog(d.day, seconds: d.seconds, places: {...d.places, p}));
  }

  // ---- 回真實生活

  /// The card [p] gives next.
  LifeCard cardFor(Place p) {
    final cards = cardsOf(p);
    return cards[(nextCard[p] ?? 0) % cards.length];
  }

  /// [p]'s card was shown: the next one comes next time.
  Game cardShown(Place p) => copyWith(nextCard: {...nextCard, p: ((nextCard[p] ?? 0) + 1) % cardsOf(p).length});

  /// 「好！」 to [card], shown on [day]: into the diary (once a day per card).
  Game keep(LifeCard card, String day) {
    if (diary.any((e) => e.card == card.id && e.day == day)) return this;
    final list = [...diary, DiaryEntry(card.id, day)];
    return copyWith(diary: list.skip(math.max(0, list.length - maxDiary)).toList());
  }

  /// A parent ticks (or unticks) diary entry [i].
  Game tick(int i, bool done) {
    if (i < 0 || i >= diary.length) return this;
    final e = diary[i];
    return copyWith(diary: [...diary]..[i] = DiaryEntry(e.card, e.day, done: done));
  }

  /// The rest's card for the day.
  static LifeCard restCard(DateTime now) => lifeCards[Days.number(now) % lifeCards.length];

  // ---- today (parent mode)

  DayLog log(DateTime now) {
    final d = today;
    return d != null && d.day == Days.key(now) ? d : DayLog(Days.key(now));
  }

  Game played(DateTime now, int seconds) {
    final d = log(now);
    return copyWith(today: DayLog(d.day, seconds: d.seconds + seconds, places: d.places));
  }

  Game rest(DateTime now) => copyWith(restSince: now);

  Game playOn() => copyWith(clearRest: true);

  Map<String, dynamic> toJson() => {
        'version': 1,
        'settings': settings.toJson(),
        'counted': {for (final e in counted.entries) '${e.key}': e.value},
        'glances': {for (final e in glances.entries) '${e.key}': e.value.toJson()},
        'shares': shares,
        'fairShares': fairShares,
        'patterns': (patterns.toList()..sort()),
        'farm': farm.toJson(),
        'nextCard': {for (final e in nextCard.entries) e.key.name: e.value},
        'diary': [for (final e in diary) e.toJson()],
        if (today != null) 'today': today!.toJson(),
        if (restSince != null) 'restSince': restSince!.toIso8601String(),
      };

  /// Reads a saved game; anything broken or unknown is left out.
  factory Game.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const Game();
    final c = j['counted'], gl = j['glances'], pa = j['patterns'], nc = j['nextCard'], di = j['diary'], rest = j['restSince'];
    final sh = j['shares'], fa = j['fairShares'];
    int? amount(dynamic k) {
      final n = k is String ? int.tryParse(k) : null;
      return n != null && n >= 1 && n <= 20 ? n : null;
    }

    final sharesN = sh is int && sh > 0 ? math.min(sh, _most) : 0;
    return Game(
      settings: Settings.fromJson(j['settings'] is Map ? (j['settings'] as Map).cast<String, dynamic>() : const {}),
      counted: {
        if (c is Map)
          for (final e in c.entries)
            if (amount(e.key) != null && e.value is int && (e.value as int) > 0) amount(e.key)!: math.min(_most, e.value as int),
      },
      glances: {
        if (gl is Map)
          for (final e in gl.entries)
            if (amount(e.key) != null) amount(e.key)!: Glance.fromJson(e.value),
      },
      shares: sharesN,
      fairShares: fa is int && fa > 0 ? math.min(fa, sharesN) : 0,
      patterns: {
        if (pa is List)
          for (final k in pa)
            if (k is String && const {'AB', 'AAB', 'ABB'}.contains(k)) k,
      },
      farm: Farm.fromJson(j['farm']),
      nextCard: {
        if (nc is Map)
          for (final p in Place.values)
            if (nc[p.name] is int && (nc[p.name] as int) >= 0) p: (nc[p.name] as int) % cardsOf(p).length,
      },
      diary: () {
        final list = [
          if (di is List)
            for (final e in di) ?DiaryEntry.fromJson(e),
        ];
        return list.skip(math.max(0, list.length - maxDiary)).toList();
      }(),
      today: DayLog.fromJson(j['today']),
      restSince: rest is String ? DateTime.tryParse(rest) : null,
    );
  }
}
