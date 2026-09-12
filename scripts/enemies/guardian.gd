class_name Guardian
extends EnemyBase
## Tier-2 scaffold: protects a Freedom Core fragment (Level 5) with a
## multi-phase DOF fight. Phase transitions are wired here so a future pass
## just needs to build the arena and call advance_phase() from triggers;
## the combat-relevant DOF behavior per phase already works.

signal phase_changed(phase: int)

@export var phase_count: int = 3
var phase: int = 0

func _init() -> void:
	display_name = "GUARDIAN"
	max_health = 220.0
	move_speed = 2.2
	attack_damage = 14.0
	attack_range = 2.4
	detect_range = 20.0
	freedom_point_reward = 60
	preferred_dof_to_strip = FreedomComponent.DOF.TRANS_Z

func _configure_freedom() -> void:
	# Phase 0: only translation. Rotation and vertical freedom are granted
	# as the fight escalates via advance_phase().
	freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOF.TRANS_Y, FreedomComponent.DOF.ROT_YAW, FreedomComponent.DOF.ROT_PITCH]
	freedom_component.unlock(FreedomComponent.DOF.TRANS_X)
	freedom_component.unlock(FreedomComponent.DOF.TRANS_Z)
	freedom_component.unlock(FreedomComponent.DOF.ROT_YAW)

func advance_phase() -> void:
	phase += 1
	phase_changed.emit(phase)
	match phase:
		1:
			freedom_component.unlock(FreedomComponent.DOF.TRANS_Y)
			move_speed *= 1.15
		2:
			freedom_component.unlock(FreedomComponent.DOF.ROT_PITCH)
			attack_damage *= 1.2

func take_damage(amount: float, source: Node = null) -> void:
	super.take_damage(amount, source)
	var health_ratio := health / max_health
	var expected_phase: int = clampi(int((1.0 - health_ratio) * phase_count), 0, phase_count - 1)
	if expected_phase > phase:
		advance_phase()
