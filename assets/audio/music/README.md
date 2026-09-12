# Music

`AudioManager` (`scripts/autoload/audio_manager.gd`) crossfades between named
states and will pick up files automatically the moment they exist at these
exact paths — nothing else to wire up:

| File | State |
|---|---|
| `exploration.ogg` | default wandering/ambient |
| `tension.ogg` | something's nearby |
| `combat.ogg` | active fight |
| `puzzle.ogg` | working a puzzle |
| `discovery.ogg` | menus / lore reveals |
| `boss.ogg` | boss encounters |
| `final.ogg` | Final Act / endings |

Loop each track seamlessly (set the `.ogg`'s loop point, or use a
loop-enabled `AudioStreamOggVorbis` import). Until these exist the game runs
in silence for music — this is expected, not a bug.
