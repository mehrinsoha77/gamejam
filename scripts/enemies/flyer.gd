class_name Flyer
extends EnemyBase
## Full XYZ translation, ignores gravity, orbits the player at range and
## dives in to attack. Teaches 3D targeting — the player must aim up.

@export var hover_height: float = 3.0
@export var orbit_speed: float = 1.2
var _orbit_angle: float = 0.0

func _init() -> void:
	display_name = "FLYER"
	max_health = 25.0
	move_speed = 4.5
	attack_damage = 7.0
	attack_range = 2.2
	detect_range = 16.0
	freedom_point_reward = 14
	preferred_dof_to_strip = FreedomComponent.DOF.TRANS_Y

func _configure_freedom() -> void:
	freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Y, FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOF.ROT_YAW]
	for dof in freedom_component.relevant_dof:
		freedom_component.unlock(dof)

func zero_gravity_capable() -> bool:
	return true

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_acquire_target()
	if state == State.IDLE or _target == null:
		move_and_slide()
		return
	_orbit_angle += orbit_speed * delta
	var can_x := freedom_component.is_free(FreedomComponent.DOF.TRANS_X)
	var can_y := freedom_component.is_free(FreedomComponent.DOF.TRANS_Y)
	var can_z := freedom_component.is_free(FreedomComponent.DOF.TRANS_Z)
	var desired := _target.global_position
	if can_x and can_z:
		desired += Vector3(cos(_orbit_angle), 0.0, sin(_orbit_angle)) * attack_range * 1.8
	if can_y:
		desired.y = _target.global_position.y + hover_height
	var to_desired := desired - global_position
	velocity = velocity.lerp(to_desired.limit_length(move_speed), 0.15)
	if global_position.distance_to(_target.global_position) <= attack_range:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			_perform_attack()
	move_and_slide()
