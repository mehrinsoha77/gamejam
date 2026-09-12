class_name Spinner
extends EnemyBase
## Limited translation, high rotational freedom. Spins in place, making it
## hard to hit a weak point and teaching the player to track orientation,
## not just position.

@export var spin_speed: float = 4.0

func _init() -> void:
	display_name = "SPINNER"
	max_health = 32.0
	move_speed = 1.6
	attack_damage = 9.0
	attack_range = 2.0
	detect_range = 12.0
	freedom_point_reward = 13
	preferred_dof_to_strip = FreedomComponent.DOF.ROT_YAW

func _configure_freedom() -> void:
	freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.ROT_PITCH, FreedomComponent.DOF.ROT_YAW, FreedomComponent.DOF.ROT_ROLL]
	for dof in freedom_component.relevant_dof:
		freedom_component.unlock(dof)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state != State.DEAD and freedom_component.is_free(FreedomComponent.DOF.ROT_YAW):
		rotate_y(spin_speed * delta)
