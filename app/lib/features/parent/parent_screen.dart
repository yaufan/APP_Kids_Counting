import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/version.dart';
import '../../app/widgets.dart';
import '../../core/content.dart';
import '../../core/game.dart';
import '../../core/providers.dart';

/// Parent mode (after the gate, docs/design.md 「家長模式」): the level, how
/// far it counts, the play time, the places, the number sentence, the cards
/// and 阿嬤's help, the sounds; what was counted and seen at a glance; the
/// 農場日記 to tick; the full version.
class ParentScreen extends ConsumerWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gameProvider);
    final s = g.settings;
    final game = ref.read(gameProvider.notifier);
    final now = ref.read(clockProvider)();

    Widget section(String title, List<Widget> children, {Key? key}) => Padding(
          key: key,
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 15, color: Inks.inkSoft, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...children,
              ]),
            ),
          ),
        );

    Widget toggle(String label, bool value, void Function(bool)? set, {Key? key, String? note}) => SwitchListTile(
          key: key,
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: const TextStyle(fontSize: 17)),
          subtitle: note == null ? null : Text(note, style: const TextStyle(fontSize: 13, color: Inks.inkSoft)),
          value: value,
          onChanged: set,
        );

    Widget chips<T>(List<T> values, T selected, String Function(T) label, void Function(T) pick, String keyOf) => Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in values)
            ChoiceChip(
              key: ValueKey('$keyOf-${v is Enum ? v.name : v}'),
              label: Text(label(v), style: const TextStyle(fontSize: 16)),
              selected: v == selected,
              onSelected: (_) => pick(v),
              selectedColor: const Color(0xFFF6D9A8),
              showCheckmark: false,
            ),
        ]);

    const note = TextStyle(fontSize: 14, height: 1.5, color: Inks.inkSoft);
    final log = g.log(now);

    return Scaffold(
      backgroundColor: Inks.parentBg,
      appBar: AppBar(
        backgroundColor: Inks.parentBg,
        title: const Text(Strings.parentTitle),
        leading: IconButton(icon: const Icon(Icons.close_rounded), tooltip: Strings.back, onPressed: () => context.go('/')),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        section(Strings.levelTitle, [
          chips(Level.values, s.level, Strings.levelLine, (v) => game.settings((x) => x.copyWith(level: v)), 'level'),
          const SizedBox(height: 10),
          const Text(Strings.levelNote, style: note),
          const SizedBox(height: 12),
          const Text(Strings.countTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          chips<int?>(const [null, 5, 10], s.countTo, Strings.countLine, (v) => game.settings((x) => v == null ? x.copyWith(byLevel: true) : x.copyWith(countTo: v)), 'count'),
          const SizedBox(height: 6),
          const Text(Strings.countNote, style: note),
        ]),
        section(Strings.playTime, [
          chips(Settings.minuteChoices, s.minutes, Strings.minutes, (v) => game.settings((x) => x.copyWith(minutes: v)), 'minutes'),
          const SizedBox(height: 10),
          const Text(Strings.playTimeNote, style: note),
          if (g.resting(now)) ...[
            const SizedBox(height: 10),
            const Text(Strings.resting, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            FilledButton(
              key: const ValueKey('play-on'),
              onPressed: () {
                game.change((g) => g.playOn());
                ref.read(sessionStartProvider.notifier).restart();
                context.go('/');
              },
              child: const Text(Strings.playOn),
            ),
          ],
        ]),
        section(Strings.placesTitle, [
          const Text(Strings.placesNote, style: note),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final p in Place.values)
              FilterChip(
                key: ValueKey('place-on-${p.name}'),
                avatar: s.open(p) ? null : const Icon(Icons.lock_rounded, size: 16),
                label: Text(p.zh, style: const TextStyle(fontSize: 16)),
                selected: s.places.contains(p),
                onSelected: (on) => game.settings((x) => x.copyWith(places: on ? {...x.places, p} : ({...x.places}..remove(p)))),
                selectedColor: const Color(0xFFDCE8C8),
              ),
          ]),
        ]),
        section(Strings.helpTitle, [
          toggle(Strings.sentences, s.sentences, (v) => game.settings((x) => x.copyWith(sentences: v)), key: const ValueKey('sentences'), note: Strings.sentencesNote),
          toggle(Strings.cards, s.cards, (v) => game.settings((x) => x.copyWith(cards: v)), key: const ValueKey('cards'), note: Strings.cardsNote),
          toggle(Strings.hints, s.hints, (v) => game.settings((x) => x.copyWith(hints: v)), key: const ValueKey('hints'), note: Strings.hintsNote),
        ]),
        section(Strings.soundTitle, [
          toggle(Strings.voice, s.voice, (v) => game.settings((x) => x.copyWith(voice: v)), key: const ValueKey('voice')),
          toggle(Strings.slow, s.slow, (v) => game.settings((x) => x.copyWith(slow: v)), key: const ValueKey('slow')),
          toggle(Strings.music, s.music, (v) => game.settings((x) => x.copyWith(music: v)), key: const ValueKey('music')),
          toggle(Strings.effects, s.sounds, (v) => game.settings((x) => x.copyWith(sounds: v)), key: const ValueKey('effects')),
        ]),
        section(Strings.progressTitle, [
          Text(Strings.today(log.seconds ~/ 60, [for (final p in Place.values) if (log.places.contains(p)) p]), style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(Strings.farmLine(g.farm.chicks, g.farm.veg, g.farm.fruit), style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          const Text(Strings.countedTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _Counted(game: g),
          const SizedBox(height: 4),
          const Text(Strings.countedNote, style: note),
          const SizedBox(height: 12),
          const Text(Strings.glanceTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (var n = 1; n <= 10; n++)
              if (g.glances[n] case final gl? when gl.asked > 0)
                Container(
                  key: ValueKey('glance-$n'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Inks.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: Inks.line)),
                  child: Text('$n：${gl.right}／${gl.asked}', style: const TextStyle(fontSize: 15)),
                ),
            if (g.glances.isEmpty) const Text('—', style: note),
          ]),
          const SizedBox(height: 12),
          Text(Strings.shareLine(g.fairShares, g.shares), style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(Strings.patternLine(g.patterns), style: const TextStyle(fontSize: 16)),
        ]),
        section(Strings.diaryTitle, key: const ValueKey('diary'), [
          if (g.diary.isEmpty) const Text(Strings.diaryEmpty, style: note),
          for (var i = g.diary.length - 1; i >= 0 && i >= g.diary.length - 20; i--)
            if (cardById(g.diary[i].card) case final card?)
              CheckboxListTile(
                key: ValueKey('diary-$i'),
                contentPadding: EdgeInsets.zero,
                value: g.diary[i].done,
                onChanged: (v) => game.change((x) => x.tick(i, v ?? false)),
                secondary: SizedBox(width: 40, height: 40, child: Art(card.picture)),
                title: Text(card.text, style: const TextStyle(fontSize: 15, height: 1.4)),
                subtitle: Text('${g.diary[i].day}・${card.place.zh}', style: const TextStyle(fontSize: 12, color: Inks.inkSoft)),
              ),
        ]),
        section(Strings.fullVersion, [
          const Text(Strings.fullNote, style: note),
          toggle(Strings.fullSwitch, s.full, (v) => game.settings((x) => x.copyWith(full: v)), key: const ValueKey('full')),
        ]),
        section(Strings.about, [
          const Text(Strings.privacy, style: TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 6),
          Text(Strings.version(appVersion), style: note),
        ]),
      ]),
    );
  }
}

/// 1 to 10, darker the more often that amount was counted to the end.
class _Counted extends StatelessWidget {
  const _Counted({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final most = [for (var n = 1; n <= 10; n++) game.counted[n] ?? 0].fold(0, (a, b) => a > b ? a : b);
    return Wrap(spacing: 5, runSpacing: 6, children: [
      for (var n = 1; n <= 10; n++)
        () {
          final c = game.counted[n] ?? 0;
          final t = most == 0 ? 0.0 : (c / most).clamp(0.0, 1.0);
          final fill = c == 0 ? const Color(0xFFEDE7DC) : Color.lerp(const Color(0xFFF7DDB4), Inks.orange, t)!;
          return Container(
            key: ValueKey('counted-$n'),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(10), border: Border.all(color: Inks.line, width: 1.5)),
            child: Text('$n', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t > .6 ? Colors.white : Inks.ink)),
          );
        }(),
    ]);
  }
}
