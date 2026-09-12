class_name AnchorAlien
extends EnemyBase
## Creates a local constraint field: while it's alive and within
## `field_radius` of the player, one of the player's translation DOFs is
## held DISABLED. This is the enemy that makes the player *feel* what it's
## like to be constrained, mirroring the game's opening hours back at them.

@export var field_radius: float = 6.0
var _held_dof: int = -1
var _player_fc: FreedomComponent = null

func _init() -> void:
	display_name = "ANCHOR"
	max_health = 50.0
	move_speed = 1.2
	attack_damage = 6.0
	attack_range = 2.0
	detect_range = 10.0
	freedom_point_reward = 18
	preferred_dof_to_strip = FreedomComponent.DOF.TRANS_X

func _configure_freedom() -> void:
	freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Z]
	for dof in freedom_component.relevant_dof:
		freedom_component.unlock(dof)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DEAD:
		_release_field()
		return
	if _target and _target.has_node("FreedomComponent"):
		var dist := global_position.distance_to(_target.global_position)
		if dist <= field_radius:
			_apply_field(_target.get_node("FreedomComponent"))
			return
	_release_field()

func _apply_field(player_fc: FreedomComponent) -> void:
	if _held_dof != -1 and _player_fc == player_fc:
		return
	_release_field()
	_player_fc = player_fc
	var candidates := [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Z]
	for dof in candidates:
		if player_fc.is_free(dof):
			_held_dof = dof
			player_fc.set_state(dof, FreedomComponent.DOFState.DISABLED)
			break

func _release_field() -> void:
	if _held_dof != -1 and is_instance_valid(_player_fc):
		if _player_fc.get_state(_held_dof) == FreedomComponent.DOFState.DISABLED:
			_player_fc.set_state(_held_dof, FreedomComponent.DOFState.UNLOCKED)
	_held_dof = -1
	_player_fc = null

func _die() -> void:
	_release_field()
	super._die()
