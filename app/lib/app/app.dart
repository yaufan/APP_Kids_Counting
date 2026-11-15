import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/content.dart';
import '../core/providers.dart';
import '../features/farm/farm_screen.dart';
import '../features/parent/parent_gate.dart';
import '../features/parent/parent_screen.dart';
import '../features/place/place_screen.dart';
import '../features/rest/rest_screen.dart';
import 'strings.dart';
import 'theme.dart';

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
    routes: [
      GoRoute(path: '/', builder: (_, _) => const FarmScreen()),
      for (final p in Place.values) GoRoute(path: '/${p.name}', builder: (_, s) => PlaceScreen(key: ValueKey(s.uri.toString()), place: p)),
      GoRoute(path: '/rest', builder: (_, _) => const RestScreen()),
      GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
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
/// rest; time in parent mode or in the background is not the child's play
/// time. It also counts today's minutes for parent mode.
class RestGuard extends ConsumerStatefulWidget {
  const RestGuard({super.key, required this.child});

  final Widget child;

  static const check = Duration(seconds: 2);
  static const awayIsRest = Duration(minutes: 10);

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
  var _unsaved = 0;

  @override
  void initState() {
    super.initState();
    ref.read(sessionStartProvider);
    _timer = Timer.periodic(RestGuard.check, (_) => _check());
    _life = AppLifecycleListener(
      onHide: () {
        _save();
        _away = ref.read(clockProvider)();
      },
      onShow: () {
        final away = _away;
        _away = null;
        if (away != null && ref.read(clockProvider)().difference(away) >= RestGuard.awayIsRest) ref.read(sessionStartProvider.notifier).restart();
        _check();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _life?.dispose();
    super.dispose();
  }

  void _save() {
    if (_unsaved <= 0) return;
    final s = _unsaved;
    _unsaved = 0;
    ref.read(gameProvider.notifier).change((g) => g.played(ref.read(clockProvider)(), s));
  }

  void _check() {
    if (!mounted) return;
    final now = ref.read(clockProvider)();
    final g = ref.read(gameProvider);
    final router = ref.read(routerProvider);
    final path = router.state.matchedLocation;
    // Not while the app is out of sight (its timer can go on in the background).
    final playing = _away == null && !path.startsWith('/parent') && path != '/rest';
    if (playing) {
      _unsaved += RestGuard.check.inSeconds;
      if (_unsaved >= RestGuard.saveEvery) _save();
    }
    if (path.startsWith('/parent')) {
      _parentSince ??= now;
      return;
    }
    final parentSince = _parentSince;
    if (parentSince != null) {
      _parentSince = null;
      ref.read(sessionStartProvider.notifier).pause(now.difference(parentSince));
    }
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
