class_name Mimic
extends EnemyBase
## Copies the player's currently-free translation DOFs onto itself every
## few seconds — if the player is fully mobile, so is the Mimic. Creates
## psychological tension: taking freedom away from yourself (e.g. retreating
## into a locked corridor) is sometimes the safer play against this enemy.

@export var mimic_interval: float = 3.0
var _mimic_timer: float = 0.0

func _init() -> void:
	display_name = "MIMIC"
	max_health = 34.0
	move_speed = 3.0
	attack_damage = 9.0
	attack_range = 1.7
	detect_range = 12.0
	freedom_point_reward = 20
	preferred_dof_to_strip = FreedomComponent.DOF.TRANS_Z

func _configure_freedom() -> void:
	freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Y, FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOF.ROT_YAW]
	freedom_component.unlock(FreedomComponent.DOF.ROT_YAW)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DEAD:
		return
	_mimic_timer -= delta
	if _mimic_timer <= 0.0:
		_mimic_timer = mimic_interval
		if _target and _target.has_node("FreedomComponent"):
			var player_fc: FreedomComponent = _target.get_node("FreedomComponent")
			for dof in [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Y, FreedomComponent.DOF.TRANS_Z]:
				if player_fc.is_free(dof):
					freedom_component.unlock(dof)
				else:
					freedom_component.lock(dof)
