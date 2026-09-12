class_name EnvironmentGenerator
extends RefCounted
## Reusable, code-driven building blocks for hand-authored (not random)
## level geometry. Everything here is StandardMaterial3D + primitive
## meshes so the game is playable today with zero art assets — see
## ASSETS_NEEDED.md for how to layer real models/textures on top later
## without touching gameplay code.

# ---- Color language (see ARCHITECTURE.md "Visual Style") ----
const COLOR_NEUTRAL := Color(0.24, 0.26, 0.3)
const COLOR_NEUTRAL_DARK := Color(0.14, 0.15, 0.18)
const COLOR_INTERACTIVE := Color(0.25, 0.75, 1.0)
const COLOR_WARNING := Color(1.0, 0.7, 0.15)
const COLOR_DANGER := Color(0.9, 0.15, 0.15)
const COLOR_FREEDOM := Color(0.6, 0.35, 1.0)
const COLOR_ALIEN := Color(0.25, 0.85, 0.55)

static func make_material(color: Color, emission: Color = Color(0, 0, 0), emission_energy: float = 0.0, roughness: float = 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.15
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat

static func _add_box_body(parent: Node3D, center: Vector3, size: Vector3, material: Material, name_hint: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name_hint
	body.position = center
	body.set_collision_layer_value(1, true)
	parent.add_child(body)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	return body

## A room/corridor segment. `size` = (width X, height Y, depth Z).
## `open_sides` may contain "north" (+Z), "south" (-Z), "east" (+X), "west" (-X)
## to leave a `door_width`-wide gap in that wall (for corridor connections /
## windows) instead of removing the whole face — otherwise a wide room with
## a narrow connecting corridor would leave the player able to walk off the
## sides of the opening into empty space.
static func create_room(parent: Node3D, center: Vector3, size: Vector3, wall_material: Material, floor_material: Material = null, ceiling_material: Material = null, open_sides: Array = [], door_width: float = 2.6) -> Node3D:
	var root := Node3D.new()
	root.position = center
	parent.add_child(root)

	var fm := floor_material if floor_material else wall_material
	var cm := ceiling_material if ceiling_material else wall_material
	var thickness := 0.3

	_add_box_body(root, Vector3(0, -thickness / 2.0, 0), Vector3(size.x, thickness, size.z), fm, "Floor")
	_add_box_body(root, Vector3(0, size.y + thickness / 2.0, 0), Vector3(size.x, thickness, size.z), cm, "Ceiling")

	_add_ns_wall(root, size, thickness, wall_material, size.z / 2.0, "WallNorth", open_sides.has("north"), door_width)
	_add_ns_wall(root, size, thickness, wall_material, -size.z / 2.0, "WallSouth", open_sides.has("south"), door_width)
	_add_ew_wall(root, size, thickness, wall_material, size.x / 2.0, "WallEast", open_sides.has("east"), door_width)
	_add_ew_wall(root, size, thickness, wall_material, -size.x / 2.0, "WallWest", open_sides.has("west"), door_width)

	return root

## North/south walls run along X at a fixed Z edge.
static func _add_ns_wall(root: Node3D, size: Vector3, thickness: float, material: Material, z_edge: float, name_hint: String, is_open: bool, door_width: float) -> void:
	var z := z_edge + (thickness / 2.0 if z_edge > 0 else -thickness / 2.0)
	if not is_open:
		_add_box_body(root, Vector3(0, size.y / 2.0, z), Vector3(size.x, size.y, thickness), material, name_hint)
		return
	var flank := (size.x - door_width) / 2.0
	if flank <= 0.05:
		return
	_add_box_body(root, Vector3(-(door_width / 2.0 + flank / 2.0), size.y / 2.0, z), Vector3(flank, size.y, thickness), material, name_hint + "_L")
	_add_box_body(root, Vector3(door_width / 2.0 + flank / 2.0, size.y / 2.0, z), Vector3(flank, size.y, thickness), material, name_hint + "_R")

## East/west walls run along Z at a fixed X edge.
static func _add_ew_wall(root: Node3D, size: Vector3, thickness: float, material: Material, x_edge: float, name_hint: String, is_open: bool, door_width: float) -> void:
	var x := x_edge + (thickness / 2.0 if x_edge > 0 else -thickness / 2.0)
	if not is_open:
		_add_box_body(root, Vector3(x, size.y / 2.0, 0), Vector3(thickness, size.y, size.z), material, name_hint)
		return
	var flank := (size.z - door_width) / 2.0
	if flank <= 0.05:
		return
	_add_box_body(root, Vector3(x, size.y / 2.0, -(door_width / 2.0 + flank / 2.0)), Vector3(thickness, size.y, flank), material, name_hint + "_A")
	_add_box_body(root, Vector3(x, size.y / 2.0, door_width / 2.0 + flank / 2.0), Vector3(thickness, size.y, flank), material, name_hint + "_B")

static func create_corridor(parent: Node3D, center: Vector3, width: float, height: float, length: float, material: Material) -> Node3D:
	return create_room(parent, center, Vector3(width, height, length), material, null, null, ["north", "south"], width)

static func create_light(parent: Node3D, position: Vector3, color: Color, energy: float = 1.2, light_range: float = 8.0) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	parent.add_child(light)
	return light

static func create_dust_particles(parent: Node3D, position: Vector3, spread: Vector3 = Vector3(3, 2, 3)) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.position = position
	particles.amount = 40
	particles.lifetime = 6.0
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.gravity = Vector3(0, 0.02, 0)
	mat.initial_velocity_min = 0.02
	mat.initial_velocity_max = 0.1
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = spread
	mat.scale_min = 0.01
	mat.scale_max = 0.03
	particles.process_material = mat
	particles.draw_pass_1 = SphereMesh.new()
	parent.add_child(particles)
	return particles

static func create_debris(parent: Node3D, position: Vector3, count: int = 4, area: Vector3 = Vector3(2, 0, 2)) -> Node3D:
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	var mat := make_material(COLOR_NEUTRAL_DARK)
	for i in range(count):
		var box := MeshInstance3D.new()
		var size := Vector3(randf_range(0.1, 0.35), randf_range(0.05, 0.2), randf_range(0.1, 0.35))
		var bm := BoxMesh.new()
		bm.size = size
		box.mesh = bm
		box.material_override = mat
		box.position = Vector3(randf_range(-area.x, area.x), size.y / 2.0, randf_range(-area.z, area.z))
		box.rotation.y = randf_range(0, TAU)
		root.add_child(box)
	return root

static func create_alien_growth(parent: Node3D, position: Vector3, scale_mult: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	var mat := make_material(COLOR_ALIEN, COLOR_ALIEN, 0.6, 0.5)
	for i in range(5):
		var sphere := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = randf_range(0.08, 0.22) * scale_mult
		sm.height = sm.radius * 2.0
		sphere.mesh = sm
		sphere.material_override = mat
		sphere.position = Vector3(randf_range(-0.3, 0.3), randf_range(-0.1, 0.3), randf_range(-0.3, 0.3)) * scale_mult
		root.add_child(sphere)
	return root

static func create_pipe(parent: Node3D, from: Vector3, to: Vector3, radius: float = 0.08, material: Material = null) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = from.distance_to(to)
	mesh_instance.mesh = cyl
	mesh_instance.material_override = material if material else make_material(COLOR_NEUTRAL_DARK)
	var mid := (from + to) / 2.0
	mesh_instance.position = mid
	mesh_instance.look_at_from_position(mid, to, Vector3.UP)
	mesh_instance.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	parent.add_child(mesh_instance)
	return mesh_instance

## Distant planet backdrop seen through a level's window openings.
static func create_planet(parent: Node3D, position: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_instance.mesh = sphere
	mesh_instance.material_override = make_material(color, color * 0.3, 0.4, 1.0)
	mesh_instance.position = position
	parent.add_child(mesh_instance)
	return mesh_instance

## Sky + fog + ambient setup, one per level. Colors vary per act (see
## LEVEL_DESIGN.md "exterior views").
static func setup_world_environment(scene: Node, sky_top: Color, sky_horizon: Color, fog_color: Color, fog_enabled: bool = true) -> WorldEnvironment:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = sky_top
	sky_material.sky_horizon_color = sky_horizon
	sky_material.ground_bottom_color = sky_horizon
	sky_material.ground_horizon_color = sky_horizon
	var sky := Sky.new()
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.fog_enabled = fog_enabled
	env.fog_light_color = fog_color
	env.fog_density = 0.01
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	scene.add_child(world_env)
	return world_env
