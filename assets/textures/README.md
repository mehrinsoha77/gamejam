# Textures

All materials in the project are currently flat-colored `StandardMaterial3D`
resources generated in code (see `EnvironmentGenerator.make_material()` in
`scripts/environment/environment_generator.gd`). Drop texture files here
(`.png`/`.jpg`, prefer power-of-two sizes) and wire them in by setting
`albedo_texture` (and `normal_texture`, `roughness_texture`, etc.) on the
materials that function builds, or by extending it with a
`texture: Texture2D` parameter. Suggested naming: `metal_panel_albedo.png`,
`metal_panel_normal.png`, `emergency_grate_albedo.png`, etc.
