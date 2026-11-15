"""數數小農場: every sound in the app, made here from sine waves and noise: nothing recorded, nothing
downloaded, every tune written for this app.

- Music (WAV, 16,000 Hz, seamless loops of 20 to 28 s): a bouncy xylophone and recorder tune for the
  farm, a clucky one for the hen house (餵小雞, 撿雞蛋), a sunny one for the orchard (摘水果, 分點心), a
  clapping beat for the vegetable patch (排排隊: 咚、啪), a busy one for the market and a music-box
  lullaby for the rest.
- The counting notes count_1 … count_10: one wooden xylophone note per number, up the pentatonic scale
  like climbing stairs (1 is Do), so a child hears 「越數越多」; count_all is the little rising chord at
  the end of a count.
- The animals (a chick's 「啾」 and its puzzled 「啾？」, the hen's 「咯咯」, the piglet's 「齁齁」, the
  sheep's 「咩」, the duck's 「呱呱」, the rabbit's sniff, 牛牛's low, gentle 「哞～」) and every action (corn
  hopping 「啵」, an egg in the box 「叩」, fruit in the basket 「咚」, a snack on a plate 「嗒」, planting
  「沙沙」, a melon on the truck, the horn 「叭叭」, the engine 「噗噗噗」, the market bell, the stamp
  「啪」, an egg hopping back 「咻～」, a crooked vegetable 「啵嚶」, the round done, a card, night).
- No error sound (docs/design.md 「做錯的時候」): a miss is only a funny sound.
- Every random choice uses a fixed seed (from the sound's name), so each run writes the same files.

    python3 design/sounds/make_sounds.py              # writes app/assets/sounds/*.wav
    python3 design/sounds/make_sounds.py tap moo      # only these
    python3 design/sounds/make_sounds.py preview OUT.m4a   # all of them in a row (needs ffmpeg)
"""
import pathlib
import subprocess
import sys
import tempfile
import wave
import zlib

import numpy as np
from scipy.signal import lfilter

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "assets" / "sounds"
SR = 22050
LOOP_SR = 16000
LIMIT = 6_000_000       # bytes, the whole folder

NOTE = {f"{n}{o}": 440 * 2 ** ((k - 9) / 12 + o - 4) for o in range(1, 9) for k, n in enumerate("C C# D D# E F F# G G# A A# B".split())}
for _o in range(1, 9):
    for _f, _s in (("Db", "C#"), ("Eb", "D#"), ("Gb", "F#"), ("Ab", "G#"), ("Bb", "A#")):
        NOTE[f"{_f}{_o}"] = NOTE[f"{_s}{_o}"]


# ---------------------------------------------------------------- helpers
def rng(name):
    return np.random.default_rng(zlib.crc32(name.encode()))


