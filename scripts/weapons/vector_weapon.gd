class_name VectorWeapon
extends WeaponBase
## "Which freedom should I remove?" weapon. Primary fire temporarily disables
## one translational DOF on the target (whichever one it most depends on to
## fight effectively — see EnemyBase.preferred_dof_to_strip). Secondary fire
## restores it early (used to set up FREEDOM CHAIN BONUS combos with allies
## or to undo a mistaken strip).

@export var strip_duration: float = 4.0
@export var chain_bonus_points: int = 15

func _init() -> void:
	weapon_name = "VECTOR WEAPON"
	fire_cooldown = 1.2
	range_meters = 30.0

func primary_fire() -> void:
	if not can_fire():
		return
	var interaction := _get_interaction()
	if interaction == null:
		return
	var result := interaction.raycast_body(range_meters)
	if result.is_empty():
		return
	var collider = result.get("collider")
	if not (collider and collider.has_node("FreedomComponent")):
		return
	_start_cooldown()
	AudioManager.play_sfx("weapon_vector_fire")
	var fc: FreedomComponent = collider.get_node("FreedomComponent")
	var dof: int = collider.preferred_dof_to_strip if "preferred_dof_to_strip" in collider else FreedomComponent.DOF.TRANS_Z
	if not fc.is_free(dof):
		return
	fc.set_state(dof, FreedomComponent.DOFState.DISABLED)
	if collider.has_method("on_dof_stripped"):
		collider.on_dof_stripped(dof)
	get_tree().create_timer(strip_duration).timeout.connect(func():
		if is_instance_valid(fc) and fc.get_state(dof) == FreedomComponent.DOFState.DISABLED:
			fc.set_state(dof, FreedomComponent.DOFState.UNLOCKED)
	)

func secondary_fire() -> void:
	pass
