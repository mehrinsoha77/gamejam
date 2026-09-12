class_name Phaser
extends EnemyBase
## Introduces enemy freedom manipulation: the Phaser periodically DISABLES
## its own TRANS_Z (phases out — briefly immune to being pushed/strafed
## around and immune to Vector Weapon strips on that axis) then re-enables
## it to lunge. A preview of what the player will later be able to do to
## others with the Vector.

@export var phase_interval: float = 2.5
var _phase_timer: float = 0.0
var _phased: bool = false

func _init() -> void:
	display_name = "PHASER"
	max_health = 28.0
	move_speed = 3.2
	attack_damage = 9.0
	attack_range = 1.7
	detect_range = 13.0
	freedom_point_reward = 16
	preferred_dof_to_strip = FreedomComponent.DOF.TRANS_X

func _configure_freedom() -> void:
	freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOF.ROT_YAW]
	for dof in freedom_component.relevant_dof:
		freedom_component.unlock(dof)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DEAD:
		return
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase_timer = phase_interval
		_phased = not _phased
		if _phased:
			freedom_component.set_state(FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOFState.DISABLED)
		else:
			freedom_component.set_state(FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOFState.UNLOCKED)
