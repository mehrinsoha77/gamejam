# Enemy models

Drop rigged/unrigged `.glb` or `.gltf` files here, one per archetype. Suggested names (match the `display_name` used in each enemy script so it's easy to find the right file):

- `crawler.glb`
- `leaper.glb`
- `flyer.glb`
- `spinner.glb`
- `phaser.glb`
- `anchor.glb`
- `mimic.glb`
- `freedom_leech.glb`
- `guardian.glb`
- `the_unbound.glb`

None of the enemy scripts hardcode a mesh — they're currently invisible CharacterBody3D logic only (collision + AI + FreedomComponent, no visual). See `ASSETS_NEEDED.md` at the project root for how to wire a model into `EnemyBase` once you have one.
