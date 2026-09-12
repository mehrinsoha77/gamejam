# Degrees of Freedom

*"Every freedom has a cost."*

A first-person sci-fi action/puzzle/exploration game built in Godot 4.x for
a game jam. The player wakes up almost unable to move, fights and solves
their way to full six-degrees-of-freedom mobility, and eventually gains the
power to take that same freedom away from others — and has to decide
whether to.

## Status

This build is a **vertical slice**: the Prologue and Level 1 ("The Straight
Line") are fully playable start to finish, and every core system the rest
of the game needs (movement, combat, the Freedom Manipulator, puzzles,
dialogue, HUD, menus, checkpoints, adaptive music, debug tools) is built
and wired up. Levels 2-5, the Final Act, the boss, and the four endings are
**designed but not built** — see [`LEVEL_DESIGN.md`](LEVEL_DESIGN.md) for
the full room-by-room spec ready for the next development pass.

There are currently **no art or audio assets** — every surface is a
primitive mesh with a flat color, and the game runs in silence. This is
intentional (see [`ASSETS_NEEDED.md`](ASSETS_NEEDED.md)): every system is
built to pick up real assets the moment they're dropped into the right
folder, with no code changes required for audio and minimal changes for
models/textures.

Read [`ARCHITECTURE.md`](ARCHITECTURE.md) for how the code is organized and
a few judgment calls made where the original design brief was ambiguous or
self-contradictory.

## Running it

This project has not been opened or tested in the Godot editor — it was
built in an environment without Godot installed, writing plain-text
`project.godot` / `.tscn` / `.gd` files directly. **Before anything else,
open it in Godot 4.2+ and fix whatever the editor flags**, then work
through the QA checklist at the bottom of this file.

1. Install Godot 4.2 or later (standard, not .NET/C# build — everything
   here is GDScript).
2. `Import` this folder as a project (point at `project.godot`).
3. Press F5 / Run. It should boot to the Main Menu.

## Controls

| Action | Key |
|---|---|
| Move | WASD |
| Look | Mouse |
| Jump | Space (requires Y-axis freedom) |
| Crouch | C |
| Sprint | Shift |
| Interact | E |
| Fire primary | Left mouse |
| Fire secondary / alt-use | Right mouse |
| Cycle Vector mode | Q (only while the Vector is equipped) |
| Switch weapon | 1-4 |
| Pause | Esc |
| Debug overlay (editor/debug builds only) | F1 (F2 give all DOF, F3 +100 freedom, F4 teleport forward) |

## Project structure

```
res://
  project.godot
  scenes/            main menu, credits, ending screen (root .tscn stubs;
                      everything else is built by their attached script)
  levels/             prologue.tscn, level_1.tscn
  scripts/
    autoload/         GameManager, AudioManager, DialogueManager, DebugManager
    freedom/          FreedomComponent — the core DOF state machine
    player/           Player, InteractionComponent, WeaponSystem
    weapons/          EnergyWeapon, VectorWeapon, AnchorWeapon, FreedomManipulator
    enemies/          EnemyBase + 10 archetypes
    systems/          Door, Terminal, Checkpoint, PuzzlePanel, pickups...
    puzzles/          NavigationPuzzle
    ui/               HUD, menus, dialogue box, scan panel (all code-built)
    environment/       EnvironmentGenerator — procedural room/corridor builder
    levels/           LevelBase, Prologue, Level1 (the actual level scripts)
  assets/             empty folders + READMEs saying exactly what goes where
  data/               reserved for future data-driven level content
```

Every `.tscn` file in this project is intentionally minimal — a root node
plus one script. All child nodes, meshes, materials, lights and collision
shapes are constructed in GDScript at runtime. This was a deliberate choice
made without an editor available to hand-author scenes visually; it also
means level geometry, UI, and props are trivially data-driven and easy to
extend by editing scripts rather than hunting through scene trees. See
`ARCHITECTURE.md` for the reasoning.

## Final QA checklist (not yet run — no Godot in the build environment)

- [ ] Project opens with zero errors in Godot 4.2+
- [ ] Main Menu → New Game → Prologue boots and is playable
- [ ] Prologue → Level 1 transition works
- [ ] Level 1 completable start to finish (weapon pickup, puzzle, arena,
      research room, Vector pickup, Freedom Core fragment, exit)
- [ ] Death mid-level respawns at the correct checkpoint with progress kept
- [ ] Pause menu, Settings menu (all sliders/toggles), Credits all open and close
- [ ] F1 debug overlay works in an editor/debug run and is inert in a release export
- [ ] Windows export completes and runs standalone

## Known limitations of this pass

- No 3D models, textures, music, or sound effects — see `ASSETS_NEEDED.md`.
- Levels 2-5, the Final Act, the boss fight, and the four endings are
  designed in `LEVEL_DESIGN.md` but not implemented as playable scenes.
- 8 of the 10 enemy archetypes (everything but Crawler and Freedom Leech)
  are implemented as functional scaffolds — their FreedomComponent-driven
  behavior works, but they haven't been placed in a tuned encounter yet.
- No third-person/viewmodel weapon meshes; weapons are invisible logic
  nodes for now (functionally complete, visually absent).
- Never opened in the Godot editor — expect small fixups on first import.
