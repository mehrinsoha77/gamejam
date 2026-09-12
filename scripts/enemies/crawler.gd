class_name Crawler
extends EnemyBase
## Ground-bound melee alien. X/Z translation only, no vertical freedom.
## Teaches the player basic aim-and-shoot combat with the Energy Weapon.

func _init() -> void:
	display_name = "CRAWLER"
	max_health = 35.0
	move_speed = 3.0
	attack_damage = 8.0
	attack_range = 1.6
	detect_range = 12.0
	freedom_point_reward = 10
	preferred_dof_to_strip = FreedomComponent.DOF.TRANS_X
	body_color = Color(0.75, 0.25, 0.3)

func _configure_freedom() -> void:
	freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOF.ROT_YAW]
	for dof in freedom_component.relevant_dof:
		freedom_component.unlock(dof)
