class_name FreedomLeech
extends EnemyBase
## On a successful hit, steals one of the player's currently-free translation
## DOFs for a few seconds — the HUD visibly flips it to LOCKED. This is the
## enemy designed to make the player *afraid* of losing freedom, not just
## afraid of dying.

@export var steal_duration: float = 3.5

func _init() -> void:
	display_name = "FREEDOM LEECH"
	max_health = 30.0
	move_speed = 2.6
	attack_damage = 4.0
	attack_range = 1.8
	detect_range = 11.0
	freedom_point_reward = 15
	preferred_dof_to_strip = FreedomComponent.DOF.TRANS_Z

func _configure_freedom() -> void:
	freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOF.ROT_YAW]
	for dof in freedom_component.relevant_dof:
		freedom_component.unlock(dof)

func _perform_attack() -> void:
	if _target == null:
		return
	if _target.has_method("take_damage"):
		_target.take_damage(attack_damage, self)
	if _target.has_node("FreedomComponent"):
		var player_fc: FreedomComponent = _target.get_node("FreedomComponent")
		var candidates := [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOF.TRANS_Y]
		candidates.shuffle()
		for dof in candidates:
			if player_fc.is_free(dof):
				player_fc.steal(dof)
				var stolen_dof := dof
				get_tree().create_timer(steal_duration).timeout.connect(func():
					if is_instance_valid(player_fc):
						player_fc.restore_stolen(stolen_dof)
				)
				break
	AudioManager.play_sfx("alien_crawler_hit")
