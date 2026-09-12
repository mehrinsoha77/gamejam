class_name TheUnbound
extends EnemyBase
## Tier-2 scaffold for the Final Act boss. Starts with all six DOF —
## the fight is won by using the Vector/Anchor/Vector-Weapon kit to strip
## them down one at a time (X, then Z, then Y, then rotation) rather than
## a flat damage race. The constrain sequence below is functional; the
## arena, scripted phase triggers and unique attacks per phase still need
## a full level-design pass (see LEVEL_DESIGN.md).

signal constrained(dof: int)
signal fully_constrained

const CONSTRAIN_ORDER := [
	FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Z,
	FreedomComponent.DOF.TRANS_Y, FreedomComponent.DOF.ROT_YAW,
	FreedomComponent.DOF.ROT_PITCH, FreedomComponent.DOF.ROT_ROLL,
]
var _next_to_constrain_index: int = 0

func _init() -> void:
	display_name = "THE UNBOUND"
	max_health = 500.0
	move_speed = 3.6
	attack_damage = 20.0
	attack_range = 3.0
	detect_range = 30.0
	freedom_point_reward = 150

func _configure_freedom() -> void:
	freedom_component.relevant_dof = CONSTRAIN_ORDER.duplicate()
	for dof in freedom_component.relevant_dof:
		freedom_component.unlock(dof)

func zero_gravity_capable() -> bool:
	return true

## Called by the Vector/Vector-Weapon/Anchor whenever they successfully
## strip a DOF from this boss — advances the intended constrain sequence
## and checks for the immobilized "expose the core" state.
func on_dof_stripped(dof: int) -> void:
	super.on_dof_stripped(dof)
	constrained.emit(dof)
	if get_free_dof_count() == 0:
		fully_constrained.emit()

func get_free_dof_count() -> int:
	var count := 0
	for dof in freedom_component.relevant_dof:
		if freedom_component.is_free(dof):
			count += 1
	return count

func next_intended_target() -> int:
	return CONSTRAIN_ORDER[_next_to_constrain_index] if _next_to_constrain_index < CONSTRAIN_ORDER.size() else -1
