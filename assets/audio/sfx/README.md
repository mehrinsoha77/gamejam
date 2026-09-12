# Sound effects

`AudioManager.play_sfx(name)` loads `res://assets/audio/sfx/<name>.ogg` on
demand and silently no-ops if the file doesn't exist yet, so drop any of
these in whenever they're ready — no code changes needed. Cues currently
called from the game:

- `footstep.ogg` — player footstep (played with slight random pitch)
- `weapon_energy_fire.ogg`
- `weapon_vector_fire.ogg`
- `weapon_anchor_fire.ogg`
- `dof_unlock_low.ogg`, `dof_unlock_mid.ogg`, `dof_unlock_high.ogg` — the
  three-layer "freedom acquired" stinger (power / mechanical / sync bands,
  per the design doc)
- `door_open.ogg`, `door_locked.ogg`
- `terminal_beep.ogg`
- `ui_click.ogg`
- `alien_crawler_hit.ogg` — generic enemy attack-lands sound
- `alien_death.ogg`
- `player_hurt.ogg`, `player_death.ogg`
- `scan_activate.ogg` — pickups, fragment collection, Vector scan-take
- `freedom_take.ogg`, `freedom_transfer.ogg` — the Vector's TAKE/STORE vs
  TRANSFER/RETURN operations
- `checkpoint.ogg`

`alarm_warning.ogg` is referenced in the design doc but not yet called from
code — hook it up wherever a future hazard/alarm needs it.