def t_of(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def env(n, attack=.005, release=.05, sr=SR):
    e = np.ones(n)
    a, r = max(1, min(n, int(attack * sr))), max(1, min(n, int(release * sr)))
    e[:a] = np.linspace(0, 1, a) ** 2
    e[-r:] *= np.linspace(1, 0, r) ** 2
    return e


def adsr(n, a, d, s, r, sr=SR):
    """Attack, decay to sustain level s, release (seconds)."""
    e = np.full(n, s, float)
    ia, idd, ir = int(a * sr), int(d * sr), int(r * sr)
    ia = max(1, min(ia, n))
    e[:ia] = np.linspace(0, 1, ia)
    j = min(n, ia + idd)
    if j > ia:
        e[ia:j] = np.linspace(1, s, j - ia)
    ir = max(1, min(ir, n))
    e[-ir:] *= np.linspace(1, 0, ir) ** 1.5
    return e


def lowpass(x, cutoff, sr=SR):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    spec *= 1 / (1 + (f / cutoff) ** 4)
    return np.fft.irfft(spec, len(x))


def bandpass(x, lo, hi, sr=SR):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    spec *= 1 / (1 + (lo / np.maximum(f, 1)) ** 4) / (1 + (f / hi) ** 4)
    return np.fft.irfft(spec, len(x))


def partial(freq, t, sr):
    return np.sin(2 * np.pi * freq * t) if freq < .45 * sr else np.zeros_like(t)


def bell(freq, dur=.8, sr=SR, bright=.6):
    """A soft glockenspiel / music-box note."""
    t = t_of(dur, sr)
    x = (partial(freq, t, sr) * np.exp(-t / (dur * .35))
         + .3 * bright * partial(freq * 2.76, t, sr) * np.exp(-t / (dur * .12))
         + .12 * bright * partial(freq * 5.4, t, sr) * np.exp(-t / (dur * .06)))
    return x * env(len(t), .002, .04, sr)


def kalimba(freq, dur=.9, sr=SR):
    t = t_of(dur, sr)
    x = partial(freq, t, sr) * np.exp(-t / (dur * .3)) + .25 * partial(freq * 3.0, t, sr) * np.exp(-t / .04) + .1 * partial(freq * 5.2, t, sr) * np.exp(-t / .02)
    return x * env(len(t), .003, .05, sr)


def pad(freqs, dur, sr=SR, swell=.6):
    """A soft, slowly swelling chord (a few detuned sines)."""
    t = t_of(dur, sr)
    x = np.zeros_like(t)
    for f in freqs:
        for det in (-.15, .15):
            x += np.sin(2 * np.pi * (f + det) * t) + .25 * partial(2 * f + det, t, sr)
    return x / len(freqs) * adsr(len(t), dur * swell * .5, .1, .9, dur * .45, sr)


def place(total, parts, sr=SR):
    out = np.zeros(int(total * sr))
    for start, sig in parts:
        i = int(start * sr)
        j = min(len(out), i + len(sig))
        if j > i:
            out[i:j] += sig[: j - i]
    return out


def place_loop(total, parts, sr):
    """Like place, but what runs past the end comes back in at the start (a seamless loop)."""
    n = int(total * sr)
    out = np.zeros(n)
    for start, sig in parts:
        i = int(start * sr) % n
        k = 0
        while k < len(sig):
            j = min(n, i + len(sig) - k)
            out[i:j] += sig[k: k + j - i]
            k += j - i
            i = 0
    return out


def resonator(x, freq, bw, sr=SR):
    r = np.exp(-np.pi * bw / sr)
    th = 2 * np.pi * freq / sr
    return lfilter([1 - r], [1, -2 * r * np.cos(th), r * r], x)


def voice(f0, formants, dur, sr=SR, breath=.15, seed="v"):
    """A soft little hum: a buzz whose pitch follows f0 (an array or a number) through formants."""
    n = int(dur * sr)
    f = np.full(n, f0, float) if np.isscalar(f0) else np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(f0)), f0)
    ph = np.cumsum(f) / sr
    buzz = sum(np.sin(2 * np.pi * k * ph) / k ** 1.2 for k in range(1, 14) if True)
    buzz = buzz + breath * rng(seed).standard_normal(n)
    y = sum(g * resonator(buzz, fr, bw, sr) for fr, bw, g in formants)
    return y / max(1e-9, np.abs(y).max())


VOWEL_M = [(300, 90, 1.0), (900, 160, .25), (2300, 220, .08)]      # a closed-mouth "mmm"
VOWEL_U = [(330, 90, 1.0), (850, 140, .3), (2250, 200, .1)]        # "uu"
VOWEL_A = [(750, 110, 1.0), (1200, 130, .6), (2500, 200, .2)]      # "aa"
VOWEL_E = [(450, 100, 1.0), (1900, 160, .4), (2600, 220, .15)]     # "eh"


def noise(n, name):
    return rng(name).standard_normal(n)


def norm(x, peak=.7):
    return x / max(1e-9, np.abs(x).max()) * peak


def fade_edges(x, sr=SR, ms=6):
    k = max(1, int(sr * ms / 1000))
    x = x.copy()
    x[:k] *= np.linspace(0, 1, k)
    x[-k:] *= np.linspace(1, 0, k)
    return x


# ---------------------------------------------------------------- instruments
def xylo(freq, dur=.5, sr=SR):
    """A wooden xylophone / marimba bar: a quick, woody decay."""
    t = t_of(dur, sr)
    x = (partial(freq, t, sr) * np.exp(-t / .16) + .35 * partial(freq * 3.93, t, sr) * np.exp(-t / .035)
         + .1 * partial(freq * 9.2, t, sr) * np.exp(-t / .012))
    return x * env(len(t), .002, .03, sr)


