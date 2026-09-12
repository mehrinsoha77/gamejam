class_name Leaper
extends EnemyBase
## Has vertical freedom and leaps unpredictably. Teaches the player to track
## a target that can suddenly change elevation.

var _jump_timer: float = 0.0

func _init() -> void:
	display_name = "LEAPER"
	max_health = 30.0
	move_speed = 3.4
	attack_damage = 10.0
	attack_range = 1.8
	detect_range = 13.0
	freedom_point_reward = 12
	preferred_dof_to_strip = FreedomComponent.DOF.TRANS_Y

func _configure_freedom() -> void:
	freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Y, FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOF.ROT_YAW]
	for dof in freedom_component.relevant_dof:
		freedom_component.unlock(dof)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DEAD:
		return
	_jump_timer -= delta
	if state == State.CHASE and _jump_timer <= 0.0 and is_on_floor() and freedom_component.is_free(FreedomComponent.DOF.TRANS_Y):
		_jump_timer = randf_range(1.2, 2.6)
		velocity.y = 6.0
