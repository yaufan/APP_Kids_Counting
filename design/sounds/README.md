# design/sounds：數數小農場的聲音

`make_sounds.py` makes every sound from sine waves and noise (numpy): nothing recorded, nothing
downloaded. It writes `app/assets/sounds/*.wav`; a fixed seed per sound, so each run writes the same
files. There is no error sound: a miss is only a funny sound (docs/design.md 「做錯的時候」).

    python3 design/sounds/make_sounds.py              # all
    python3 design/sounds/make_sounds.py moo honk     # only these
    python3 design/sounds/make_sounds.py preview OUT.m4a

## Music (16,000 Hz, seamless loops)
| file | where |
|---|---|
| `music_farm.wav` | the farm (home) |
| `music_coop.wav` | 餵小雞, 撿雞蛋 |
| `music_orchard.wav` | 摘水果, 分點心 |
| `music_garden.wav` | 排排隊 |
| `music_market.wav` | 去市場 |
| `music_rest.wav` | the rest |

## Short sounds (22,050 Hz)
| file | when |
|---|---|
| `tap.wav` | any button |
| `pop.wav` | 餵小雞: a corn hops to a chick |
| `cheep.wav` | a chick fed; chicks counted |
| `cheep_q.wav` | a chick that has eaten already shakes its head |
| `cluck.wav` | 撿雞蛋 starts; the hen |
| `oink.wav` | 分點心: a piglet |
| `baa.wav` | a sheep (customer or eater) |
| `quack.wav` | 鴨子過橋; a duck customer |
| `sniff.wav` | a rabbit customer |
| `moo.wav` | tapping 牛牛 |
| `knock.wav` | an egg into the box |
| `thud.wav` | a fruit into the basket |
| `tick.wav` | a snack on a plate |
| `rustle.wav` | planting in 排排隊 |
| `plonk.wav` | a melon onto the truck |
| `honk.wav` | the truck is loaded |
| `engine.wav` | the truck drives to market |
| `bell.wav` | the 「好了！」 bell; the market |
| `stamp.wav` | the order is done |
| `swish.wav` | one too many hops back |
| `boing.wav` | a crooked vegetable |
| `peek.wav` | chicks pop out of the hay |
| `hide.wav` | they hide again |
| `whoosh.wav` | the next question; a duck crosses; a fruit back to the tree |
| `done.wav` | a round done |
| `card.wav` | a 回真實生活 card |
| `night.wav` | the rest begins |
| `count_all.wav` | the end of a count: 「一共……」 |
| `count_1.wav` | counting 1 (the 1th step up the stairs) |
| `count_2.wav` | counting 2 (the 2th step up the stairs) |
| `count_3.wav` | counting 3 (the 3th step up the stairs) |
| `count_4.wav` | counting 4 (the 4th step up the stairs) |
| `count_5.wav` | counting 5 (the 5th step up the stairs) |
| `count_6.wav` | counting 6 (the 6th step up the stairs) |
| `count_7.wav` | counting 7 (the 7th step up the stairs) |
| `count_8.wav` | counting 8 (the 8th step up the stairs) |
| `count_9.wav` | counting 9 (the 9th step up the stairs) |
| `count_10.wav` | counting 10 (the 10th step up the stairs) |

The counting notes climb the pentatonic scale (C5 D5 E5 G5 A5, then C6 D6 E6 G6 A6), one per number.
Each sound switch in parent mode (music, effects, voice) silences only its own sound.