def harmonica(freq, dur=.5, sr=SR):
    """A soft reed: odd and even harmonics, a little vibrato, breathy."""
    t = t_of(dur, sr)
    vib = 1 + .006 * np.sin(2 * np.pi * 5.5 * t) * np.clip(t / .15, 0, 1)
    ph = np.cumsum(freq * vib) / sr
    x = sum((.9 ** k) / k * np.sin(2 * np.pi * k * ph) for k in range(1, 8) if k * freq < .45 * sr)
    x = lowpass(x + .04 * rng(f"harm{freq:.0f}").standard_normal(len(t)), 2600, sr)
    return x * adsr(len(t), .03, .08, .75, min(.12, dur * .4), sr)


def piano(freq, dur=1.2, sr=SR):
    """A soft piano-like note."""
    t = t_of(dur, sr)
    x = (partial(freq, t, sr) * np.exp(-t / .7) + .4 * partial(freq * 2.001, t, sr) * np.exp(-t / .35)
         + .15 * partial(freq * 3.003, t, sr) * np.exp(-t / .18) + .06 * partial(freq * 4.01, t, sr) * np.exp(-t / .1))
    return x * env(len(t), .004, .08, sr)


def knock(dur, f, name, sr=SR, decay=.02, cut=1400):
    """A dull wooden knock (a toy's click)."""
    t = t_of(dur, sr)
    x = lowpass(noise(len(t), name), cut, sr) * np.exp(-t / decay) * .7 + np.sin(2 * np.pi * f * t) * np.exp(-t / (decay * 1.4))
    return x


def recorder(freq, dur=.5, sr=SR):
    """A soft recorder (直笛): almost a sine, a breath at the start, a little vibrato."""
    t = t_of(dur, sr)
    vib = 1 + .005 * np.sin(2 * np.pi * 5 * t) * np.clip(t / .2, 0, 1)
    ph = np.cumsum(freq * vib) / sr
    x = np.sin(2 * np.pi * ph) + .12 * np.sin(4 * np.pi * ph) + .05 * np.sin(6 * np.pi * ph)
    x += .05 * lowpass(rng(f"rec{freq:.0f}").standard_normal(len(t)), 3000, sr) * np.exp(-t / .05)
    return x * adsr(len(t), .025, .06, .8, min(.1, dur * .4), sr)


def chirp(f0, f1, dur, name, sr=SR, wobble=0.0):
    """A little bird-like sweep (a chick's 啾)."""
    t = t_of(dur, sr)
    f = np.linspace(f0, f1, len(t)) * (1 + wobble * np.sin(2 * np.pi * 30 * t))
    x = np.sin(2 * np.pi * np.cumsum(f) / sr) + .2 * np.sin(4 * np.pi * np.cumsum(f) / sr)
    return x * np.sin(np.pi * t / dur) ** 1.5


# The pentatonic stairs for the numbers: Do Re Mi So La, then up an octave.
STAIRS = ["C5", "D5", "E5", "G5", "A5", "C6", "D6", "E6", "G6", "A6"]


# ---------------------------------------------------------------- the short sounds
def s_tap():
    n = int(.13 * SR)
    x = lowpass(noise(n, "tap"), 900) * np.exp(-t_of(.13) / .025) * .6 + np.sin(2 * np.pi * 180 * t_of(.13)) * np.exp(-t_of(.13) / .03)
    return norm(x, .5)


def count_note(k):
    def f():
        return norm(place(.55, [(0, xylo(NOTE[STAIRS[k - 1]], .55)), (0, .25 * xylo(NOTE[STAIRS[k - 1]] * 2, .3))]), .55)
    f.__name__ = f"s_count_{k}"
    return f


def s_count_all():
    """The end of a count: a little rising chord, 「一共……！」"""
    return norm(place(1.2, [(0, xylo(NOTE["C5"])), (.08, xylo(NOTE["E5"])), (.16, xylo(NOTE["G5"])), (.26, bell(NOTE["C6"], .9, bright=.4)),
                            (.26, .5 * xylo(NOTE["E6"], .8))]), .55)


def s_pop():
    """Corn hopping out of the bucket: 「啵」."""
    t = t_of(.16)
    f = np.linspace(500, 1100, len(t))
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / .04)
    return norm(x, .55)


def s_cheep():
    """A happy chick: 「啾啾」."""
    return norm(place(.4, [(0, chirp(2600, 3400, .1, "c1")), (.14, chirp(2800, 3600, .12, "c2"))]), .45)


def s_cheep_q():
    """A puzzled chick, 「啾？」 (I've eaten already): one chirp bending up."""
    return norm(place(.45, [(0, chirp(2400, 2300, .08, "q1")), (.12, chirp(2300, 3800, .22, "q2"))]), .42)


