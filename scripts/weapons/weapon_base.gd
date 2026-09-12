class_name WeaponBase
extends Node3D
## Base class for anything mounted in WeaponSystem's slot list.
## Subclasses override primary_fire()/secondary_fire(). Damage-dealing is
## optional — the Vector and Anchor "weapons" manipulate DOF instead of HP.

@export var weapon_name: String = "WEAPON"
@export var fire_cooldown: float = 0.4
@export var range_meters: float = 40.0

var owner_player: Node = null
var _cooldown_timer: float = 0.0

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

func equip(player: Node) -> void:
	owner_player = player

func can_fire() -> bool:
	return _cooldown_timer <= 0.0

func _start_cooldown() -> void:
	_cooldown_timer = fire_cooldown

## Called on fire_primary press.
func primary_fire() -> void:
	pass

## Called on fire_secondary press.
func secondary_fire() -> void:
	pass

func _get_interaction() -> InteractionComponent:
	if owner_player and owner_player.has_node("InteractionComponent"):
		return owner_player.get_node("InteractionComponent")
	return null
