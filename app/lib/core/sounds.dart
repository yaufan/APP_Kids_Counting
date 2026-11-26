import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'content.dart';

/// The music (design/sounds/make_sounds.py): a bouncy xylophone and recorder
/// tune for the farm, a clucky one for the hen house (餵小雞, 撿雞蛋), a sunny
/// one for the orchard (摘水果, 分點心), a clapping beat for the vegetable
/// patch (排排隊), a busy one for the market and a lullaby for the rest.
enum Music {
  farm('music_farm'),
  coop('music_coop'),
  orchard('music_orchard'),
  garden('music_garden'),
  market('music_market'),
  rest('music_rest');

  const Music(this.file);

  final String file;

  static Music of(Place p) => switch (p) {
        Place.chicks || Place.eggs => Music.coop,
        Place.fruit || Place.share => Music.orchard,
        Place.garden => Music.garden,
        Place.market => Music.market,
      };
}

/// The rising note of each number counted (1 is the lowest), up the
/// pentatonic scale like climbing stairs: count_1 … count_10.
String countNote(int n) => 'count_${n.clamp(1, 10)}';

/// Short sounds are named by their file in assets/sounds/ (design/sounds/README.md lists them).
abstract interface class Sounds {
  set music(bool on);
  set effects(bool on);

  void play(String sfx);

  /// [owner] (a screen) wants [music]; the one asked for last plays.
  void hold(Object owner, Music? music);

  void release(Object owner);
}

class MusicHolders {
  final _holders = <Object, Music?>{};

  void hold(Object owner, Music? music) {
    _holders.remove(owner);
    _holders[owner] = music;
  }

  void release(Object owner) => _holders.remove(owner);

  Music? get current => _holders.isEmpty ? null : _holders.values.last;
}

class SilentSounds implements Sounds {
  const SilentSounds();

  @override
  set music(bool on) {}

  @override
  set effects(bool on) {}

  @override
  void play(String sfx) {}

  @override
  void hold(Object owner, Music? music) {}

  @override
  void release(Object owner) {}
}

/// Remembers the sounds played (tests), keeping to the two switches like
/// the real thing: effects off plays nothing, music off holds no music.
class RecordingSounds implements Sounds {
  final played = <String>[];
  final _holders = MusicHolders();
  var musicOn = true, effectsOn = true;

  Music? get music => musicOn ? _holders.current : null;

  @override
  set music(bool on) => musicOn = on;

  @override
  set effects(bool on) => effectsOn = on;

  @override
  void play(String sfx) {
    if (effectsOn) played.add(sfx);
  }

  @override
  void hold(Object owner, Music? music) => _holders.hold(owner, music);

  @override
  void release(Object owner) => _holders.release(owner);
}

/// How every sound plays: on Android the media stream (the media volume,
/// heard with the phone on vibrate or silent like the voice), never taking
/// the audio focus, so sounds never stop one another or the voice; on
/// iPhone a mixing 「ambient」 session as before.
final soundContext = AudioContext(
  android: const AudioContextAndroid(
    usageType: AndroidUsageType.media,
    contentType: AndroidContentType.music,
    audioFocus: AndroidAudioFocus.none,
  ),
  iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
);

/// The player the music loops on (a slow stand-in in the tests).
abstract interface class MusicLoop {
  Future<void> stop();
  Future<void> play(String file, double volume);
}

/// Plays through audioplayers: a pool per sound, one looping player for the
/// music; quiet while the app is in the background.
class SystemSounds implements Sounds {
  SystemSounds({MusicLoop? loop}) {
    _loop = loop ?? _PlayerLoop(_ready);
    _lifecycle = AppLifecycleListener(onHide: () => _setAway(true), onShow: () => _setAway(false));
  }

  static const _sfxVolume = 0.85, _musicVolume = 0.35;

  late final AppLifecycleListener _lifecycle;
  late final MusicLoop _loop;
  final _pools = <String, Future<AudioPool>>{};
  final _holders = MusicHolders();
  Future<void>? _setUp;

  /// The music wanted now, and the music the loop was last started with.
  Music? _playing, _sounding;

  /// Switches of the music, one after the other: a stop asked for while a
  /// start is still loading waits for it, so the wrong tune never plays and
  /// the music never starts after it was stopped (a quick change of screen,
  /// the app hidden).
  Future<void> _switching = Future.value();
  var _music = true, _effects = true, _away = false;

  @override
  set music(bool on) {
    _music = on;
    _update();
  }

  @override
  set effects(bool on) => _effects = on;

  void _setAway(bool away) {
    _away = away;
    _update();
  }

  Future<void> _ready() => _setUp ??= AudioPlayer.global.setAudioContext(soundContext);

  @override
  void play(String sfx) {
    if (!_effects || _away || sfx.isEmpty) return;
    unawaited(_play(sfx));
  }

  Future<void> _play(String sfx) async {
    try {
      await _ready();
      final pool = await (_pools[sfx] ??= AudioPool.create(source: AssetSource('sounds/$sfx.wav'), maxPlayers: 4, audioContext: soundContext));
      await pool.start(volume: _sfxVolume);
    } catch (_) {
      _pools.remove(sfx);
    }
  }

  @override
  void hold(Object owner, Music? music) {
    _holders.hold(owner, music);
    _update();
  }

  @override
  void release(Object owner) {
    _holders.release(owner);
    _update();
  }

  void _update() {
    final wanted = !_music || _away ? null : _holders.current;
    if (wanted == _playing) return;
    _playing = wanted;
    _switching = _switching.then((_) => _apply());
  }

  /// Makes the loop play what is wanted now (a later wish queues another).
  Future<void> _apply() async {
    final music = _playing;
    if (music == _sounding) return;
    try {
      await _loop.stop();
      _sounding = null;
      if (music == null) return;
      await _loop.play(music.file, _musicVolume);
      _sounding = music;
    } catch (_) {
      _sounding = null;
    }
  }

  void dispose() {
    _lifecycle.dispose();
    final loop = _loop;
    if (loop is _PlayerLoop) loop.dispose();
  }
}

class _PlayerLoop implements MusicLoop {
  _PlayerLoop(this._ready);

  final Future<void> Function() _ready;
  AudioPlayer? _player;

  Future<AudioPlayer> _get() async {
    await _ready();
    var p = _player;
    if (p == null) {
      p = _player = AudioPlayer();
      await p.setAudioContext(soundContext);
      await p.setReleaseMode(ReleaseMode.loop);
    }
    return p;
  }

  @override
  Future<void> stop() async => (await _get()).stop();

  @override
  Future<void> play(String file, double volume) async {
    final p = await _get();
    await p.setVolume(volume);
    await p.play(AssetSource('sounds/$file.wav'));
  }

  void dispose() => unawaited(_player?.dispose());
}