def s_cluck():
    """The hen: 「咯咯咯」."""
    parts = []
    for i in range(3):
        v = voice([420, 520, 380], [(700, 120, 1.0), (1300, 160, .5), (2600, 240, .15)], .11, seed=f"cluck{i}")
        parts.append((i * .14, v * env(len(v), .005, .04)))
    return norm(place(.5, parts), .45)


def s_oink():
    """A piglet's soft 「齁齁」: a nasal grunt, twice."""
    parts = []
    for i in range(2):
        v = voice([150, 190, 130], [(500, 90, 1.0), (1000, 120, .5), (2400, 220, .1)], .2, breath=.4, seed=f"oink{i}")
        parts.append((i * .26, v * env(len(v), .01, .06)))
    return norm(place(.55, parts), .42)


def s_baa():
    """The sheep: 「咩～」, a wavering bleat."""
    f0 = 330 + 40 * np.sin(np.linspace(0, 2 * np.pi * 7, 60))
    v = voice(f0, [(650, 110, 1.0), (1700, 160, .5), (2600, 220, .2)], .6, breath=.25, seed="baa")
    return norm(v * adsr(len(v), .04, .1, .8, .2), .42)


def s_quack():
    """The duck: 「呱呱」."""
    parts = []
    for i in range(2):
        v = voice([300, 260], [(900, 200, 1.0), (1500, 220, .7), (2700, 300, .3)], .14, breath=.5, seed=f"quack{i}")
        parts.append((i * .2, v * env(len(v), .005, .04)))
    return norm(place(.45, parts), .42)


def s_sniff():
    """The rabbit: three little sniffs."""
    one = lambda k: bandpass(noise(int(.07 * SR), f"sniff{k}"), 1500, 5000) * np.sin(np.pi * t_of(.07) / .07) ** 2
    return norm(place(.4, [(0, one(0)), (.11, one(1)), (.22, one(2))]), .3)


def s_moo():
    """牛牛: a low, gentle 「哞～」."""
    f0 = np.concatenate([np.linspace(130, 150, 20), np.linspace(150, 120, 40)])
    v = voice(f0, VOWEL_U, 1.1, breath=.2, seed="moo")
    return norm(v * adsr(len(v), .12, .2, .8, .35), .45)


def s_knock():
    """An egg set in the wooden box: 「叩」."""
    return norm(knock(.2, 520, "egg", decay=.025, cut=2200) + .5 * xylo(NOTE["G5"], .2), .5)


def s_thud():
    """A fruit landing in the basket: 「咚」."""
    t = t_of(.25)
    x = np.sin(2 * np.pi * np.cumsum(np.linspace(220, 140, len(t))) / SR) * np.exp(-t / .07) + .3 * lowpass(noise(len(t), "thud"), 800) * np.exp(-t / .03)
    return norm(x, .55)


def s_tick():
    """A snack set on a plate: 「嗒」."""
    t = t_of(.18)
    x = bell(NOTE["E6"], .18, bright=.2) * .4 + knock(.18, 700, "plate", decay=.012, cut=3000)
    return norm(x, .45)


def s_rustle():
    """Planting: 「沙沙」, soil and leaves."""
    one = lambda k: bandpass(noise(int(.18 * SR), f"rustle{k}"), 1200, 6000) * np.sin(np.pi * t_of(.18) / .18) ** 2
    return norm(place(.45, [(0, one(0)), (.22, .8 * one(1))]) + .4 * place(.45, [(.3, xylo(NOTE["C6"], .15))]), .4)


def s_plonk():
    """A melon on the truck: 「咚咚」, round and heavy."""
    t = t_of(.3)
    one = np.sin(2 * np.pi * np.cumsum(np.linspace(160, 110, len(t))) / SR) * np.exp(-t / .09)
    return norm(place(.5, [(0, one), (.16, .45 * one)]), .55)


def s_honk():
    """The truck's horn: 「叭叭」, two friendly toots."""
    def toot(d):
        t = t_of(d)
        x = sum(np.sign(np.sin(2 * np.pi * f * t)) * .5 + np.sin(2 * np.pi * f * t) for f in (NOTE["E4"], NOTE["G#4"]))
        return lowpass(x, 1800) * adsr(len(t), .01, .03, .9, .04)
    return norm(place(.6, [(0, toot(.18)), (.26, toot(.26))]), .45)


