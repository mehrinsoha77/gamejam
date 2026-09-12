# Prop / environment models

Drop `.glb`/`.gltf` files here for hand-placed set dressing: terminals, doors, pipes, machinery, alien architecture, the Freedom Core itself, etc.

Everything in `scripts/systems/` and `scripts/environment/environment_generator.gd` currently builds its visuals from primitive meshes (boxes, cylinders, spheres) with plain colored materials — see `ASSETS_NEEDED.md` at the project root for the swap-in pattern (each prop script builds its own mesh in `_ready()`; replace the `MeshInstance3D.mesh = BoxMesh.new()` lines with a loaded model, keeping the existing `CollisionShape3D` sizes so physics stays correct).
