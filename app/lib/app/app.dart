import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/content.dart';
import '../core/game.dart';
import '../core/providers.dart';
import '../features/farm/farm_screen.dart';
import '../features/parent/parent_gate.dart';
import '../features/parent/parent_screen.dart';
import '../features/place/place_screen.dart';
import '../features/rest/rest_screen.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Every page there is.
final _pages = {'/', '/rest', '/parent', for (final p in Place.values) '/${p.name}'};

final routerProvider = Provider<GoRouter>((ref) {
  final resting = ref.read(gameProvider).resting(ref.read(clockProvider)());
  final router = GoRouter(
    initialLocation: resting ? '/rest' : '/',
    // Always start here, whatever page another app asks the phone to open.
    overridePlatformDefaultLocation: true,
    redirect: (_, state) {
      final at = state.uri.path;
      // A page that does not exist (a link from another app) is the farm.
      if (!_pages.contains(at)) return '/';
      if (at == '/parent') return ParentPass.take() ? null : '/';
      if (at == '/rest') return null;
      final place = Place.values.asNameMap()[at.substring(1)];
      // A place a parent turned off (or in the full version only) never opens.
      if (place != null && !ref.read(gameProvider).settings.enabled(place)) return '/';
      return null;
    },
    // The phone's back key never closes the app: on the farm and at the rest
    // it does nothing, anywhere else it goes to the farm (as the screen's
    // own home button does).
    routes: [
      GoRoute(path: '/', builder: (_, _) => const BackKey(child: FarmScreen())),
      for (final p in Place.values)
        GoRoute(path: '/${p.name}', builder: (context, s) => BackKey(onBack: () => GoRouter.of(context).go('/'), child: PlaceScreen(key: ValueKey(s.uri.toString()), place: p))),
      GoRoute(path: '/rest', builder: (_, _) => const BackKey(child: RestScreen())),
      // Parent mode closes by itself after five minutes without a touch.
      GoRoute(
        path: '/parent',
        builder: (context, _) {
          void home() => GoRouter.of(context).go('/');
          return BackKey(onBack: home, child: ParentIdle(onIdle: home, child: const ParentScreen()));
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class FarmApp extends ConsumerWidget {
  const FarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gameProvider.select((g) => g.settings));
    // Each switch silences only its own sound (the voice is checked in speak()).
    ref.read(soundsProvider)
      ..music = settings.music
      ..effects = settings.sounds;
    return MaterialApp.router(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: InkTheme.light(),
      locale: const Locale('zh', 'TW'),
      supportedLocales: const [Locale('zh', 'TW')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      builder: (_, child) => RestGuard(child: child ?? const SizedBox()),
    );
  }
}

/// Keeps the parent's play time (docs/design.md 「每次玩多久」): when the
/// sitting has gone on for the minutes they set, dusk falls on the farm and
/// the child is sent to count the spoons at home; an hour later (or when a
/// parent says so) play can go on. A round being played is finished first
/// (at most a minute more). Away from the app for ten minutes counts as a
/// rest, closed or in the background: the sitting is kept on the phone, so
/// the app closed and opened again goes on with it. Time on the parent gate,
/// in parent mode or in the background is not the child's play time, and a
/// phone clock moved back gives no extra time. Parent mode left in the
/// background is closed, so a child finds the farm. It also counts today's
/// minutes for parent mode.
class RestGuard extends ConsumerStatefulWidget {
  const RestGuard({super.key, required this.child});

  final Widget child;

  static const check = Duration(seconds: 2);
  static const awayIsRest = Sitting.goesOn;

  /// How long a round being played may go on after the time is up.
  static const finishRound = Duration(minutes: 1);

  /// Played seconds are saved this often.
  static const saveEvery = 30;

  @override
  ConsumerState<RestGuard> createState() => _RestGuardState();
}

class _RestGuardState extends ConsumerState<RestGuard> {
  Timer? _timer;
  AppLifecycleListener? _life;
  DateTime? _away;

  /// When parent mode was opened (its time is given back to the child).
  DateTime? _parentSince;

  /// The phone's clock at the last check (to see it moved back).
  DateTime? _last;
  var _unsaved = 0;

  @override
  void initState() {
    super.initState();
    ref.read(sessionStartProvider);
    parentGateShowing.addListener(_gate);
    _timer = Timer.periodic(RestGuard.check, (_) => _check());
    _life = AppLifecycleListener(
      onHide: () {
        _save();
        _away = ref.read(clockProvider)();
        // Parent mode is not left open for a child to find: the farm, and the
        // gate has to be answered again.
        final router = ref.read(routerProvider);
        if (router.state.matchedLocation.startsWith('/parent')) {
          ParentPass.take();
          router.go('/');
        }
      },
      onShow: () {
        final away = _away;
        _away = null;
        if (away != null) _back(away);
        _check();
      },
    );
  }

  /// Back from the background, gone since [away]: ten minutes or more is a
  /// rest (a new sitting); less is not the child's play time either, so the
  /// sitting goes on where it was (a clock moved back meanwhile makes
  /// [gone] negative and takes that back too).
  void _back(DateTime away) {
    final now = ref.read(clockProvider)();
    final gone = now.difference(away);
    _last = now;
    if (gone >= RestGuard.awayIsRest) {
      ref.read(sessionStartProvider.notifier).restart();
      if (_parentSince != null) _parentSince = now;
      return;
    }
    _moveSitting(gone);
  }

  /// Moves the sitting (and parent mode's start, so its time is not given
  /// back twice) by [d].
  void _moveSitting(Duration d) {
    ref.read(sessionStartProvider.notifier).shift(d);
    final p = _parentSince;
    if (p != null) _parentSince = p.add(d);
  }

  /// The parent gate's time is parent time from the moment it opens until
  /// it closes (unless it opened parent mode).
  void _gate() {
    if (_away != null) return;
    if (parentGateShowing.value > 0) {
      _parentSince ??= ref.read(clockProvider)();
      return;
    }
    // (The gate closes while the screens are being put up: just after.)
    Future.microtask(() {
      if (!mounted || _away != null || parentGateShowing.value > 0) return;
      if (ref.read(routerProvider).state.matchedLocation.startsWith('/parent')) return;
      _parentOver(ref.read(clockProvider)());
    });
  }

  /// Parent time is over: given back to the child.
  void _parentOver(DateTime now) {
    final parentSince = _parentSince;
    if (parentSince == null) return;
    _parentSince = null;
    final d = now.difference(parentSince);
    if (!d.isNegative) ref.read(sessionStartProvider.notifier).shift(d);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _life?.dispose();
    parentGateShowing.removeListener(_gate);
    super.dispose();
  }

  /// Saves the seconds played, and the sitting: how much play time it has
  /// used (parent mode's time not yet given back left out) and when.
  void _save() {
    final now = ref.read(clockProvider)();
    final s = _unsaved;
    _unsaved = 0;
    var used = now.difference(ref.read(sessionStartProvider));
    final p = _parentSince;
    if (p != null && now.isAfter(p)) used -= now.difference(p);
    final sitting = Sitting(used.isNegative ? Duration.zero : used, now);
    ref.read(gameProvider.notifier).change((g) {
      final played = s > 0 ? g.played(now, s) : g;
      // Resting: there is no sitting to go on with.
      return g.restSince != null ? played : played.copyWith(sitting: sitting);
    });
  }

  void _check() {
    // Nothing while the app is out of sight (its timer can go on in the
    // background): that time is not played, and it is given back on return.
    if (!mounted || _away != null) return;
    final now = ref.read(clockProvider)();
    // The phone's clock moved back: the sitting moves back with it.
    final last = _last;
    _last = now;
    if (last != null && now.isBefore(last)) _moveSitting(now.difference(last));
    final g = ref.read(gameProvider);
    final router = ref.read(routerProvider);
    final path = router.state.matchedLocation;
    // The parent gate (on top of the farm or the rest) is parent time too.
    final parent = path.startsWith('/parent') || parentGateShowing.value > 0;
    final playing = !parent && path != '/rest';
    if (playing) {
      _unsaved += RestGuard.check.inSeconds;
      if (_unsaved >= RestGuard.saveEvery) _save();
    }
    if (parent) {
      _parentSince ??= now;
      return;
    }
    _parentOver(now);
    if (g.restSince != null) {
      if (g.resting(now)) {
        if (path != '/rest') router.go('/rest');
        return;
      }
      ref.read(gameProvider.notifier).change((g) => g.playOn());
      ref.read(sessionStartProvider.notifier).restart();
      if (path == '/rest') router.go('/');
      return;
    }
    if (path == '/rest') return;
    final over = now.difference(ref.read(sessionStartProvider)) - Duration(minutes: g.settings.minutes);
    if (!over.isNegative) {
      // A round being played is finished first (at most a minute more).
      if (ref.read(roundBusyProvider).busy && over < RestGuard.finishRound) return;
      _save();
      ref.read(gameProvider.notifier).change((g) => g.rest(now));
      router.go('/rest');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
