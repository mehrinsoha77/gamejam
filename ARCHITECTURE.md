# Architecture

## The core idea: FreedomComponent

`scripts/freedom/freedom_component.gd` is the single source of truth for
"what can this thing do." It tracks six degrees of freedom (`TRANS_X/Y/Z`,
`ROT_PITCH/YAW/ROLL`), each in one of six states (`LOCKED`, `UNLOCKED`,
`TEMPORARY`, `DISABLED`, `STOLEN`, `TRANSFERRED`). Any node that should
participate in the freedom-manipulation mechanic — the player, an enemy, a
door, an elevator — gets its own `FreedomComponent` child named exactly
`"FreedomComponent"`, and every other system (movement gating, the Vector
Weapon, the Freedom Manipulator, the HUD's scan panel) reads/writes it
through the same handful of methods (`is_free`, `unlock`, `lock`, `steal`,
`give_to`, `reclaim`, `hold_for_device`, `force_lock`, `force_unlock`).
Nothing checks six scattered booleans anywhere in the codebase.

`relevant_dof` on each component lets an object declare which axes even
apply to it (a wall-mounted door only cares about `TRANS_Y`, say), so scan
UIs can show "n/a" instead of a false "locked."

## The Vector (Freedom Manipulator)

`scripts/weapons/freedom_manipulator.gd` implements all seven operations
from the design doc: **SCAN** is passive/continuous (whatever you're
looking at is scanned automatically), and **TAKE / STORE / TRANSFER /
RETURN / LOCK / RESTORE** are six modes cycled with `Q` and executed on
left-click. TAKE and RETURN operate directly between the scanned object and
the player (via `give_to()` / `reclaim()`, which remember the original
owner). STORE/TRANSFER route through a small internal buffer
(`hold_for_device()` / `release_from_device()`) so freedom can be moved
between two objects that aren't the player at all — the actual puzzle
mechanic described for Level 4 onward.

## Design-doc ambiguities and how they were resolved

The master brief is a rich design document, not a spec, and a few things in
it don't fully reconcile. Per its own "Important AI Behavior" section, here
's what was decided and why, rather than silently picking one:

1. **Is looking around (mouse look) itself a locked DOF from the start?**
   The doc's own Prologue text says "the player can initially move only
   forward," which only makes sense as a statement about *translation* — if
   pitch/yaw were also locked at game start the player couldn't even see
   the room they woke up in. Resolution: `ROT_PITCH`/`ROT_YAW` are unlocked
   for the player unconditionally in `Player._build_rig()`; only
   translation is gated by story progress. `ROT_ROLL` stays locked until
   the Final Act's zero-gravity sequences, and enemies (Anchor, late
   bosses) *can* still temporarily lock the player's rotation DOFs as a
   combat effect — the baseline is "free," not "impossible to touch."

2. **The abstract "Freedom Level 0-6" ladder (X, then X+reverse, then X/Y,
   then X/Y/Z...) vs. the concrete per-level rewards ("Level 1 reward:
   backward movement", "Level 2 reward: vertical movement", "Level 3
   reward: downward movement").** These two lists don't map onto each other
   cleanly. Resolution: the concrete per-level rewards are treated as
   authoritative (they're the actual gameplay beats), and the abstract
   ladder is treated as flavor text describing the general shape of
   progression, not a literal checklist. The Prologue's "1 DOF" is
   `TRANS_Z` restricted to forward-only via a simple `Player.forward_only`
   flag (not a seventh FreedomComponent state — see below); Level 1's nav
   puzzle reward unlocks full `TRANS_Z` *and* `TRANS_X` together (labeled
   "GROUND-PLANE TRANSLATION") because a corridor-crawl combat arena
   immediately follows it, and forward/back-only strafing in that fight
   would feel bad regardless of what the abstract ladder implies about X
   vs Z ordering.

3. **"Forward-only" is a directional restriction, not a sixth kind of
   lock.** `FreedomComponent`'s state enum models *whether* an axis is
   available, not *which direction* along it. Rather than inventing
   `FORWARD_ONLY` as a seventh DOFState (which would leak a Prologue-only
   narrative beat into the general-purpose freedom system every other
   object uses), `Player.forward_only: bool` clamps the input vector one
   level up, in `_get_gated_input_vector()`. `TRANS_Z` itself is genuinely
   `UNLOCKED` throughout; only the sign of movement along it is
   restricted, and only for the player, and only until the Level 1 puzzle
   clears it.

4. **The Vector Weapon (combat item, one of the four weapons) vs. "the
   Vector" (the manipulator tool with SCAN/TAKE/STORE/TRANSFER/RETURN/
   LOCK/RESTORE) share a name in the brief.** They're kept as two distinct
   classes — `VectorWeapon` (combat: strips one DOF from a locked-on
   enemy for a few seconds, an offensive tool) and `FreedomManipulator`
   (utility: the full seven-operation toolkit, a puzzle/mercy tool) — both
   diegetically "the same technology, two calibrations," so the naming
   collision in the prose doesn't become a naming collision in code.

## Why every `.tscn` is just a root node + a script

This project was built without access to the Godot editor (no GUI, so no
way to hand-place nodes, verify anchors visually, or catch a scene-file
typo before runtime). Hand-writing full `.tscn` files with multiple
`ext_resource`/`sub_resource` blocks is exactly the kind of thing that's
easy to get subtly wrong in a way that only shows up when someone opens it
in an editor. Building every scene's contents in GDScript (`_ready()`
constructs the node tree in code) trades a bit of Godot-editor convenience
for something far more important right now: it's all statically checkable
by reading the script, and it's trivially data-driven (level layout is
just numbers in `level_1.gd`, not buried in a binary-ish scene graph).
**This is a deliberate, temporary tradeoff** — once this project is opened
in a real editor, hand-authoring the visually complex scenes (especially
future levels' set-dressing) the normal Godot way is entirely reasonable
and probably faster for a human working visually.

## Collision layer convention

| Layer # | Used for |
|---|---|
| 1 | Static world geometry (floors/walls/ceilings/doors' blockers) |
| 2 | Player body |
| 3 | Interactable `Area3D`s (raycast target for `[E]` prompts) |
| 4 | Enemy bodies |

`InteractionComponent` casts two different rays: `raycast_body()` (bodies
only — combat weapons use this so a Terminal's trigger volume never
intercepts a shot) and `raycast_any()` (bodies *and* areas — the Freedom
Manipulator needs this because Interactables like doors/elevators are
`Area3D`s, not physics bodies).

## Level geometry gotcha this codebase already worked around

`EnvironmentGenerator.create_room()`'s `open_sides` parameter leaves a
`door_width`-wide gap in a wall rather than removing the entire wall face.
An early version of Level 1 removed whole wall faces to connect to
corridors, which left the flanks of every wide room with no wall *and* no
floor beyond the connecting corridor's width — an invisible walk-off-into-
the-void hazard. If you add new rooms, always pass a `door_width` that
matches the corridor actually connecting there (or leave the default,
which matches every corridor already in Level 1), and never call
`open_sides` on a face that doesn't lead to more built geometry.
