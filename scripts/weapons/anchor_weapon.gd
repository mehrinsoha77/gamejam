class_name AnchorWeapon
extends WeaponBase
## Restricts movement in an area rather than targeting one enemy. Fires a
## slow-moving anchor charge that, on impact, locks TRANS_X/Y/Z for every
## enemy FreedomComponent inside a radius for a few seconds. Good for
## grounding Flyers/Spinners or freezing a crowd before an Energy Weapon pass.

@export var field_radius: float = 5.0
@export var field_duration: float = 3.5
@export var projectile_speed: float = 18.0

func _init() -> void:
	weapon_name = "ANCHOR WEAPON"
	fire_cooldown = 2.5
	range_meters = 35.0

func primary_fire() -> void:
	if not can_fire():
		return
	var interaction := _get_interaction()
	if interaction == null:
		return
	_start_cooldown()
	AudioManager.play_sfx("weapon_anchor_fire")
	var result := interaction.raycast_body(range_meters)
	var impact_pos: Vector3 = owner_player.global_position - owner_player.global_transform.basis.z * range_meters
	if not result.is_empty():
		impact_pos = result.get("position", impact_pos)
	_trigger_field(impact_pos)

func _trigger_field(center: Vector3) -> void:
	var space_state := get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = field_radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), center)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var hits := space_state.intersect_shape(params, 32)
	for hit in hits:
		var collider = hit.get("collider")
		if collider and collider.has_node("FreedomComponent") and collider.is_in_group("enemy"):
			var fc: FreedomComponent = collider.get_node("FreedomComponent")
			_anchor_component(fc)

func _anchor_component(fc: FreedomComponent) -> void:
	var axes := [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Y, FreedomComponent.DOF.TRANS_Z]
	var restored: Array = []
	for dof in axes:
		if fc.is_free(dof):
			fc.set_state(dof, FreedomComponent.DOFState.DISABLED)
			restored.append(dof)
	get_tree().create_timer(field_duration).timeout.connect(func():
		if is_instance_valid(fc):
			for dof in restored:
				if fc.get_state(dof) == FreedomComponent.DOFState.DISABLED:
					fc.set_state(dof, FreedomComponent.DOFState.UNLOCKED)
	)
