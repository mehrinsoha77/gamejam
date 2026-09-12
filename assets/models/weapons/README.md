# Weapon viewmodels

No weapon currently has a visible mesh — `WeaponBase` and its subclasses
(`scripts/weapons/*.gd`) are pure logic nodes (`Node3D`, no `MeshInstance3D`)
parented under the player's camera via `WeaponSystem`. Drop first-person
viewmodel `.glb` files here (e.g. `energy_weapon.glb`, `vector_weapon.glb`,
`anchor_weapon.glb`, `the_vector.glb`) and instance them as a child
`MeshInstance3D`/scene under each weapon's `equip()` method.
