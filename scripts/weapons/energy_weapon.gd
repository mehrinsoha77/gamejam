class_name EnergyWeapon
extends WeaponBase
## Basic sidearm. Straightforward hitscan damage — the "how much damage"
## weapon, contrasted with the Vector/Anchor which ask "which freedom".

@export var damage: float = 18.0

func _init() -> void:
	weapon_name = "ENERGY WEAPON"
	fire_cooldown = 0.25
	range_meters = 40.0

func primary_fire() -> void:
	if not can_fire():
		return
	var interaction := _get_interaction()
	if interaction == null:
		return
	_start_cooldown()
	AudioManager.play_sfx("weapon_energy_fire")
	var result := interaction.raycast_body(range_meters)
	if result.is_empty():
		return
	var collider = result.get("collider")
	if collider and collider.has_method("take_damage"):
		collider.take_damage(damage, owner_player)
