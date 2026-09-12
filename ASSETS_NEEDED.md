# Assets needed

Nothing in this project currently uses external art or audio — every
surface, prop, character, and sound is either a primitive mesh with a flat
color or silence. This is deliberate (no assets existed when this pass was
built) and every system below is built so dropping in a real file is
enough on its own, or close to it. Per-folder `README.md` files under
`assets/` repeat the relevant table for whoever is working in that folder;
this is the consolidated version.

## Zero-code-change: audio

Drop files at the exact paths below and they play automatically. See
`assets/audio/music/README.md` and `assets/audio/sfx/README.md` for the
full lists — `AudioManager.play_sfx()` / `set_music_state()` both check
`ResourceLoader.exists()` first, so a missing file is silent, never an
error.

- `assets/audio/music/{exploration,tension,combat,puzzle,discovery,boss,final}.ogg`
- `assets/audio/sfx/*.ogg` — ~20 cues, full list in `assets/audio/sfx/README.md`

## Small-code-change: 3D models

Nothing hardcodes a mesh name, but nothing auto-detects a dropped-in model
either — each script currently builds its own placeholder primitive in
`_ready()`/`_configure_freedom()`-adjacent code. The pattern to swap one in
is the same everywhere:

```gdscript
# before (e.g. enemy_base.gd _ready())
var mesh_instance := MeshInstance3D.new()
var capsule_mesh := CapsuleMesh.new()
mesh_instance.mesh = capsule_mesh
mesh_instance.material_override = EnvironmentGenerator.make_material(body_color, ...)
add_child(mesh_instance)

# after
var model := load("res://assets/models/enemies/crawler.glb").instantiate()
add_child(model)
```

Keep the existing `CollisionShape3D` (don't delete it when replacing the
mesh) so physics/hit-detection sizes stay correct, and prefer sizing the
new model to roughly match the placeholder's dimensions (noted in each
script) to avoid re-tuning gameplay distances.

Priority order if building assets incrementally:
1. **Player weapon viewmodels** (`assets/models/weapons/`) — most visible,
   currently literally invisible.
2. **Enemy models** (`assets/models/enemies/`) — currently a plain colored
   capsule for every archetype.
3. **Hero props**: the Freedom Core fragment, the Vector pickup, doors,
   terminals (`assets/models/props/`).
4. Everything else (pipes, debris, alien growth decoration) — lowest
   priority, primitives already read fine as industrial clutter.

## Textures

Every material is `StandardMaterial3D` with only `albedo_color` (and
sometimes `emission`) set — see `EnvironmentGenerator.make_material()`.
Drop files in `assets/textures/` and extend that one function to accept an
optional texture, or set `albedo_texture` directly on materials after
creation. This is the single highest-leverage visual upgrade available
before any modeling work: same geometry, real surfaces.

## Fonts

None set; Godot's default theme font is in use everywhere. See
`assets/fonts/README.md`.

## Licensing note

Whatever ends up in these folders, keep track of the source/license for
each asset (CC0, purchased, commissioned, etc.) — `scripts/ui/credits.gd`
has an `ASSET LICENSES`-shaped spot ready in the credits list once that
information exists.