def s_engine():
    """The engine starting and driving off: 「噗噗噗」."""
    parts = []
    for i in range(9):
        t = t_of(.09)
        p = lowpass(noise(len(t), f"eng{i % 3}"), 500) * np.sin(np.pi * t / .09) ** 2 + .6 * np.sin(2 * np.pi * 70 * t) * np.exp(-t / .05)
        parts.append((i * (.13 - i * .006), p * (1 - i * .07)))
    return norm(place(1.2, parts), .45)


def s_bell():
    """The market's little bell: 「叮鈴」."""
    return norm(place(.9, [(0, bell(NOTE["A6"], .6, bright=.6)), (.1, bell(NOTE["E7"], .5, bright=.5)), (.2, .7 * bell(NOTE["A6"], .5))]), .45)


def s_stamp():
    """The order stamped 「好了」: 「啪」."""
    t = t_of(.2)
    x = knock(.2, 180, "stamp", decay=.03, cut=1600) + .4 * bandpass(noise(len(t), "stamp2"), 800, 3000) * np.exp(-t / .01)
    return norm(x, .55)


def s_swish():
    """An egg (or a fruit) hopping back: 「咻～」, a sweep going up then down."""
    t = t_of(.45)
    f = 600 + 900 * np.sin(np.pi * t / .45)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / .45) ** 2
    return norm(x, .38)


def s_boing():
    """A crooked vegetable: a funny 「啵嚶」 that wobbles."""
    t = t_of(.6)
    f = 300 + 120 * np.sin(2 * np.pi * 9 * t) * np.exp(-t / .3) + 80 * t
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / .25)
    return norm(x, .42)


def s_peek():
    """The chicks pop out of the hay."""
    return norm(place(.4, [(0, s_pop()), (.05, .5 * chirp(2800, 3400, .08, "pk"))]), .45)


def s_hide():
    """…and back into the hay."""
    one = lambda k: bandpass(noise(int(.2 * SR), f"hay{k}"), 900, 4000) * np.sin(np.pi * t_of(.2) / .2) ** 2
    return norm(one(0), .32)


