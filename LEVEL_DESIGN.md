# Level Design — Levels 2-5, Final Act, Endings

Everything below is **designed, not built**. It translates the original
master design brief into concrete implementation notes against the systems
that already exist (`FreedomComponent`, `EnvironmentGenerator`,
`NavigationPuzzle`-style puzzle pattern, the enemy roster, `Door`/
`ElevatorPlatform`/`Checkpoint`, `DialogueManager`, `AudioManager` states),
so building each level is "write a `scripts/levels/level_N.gd` like
`level_1.gd`," not "invent new systems."

General pattern every level should follow (established by `Level1`):
- Extend `LevelBase`, build geometry with `EnvironmentGenerator` in a
  `_build_*_zone()` per room, call `spawn_player()` last.
- Chain rooms/corridors with **exactly abutting Z (or X) ranges** — see the
  "gotcha" in `ARCHITECTURE.md`. Track a running cursor when laying out
  coordinates; do not eyeball adjacent segments' centers/sizes.
- A `Checkpoint` at the start and after every major beat (puzzle solved,
  arena cleared, before/after a boss phase).
- Call `set_objective()` at every beat transition.
- Reward moments call `player.unlock_dof_with_presentation(...)`.
- Use `AudioManager.set_music_state(...)` on entering/leaving combat.

---

## Level 2 — The Vertical Problem

**Theme:** vertical freedom. **Unlocks:** `TRANS_Y`.

- A tall industrial shaft (`EnvironmentGenerator` doesn't yet have a
  vertical-shaft helper — add `create_shaft(parent, center, radius/size,
  height)` alongside `create_room`, built the same way: floor, an open
  ceiling far above, and a ring of walls) with several `ElevatorPlatform`-
  style suspended platforms at increasing height, and a visible destination
  (a lit doorway/silhouette) the player can see from the start but not
  reach — the motivating "I can see it, I can't get there" shot the brief
  calls for.
- **Puzzle:** an energy/trajectory calibration at a `Terminal`+`PuzzlePanel`
  station near the shaft base — reuse the `NavigationPuzzle` pattern
  (dials matched against an in-world stamped/plaque value) but frame the
  flavor text around a physics quantity (e.g. required launch energy for a
  platform lift) rather than reusing Level 1's exact cover story.
- **Reward:** `TRANS_Y` unlocked (jump becomes real vertical traversal, not
  just a hop) via `unlock_dof_with_presentation([FreedomComponent.DOF.TRANS_Y], hud)`.
  Immediately after, the player physically ascends the shaft they could
  only look up at before — that ascent sequence is the "immediately use
  the new freedom" beat the brief asks for.
- **New enemy:** `Flyer` (already implemented) — first fight where the
  player must aim up. Its `preferred_dof_to_strip` is `TRANS_Y`, so a
  Vector Weapon shot grounds it, which doubles as a teaching moment for
  DOF-based combat against a mobile target.
- **Optional:** an `ElevatorPlatform` (already implemented) mid-shaft as a
  legitimate alternate/faster route once the player has picked up the
  Freedom Manipulator in Level 1's research room — TAKE its `TRANS_Y` to
  fly straight up instead of climbing platform-by-platform.

## Level 3 — The Fall

**Theme:** loss of control. **Unlocks:** downward `TRANS_Y` traversal
(implemented as the same `TRANS_Y` DOF; see the note in `ARCHITECTURE.md`
about the design doc's per-direction vs per-axis ambiguity — Level 2
already unlocked *up*, so Level 3's beat is about a *different*
restriction: gravity/anchor fields that override normal falling, not a new
FreedomComponent state. A `HazardZone`-style volume that forces
`velocity.y` toward zero within its bounds is the cleanest implementation —
add it to `scripts/systems/` as `gravity_anomaly.gd`, an `Area3D` the
player's `_physics_process` checks each frame the way `zero_gravity` is
already checked).

- A vertical reactor shaft, broken elevators, floating debris. The player
  can see the lower section and is held above it by a gravity anomaly.
- **Puzzle:** a biochemical/compound-matching interaction — implement as a
  set of colored/labeled `Interactable` canisters the player carries one
  at a time (a simple `held_item: String` on the player, set on interact,
  cleared on depositing at a matching receptacle) rather than a dropdown
  quiz UI, per the brief's "make it visual and interactive" instruction.
- **Reward:** the anomaly is disabled → a scripted descent sequence
  (camera stays player-controlled but falling is now intentional/safe —
  drop the player into a padded/current-filled shaft segment, or ramp
  `zero_gravity` briefly true with a controlled downward thrust) through
  the reactor shaft into Level 4's space.
- **New enemies:** `Leaper` (unpredictable vertical attacks fit the falling
  motif) and `Spinner` (introduce orientation-tracking combat ahead of
  Level 4's rotating rooms).

## Level 4 — Freedom Isn't Safety

**Theme:** freedom creates responsibility. **Introduces:** the Freedom
Manipulator's full puzzle usage (the player already picked it up in Level
1's research room for this playthrough's continuity, or introduce it fresh
here if that pickup is cut for a stricter reading of the brief's ordering —
either works with the existing `FreedomManipulator` implementation).

- A collapsing, destabilizing research complex: rotating rooms, moving
  debris, malfunctioning doors, radiation zones (a `HazardZone` variant
  that calls `player.take_damage()` on a tick timer while overlapping).
