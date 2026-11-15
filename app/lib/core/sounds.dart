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

/// Plays through audioplayers: a pool per sound, one looping player for the
/// music; quiet while the app is in the background.
class SystemSounds implements Sounds {
  SystemSounds() {
    _lifecycle = AppLifecycleListener(onHide: () => _setAway(true), onShow: () => _setAway(false));
  }

  static const _sfxVolume = 0.85, _musicVolume = 0.35;

  late final AppLifecycleListener _lifecycle;
  final _pools = <String, Future<AudioPool>>{};
  final _holders = MusicHolders();
  Future<void>? _setUp;
  AudioPlayer? _loop;
  Music? _playing;
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

  Future<void> _ready() => _setUp ??= AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: true).build(),
      );

  @override
  void play(String sfx) {
    if (!_effects || _away || sfx.isEmpty) return;
    unawaited(_play(sfx));
  }

  Future<void> _play(String sfx) async {
    try {
      await _ready();
      final pool = await (_pools[sfx] ??= AudioPool.createFromAsset(path: 'sounds/$sfx.wav', maxPlayers: 4));
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
    unawaited(_switchTo(wanted));
  }

  Future<void> _switchTo(Music? music) async {
    try {
      await _ready();
      var loop = _loop;
      if (loop == null) {
        loop = _loop = AudioPlayer();
        await loop.setReleaseMode(ReleaseMode.loop);
      }
      await loop.stop();
      if (music == null || music != _playing) return;
      await loop.setVolume(_musicVolume);
      await loop.play(AssetSource('sounds/${music.file}.wav'));
    } catch (_) {}
  }

  void dispose() {
    _lifecycle.dispose();
    unawaited(_loop?.dispose());
  }
}
