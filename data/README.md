# Data

Reserved for data-driven content once levels 2-5 are built out: puzzle
solutions, dialogue/lore tables, and enemy/level configs as `.tres`
Resource files or JSON, so a level designer can tune content without
touching GDScript. Nothing reads from this folder yet — Level 1's dialogue
and puzzle data live inline in `scripts/levels/level_1.gd` for now (see
`ARCHITECTURE.md` for why that's fine at this scale, and where the line is
for when to move it out here).