- **Core puzzle:** three objects each need one DOF the player must
  redistribute — a `Door` (freedom_gated, needs `TRANS_Y`), an
  `ElevatorPlatform` (owns `TRANS_Y`), and a rotating bridge/platform prop
  (owns `ROT_YAW`) — using STORE on one and TRANSFER onto another. This is
  literally what `FreedomManipulator`'s buffer (`Mode.STORE`/`Mode.TRANSFER`)
  was built for; no new manipulator code should be needed, only new
  `FreedomComponent`-bearing props.
- **Combat/environment interaction:** killing a creature near a structural
  support should trigger a stabilizer failure that changes the room's
  available movement (e.g. a `Door.locked` flips true, or a platform's
  `FreedomComponent` gets `force_lock()`ed) — wire this as a `died` signal
  connection on the relevant enemy instance in the level script, same
  pattern as `Level1._on_arena_enemy_died`.
- **New systems:** a `Shield` resource on the player (an
  `shield_energy: float` alongside `energy`, drained by a "shield active"
  toggle, blocking incoming damage while > 0) for the radiation zones —
  small, additive change to `player.gd`.
- **New enemies:** `Phaser`, `Mimic` (both implemented) fit this level's
  "things aren't stable, including the rules" theme.

## Level 5 — The Freedom Core

**Theme:** truth. Visual style shifts hard: less industrial, more alien/
impossible architecture (taller rooms, non-orthogonal `EnvironmentGenerator`
extensions — consider adding rotated wall segments or non-rectangular
room shapes here specifically, since Levels 1-4 are deliberately boxy to
match their "constrained facility" reading).

- Reveal the facility's true purpose gradually via `ResearchLog`s and
  short `DialogueManager.queue_lines()` beats (never one big dump) — the
  existing `FreedomCoreFragment.reveal_lines` pattern from Level 1 scales
  directly to this.
- **Guardian** fight (implemented as a scaffold in
  `scripts/enemies/guardian.gd`): a multi-phase boss that gains DOF as its
  health drops (`advance_phase()` already wired to `take_damage()`). What's
  missing is the arena itself and phase-specific attacks/telegraphs — the
  phase-change *signal* (`phase_changed`) already exists to hang those off
  of.

## Final Boss — The Unbound

Scaffolded in `scripts/enemies/the_unbound.gd`: starts with all six DOF
unlocked, exposes `on_dof_stripped(dof)` (already called by
`VectorWeapon`/`AnchorWeapon` automatically, no extra wiring needed for
combat) and a `CONSTRAIN_ORDER` suggesting X → Z → Y → yaw → pitch → roll,
firing `fully_constrained` once every relevant DOF is disabled. What's not
built: the arena, per-phase unique attacks as each axis is stripped (the
brief explicitly warns against a "purely repetitive" strip sequence — each
successful strip should change its moveset, not just its speed), and the
KILL vs FREE choice prompt once `fully_constrained` fires (wire this as a
`Terminal`-style or dedicated prompt UI calling either `take_damage(9999)`
or `FreedomManipulator`-style `force_unlock` on every DOF, then
`GameManager.show_ending(...)`).

## Final Act — Total Freedom

Full 6DOF gameplay: `player.zero_gravity = true`, all `FreedomComponent`
DOFs unlocked including `ROT_ROLL`. `Player._handle_jump()` and
`_handle_head_bob()` already branch on `zero_gravity`, so the movement
half of this is implemented and just needs `zero_gravity` flipped true by
the level script — what's missing is the collapsing-facility set dressing
(rotating rooms, moving structures, hazards) and the energy-management
framing the brief asks for (tie to the `Shield`/`energy` fields already on
`Player`).

## Endings

`GameManager.show_ending(title, body)` + `scenes/ending_screen.tscn` are
fully implemented and already display the Freedom Score/rank
(`GameManager.compute_rank()`). Each ending is just a call to
`show_ending()` from wherever the Freedom Core's final choice UI lives:

1. **Escape** — `show_ending("YOU CHOSE YOURSELF", "...")`, no state
   changes beyond whatever score was already accrued.
2. **Liberation** — before calling `show_ending`, iterate every unlocked
   player DOF and `lock()` it back down (the mirror image of the whole
   game's progression), then show the ending text.
3. **Control** — set some `GameManager.player_is_core_administrator = true`
   flag (new, trivial) for epilogue/credits flavor, `show_ending(...)`.
4. **Secret** — gate behind `GameManager.research_logs_found` and
   `GameManager.creatures_freed` thresholds (both already tracked!,
   incremented by `ResearchLog.interact()` and
   `FreedomManipulator._do_restore()` respectively) — check the thresholds
   where the final choice is presented and offer this fourth option only
   if met.

## Enemy roster status

| Archetype | File | Status |
|---|---|---|
| Crawler | `crawler.gd` | Fully implemented, used in Level 1 |
| Freedom Leech | `freedom_leech.gd` | Fully implemented, not yet placed in a level |
| Leaper | `leaper.gd` | Functional scaffold |
| Flyer | `flyer.gd` | Functional scaffold, earmarked for Level 2 |
| Spinner | `spinner.gd` | Functional scaffold, earmarked for Level 3 |
| Phaser | `phaser.gd` | Functional scaffold, earmarked for Level 4 |
| Anchor | `anchor_alien.gd` | Functional scaffold |
| Mimic | `mimic.gd` | Functional scaffold, earmarked for Level 4 |
| Guardian | `guardian.gd` | Phase-transition logic only, no arena |
| The Unbound | `the_unbound.gd` | DOF-strip tracking only, no arena/moveset |

"Functional scaffold" means: has a distinct `FreedomComponent` profile,
distinct stats, and archetype-specific behavior that runs correctly today
if you instance it in a level (as `Level1` does with `Crawler`) — it just
hasn't been placed in a tuned encounter or given a unique model yet.