def s_whoosh():
    n = int(.5 * SR)
    t = t_of(.5)
    x = np.zeros(n)
    nz = noise(n, "whoosh")
    for i, c in enumerate(np.linspace(600, 2400, 8)):
        seg = slice(i * n // 8, (i + 1) * n // 8)
        x[seg] = bandpass(nz, c * .7, c * 1.3)[seg]
    return norm(lowpass(x, 3000) * np.sin(np.pi * t / .5) ** 2, .4)


def s_done():
    """A round done: a little fanfare on the xylophone and recorder."""
    return norm(place(1.4, [(0, xylo(NOTE["G5"])), (.12, xylo(NOTE["C6"])), (.24, xylo(NOTE["E6"])), (.4, .7 * recorder(NOTE["G6"], .8)),
                            (.4, .6 * xylo(NOTE["C6"], .7))]), .55)


def s_card():
    """A 回真實生活 card coming out: paper and a soft chime."""
    t = t_of(.25)
    paper = bandpass(noise(len(t), "card"), 2000, 7000) * np.sin(np.pi * t / .25) ** 2 * .5
    return norm(place(.9, [(0, paper), (.15, bell(NOTE["G6"], .6, bright=.3)), (.3, .7 * bell(NOTE["D7"], .5, bright=.3))]), .4)


def s_night():
    """Dusk on the farm: three falling music-box notes."""
    return norm(place(1.5, [(0, bell(NOTE["G5"], .9, bright=.3)), (.3, bell(NOTE["E5"], .9, bright=.3)), (.6, bell(NOTE["C5"], .9, bright=.3))]), .45)


# ---------------------------------------------------------------- the music
def loop(total, parts, sr=LOOP_SR, peak=.42):
    x = place_loop(total, parts, sr)
    return x / max(1e-9, np.abs(x).max()) * peak


def bass_line(chords, b, sr, vol=.5, inst=None):
    inst = inst or xylo
    parts = []
    for beat, root in chords:
        parts.append((beat * b, vol * inst(NOTE[root], .8, sr)))
        parts.append(((beat + 2) * b, vol * .8 * inst(NOTE[root] * 1.5, .6, sr)))
    return parts


def m_farm():
    """Bouncy: xylophone and recorder in C, 108 bpm, 48 beats."""
    b, sr = 60 / 108, LOOP_SR
    mel = [(0, "C5", 1), (1, "E5", 1), (2, "G5", 1), (3, "E5", 1), (4, "A5", 1), (5, "G5", 1), (6, "E5", 2),
           (8, "D5", 1), (9, "E5", 1), (10, "F5", 1), (11, "D5", 1), (12, "G5", 2), (14, "G4", 2),
           (16, "C5", 1), (17, "E5", 1), (18, "G5", 1), (19, "C6", 1), (20, "A5", 1), (21, "G5", 1), (22, "E5", 2),
           (24, "F5", 1), (25, "E5", 1), (26, "D5", 1), (27, "E5", 1), (28, "C5", 4),
           (32, "E5", 1), (33, "G5", 1), (34, "A5", 2), (36, "G5", 1), (37, "E5", 1), (38, "D5", 2),
           (40, "E5", 1), (41, "D5", 1), (42, "C5", 1), (43, "D5", 1), (44, "C5", 4)]
    parts = []
    for beat, nt, ln in mel:
        inst = .55 * recorder(NOTE[nt], ln * b * .95, sr) if 16 <= beat < 32 else xylo(NOTE[nt], max(.35, ln * b), sr)
        parts.append((beat * b, inst))
    parts += bass_line([(0, "C3"), (4, "A2"), (8, "F2"), (12, "G2"), (16, "C3"), (20, "A2"), (24, "F2"), (28, "C3"), (32, "A2"), (36, "F2"), (40, "G2"), (44, "C3")], b, sr)
    return loop(48 * b, parts)


def m_coop():
    """The hen house: a perky tune in F with little 「咯咯」 pecks on the off-beats, 116 bpm, 40 beats."""
    b, sr = 60 / 116, LOOP_SR
    mel = [(0, "F5", .5), (.5, "F5", .5), (1, "A5", 1), (2, "C6", 1), (3, "A5", 1), (4, "G5", 1), (5, "A5", .5), (5.5, "G5", .5), (6, "F5", 2),
           (8, "D5", 1), (9, "F5", 1), (10, "G5", 1), (11, "A5", 1), (12, "G5", 2), (14, "C5", 2),
           (16, "F5", .5), (16.5, "F5", .5), (17, "A5", 1), (18, "C6", 1), (19, "D6", 1), (20, "C6", 1), (21, "A5", 1), (22, "G5", 2),
           (24, "A5", 1), (25, "G5", 1), (26, "F5", 1), (27, "D5", 1), (28, "F5", 4),
           (32, "C6", 1), (33, "A5", 1), (34, "G5", 1), (35, "A5", 1), (36, "F5", 4)]
    parts = [(beat * b, xylo(NOTE[nt], max(.3, ln * b), sr)) for beat, nt, ln in mel]
    parts += bass_line([(0, "F2"), (4, "C3"), (8, "D3"), (12, "C3"), (16, "F2"), (20, "A2"), (24, "Bb2"), (28, "F2"), (32, "C3"), (36, "F2")], b, sr)
    for k in range(40):
        if k % 2 == 1:
            t = t_of(.05, sr)
            peck = knock(.05, 900, f"peck{k % 3}", sr, decay=.008, cut=3000)
            parts.append(((k + .5) * b, .12 * peck))
    return loop(40 * b, parts)


def m_orchard():
    """The orchard: a sunny, swaying tune in G in three, 96 bpm, 48 beats (16 bars of 3)."""
    b, sr = 60 / 96, LOOP_SR
    mel = [(0, "D5", 1), (1, "G5", 1), (2, "B5", 1), (3, "A5", 2), (5, "G5", 1), (6, "E5", 2), (8, "D5", 1), (9, "G5", 3),
           (12, "B5", 1), (13, "D6", 1), (14, "B5", 1), (15, "A5", 2), (17, "G5", 1), (18, "A5", 3), (21, "D5", 3),
           (24, "D5", 1), (25, "G5", 1), (26, "B5", 1), (27, "C6", 2), (29, "B5", 1), (30, "A5", 2), (32, "G5", 1), (33, "E5", 3),
           (36, "C6", 1), (37, "B5", 1), (38, "A5", 1), (39, "G5", 2), (41, "F#5", 1), (42, "G5", 6)]
    parts = [(beat * b, (.6 * recorder(NOTE[nt], ln * b * .95, sr) if beat >= 24 else xylo(NOTE[nt], max(.35, ln * b), sr))) for beat, nt, ln in mel]
    roots = ["G2", "C3", "G2", "D3", "G2", "E2", "A2", "D3", "G2", "C3", "G2", "E2", "C3", "D3", "G2", "G2"]
    for i, r in enumerate(roots):
        parts.append((i * 3 * b, .55 * xylo(NOTE[r], .9, sr)))
        for k in (1, 2):
            parts.append(((i * 3 + k) * b, .3 * xylo(NOTE[r] * 2, .4, sr)))
    return loop(48 * b, parts)


def m_garden():
    """The vegetable patch: 咚、啪 (a soft drum and a clap on every beat in turn) under a marimba tune, 100 bpm, 40 beats."""
    b, sr = 60 / 100, LOOP_SR
    parts = []
    for k in range(40):
        t = t_of(.2, sr)
        if k % 2 == 0:
            kick = np.sin(2 * np.pi * np.cumsum(np.linspace(120, 50, len(t))) / sr) * np.exp(-t / .09)
            parts.append((k * b, .7 * kick))
        else:
            clap = sum(bandpass(noise(len(t), f"clap{k % 3}{j}"), 900, 3500, sr) * np.exp(-np.maximum(t - j * .012, 0) / .03) * (t >= j * .012)
                       for j in range(3))
            parts.append((k * b, .3 * clap))
    mel = [(0, "C5"), (1, "E5"), (2, "C5"), (3, "E5"), (4, "G5"), (6, "E5"), (8, "D5"), (9, "F5"), (10, "D5"), (11, "F5"), (12, "A5"), (14, "G5"),
           (16, "E5"), (17, "G5"), (18, "E5"), (19, "G5"), (20, "C6"), (22, "A5"), (24, "G5"), (25, "F5"), (26, "E5"), (27, "D5"), (28, "C5"),
           (32, "E5"), (33, "D5"), (34, "E5"), (35, "G5"), (36, "C5"), (38, "C5")]
    for beat, nt in mel:
        parts.append((beat * b, .8 * xylo(NOTE[nt], .5, sr)))
    for k, root in enumerate(["C3", "D3", "C3", "G2", "C3", "F2", "G2", "C3", "C3", "G2"]):
        parts.append((k * 4 * b, .55 * xylo(NOTE[root], 1.0, sr)))
    return loop(40 * b, parts, peak=.4)


def m_market():
    """The market: busier, a recorder and xylophone in D with a shaker, 124 bpm, 48 beats."""
    b, sr = 60 / 124, LOOP_SR
    mel = [(0, "D5", .5), (.5, "E5", .5), (1, "F#5", 1), (2, "A5", 1), (3, "F#5", 1), (4, "B5", 1), (5, "A5", 1), (6, "F#5", 2),
           (8, "G5", 1), (9, "F#5", 1), (10, "E5", 1), (11, "F#5", 1), (12, "D5", 2), (14, "A4", 2),
           (16, "D5", .5), (16.5, "E5", .5), (17, "F#5", 1), (18, "A5", 1), (19, "D6", 1), (20, "B5", 1), (21, "A5", 1), (22, "F#5", 2),
           (24, "G5", 1), (25, "A5", 1), (26, "B5", 1), (27, "C#6", 1), (28, "D6", 4),
           (32, "A5", 1), (33, "F#5", 1), (34, "G5", 1), (35, "E5", 1), (36, "F#5", 1), (37, "D5", 1), (38, "E5", 2),
           (40, "F#5", 1), (41, "E5", 1), (42, "D5", 1), (43, "E5", 1), (44, "D5", 4)]
    parts = []
    for beat, nt, ln in mel:
        inst = .55 * recorder(NOTE[nt], ln * b * .95, sr) if 16 <= beat < 32 else xylo(NOTE[nt], max(.3, ln * b), sr)
        parts.append((beat * b, inst))
    parts += bass_line([(0, "D3"), (4, "B2"), (8, "G2"), (12, "A2"), (16, "D3"), (20, "B2"), (24, "G2"), (28, "D3"), (32, "A2"), (36, "D3"), (40, "A2"), (44, "D3")], b, sr)
    for k in range(96):
        t = t_of(.06, sr)
        sh = bandpass(noise(len(t), f"shake{k % 4}"), 3000, 7500, sr) * np.sin(np.pi * t / .06) ** 2
        parts.append((k * b / 2, (.1 if k % 2 else .06) * sh))
    return loop(48 * b, parts)


def m_rest():
    """A music-box lullaby at dusk, 56 bpm, 24 beats."""
    b, sr = 60 / 56, LOOP_SR
    mel = [(0, "E5", 2), (2, "D5", 1), (3, "C5", 1), (4, "D5", 2), (6, "G4", 2), (8, "E5", 2), (10, "G5", 1), (11, "E5", 1),
           (12, "D5", 4), (16, "C5", 2), (18, "D5", 1), (19, "E5", 1), (20, "C5", 4)]
    ch = [(0, ["C4", "E4", "G4"]), (4, ["G3", "B3", "D4"]), (8, ["A3", "C4", "E4"]), (12, ["G3", "B3", "D4"]), (16, ["F3", "A3", "C4"]),
          (20, ["C4", "E4", "G4"])]
    parts = [(beat * b, .7 * bell(NOTE[nt], max(.6, ln * b * 1.6), sr, .25)) for beat, nt, ln in mel]
    for beat, notes in ch:
        parts.append((beat * b, .45 * pad([NOTE[x] for x in notes], 4 * b * 1.15, sr)))
    return loop(24 * b, parts, peak=.38)


SOUNDS = {
    "tap": s_tap, "pop": s_pop, "cheep": s_cheep, "cheep_q": s_cheep_q, "cluck": s_cluck, "oink": s_oink, "baa": s_baa, "quack": s_quack,
    "sniff": s_sniff, "moo": s_moo, "knock": s_knock, "thud": s_thud, "tick": s_tick, "rustle": s_rustle, "plonk": s_plonk, "honk": s_honk,
    "engine": s_engine, "bell": s_bell, "stamp": s_stamp, "swish": s_swish, "boing": s_boing, "peek": s_peek, "hide": s_hide,
    "whoosh": s_whoosh, "done": s_done, "card": s_card, "night": s_night, "count_all": s_count_all,
    **{f"count_{k}": count_note(k) for k in range(1, 11)},
}
MUSIC = {"music_farm": m_farm, "music_coop": m_coop, "music_orchard": m_orchard, "music_garden": m_garden, "music_market": m_market,
         "music_rest": m_rest}
LONG = {}


def write(path, x, sr):
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())


def make(names=None):
    OUT.mkdir(parents=True, exist_ok=True)
    wanted = set(names or [*SOUNDS, *MUSIC])
    for name, f in SOUNDS.items():
        if name not in wanted:
            continue
        x = fade_edges(np.asarray(f(), float))
        d = len(x) / SR
        if d > LONG.get(name, 1.5):
            raise SystemExit(f"{name}: {d:.2f} s is too long")
        if np.abs(x).max() > .75:
            raise SystemExit(f"{name}: too loud")
        write(OUT / f"{name}.wav", x, SR)
        print(f"  {name:20s} {d:5.2f} s  peak {np.abs(x).max():.2f}")
    for name, f in MUSIC.items():
        if name not in wanted:
            continue
        x = np.asarray(f(), float)
        d = len(x) / LOOP_SR
        jump = abs(x[0] - x[-1])
        if not 18 <= d <= 30 or jump > .05:
            raise SystemExit(f"{name}: {d:.1f} s, seam jump {jump:.3f}")
        write(OUT / f"{name}.wav", x, LOOP_SR)
        print(f"  {name:20s} {d:5.2f} s  loop seam {jump:.3f}")
    known = {f"{n}.wav" for n in [*SOUNDS, *MUSIC]}
    extra = [p.name for p in OUT.glob("*.wav") if p.name not in known]
    if extra:
        raise SystemExit(f"files nobody makes: {extra}")
    size = sum(p.stat().st_size for p in OUT.glob("*.wav"))
    if size > LIMIT:
        raise SystemExit(f"{size} bytes: over {LIMIT}")
    print(f"{len(known)} sounds, {size:,} bytes")


def preview(out):
    with tempfile.TemporaryDirectory(dir="/dev/shm") as tmp:
        parts = []
        for name in [*MUSIC, *SOUNDS]:
            parts.append(str(OUT / f"{name}.wav"))
        lst = pathlib.Path(tmp) / "list.txt"
        lst.write_text("".join(f"file '{p}'\n" for p in parts))
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", str(lst), "-ar", "22050", "-c:a", "aac", "-b:a", "96k", out], check=True)
    print(out)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["preview"]:
        preview(args[1])
    else:
        make(args or None)
