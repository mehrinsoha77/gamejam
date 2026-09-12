class_name WeaponSystem
extends Node3D
## Holds the player's equipped tools and routes fire input + switching.
## Weapons are added via add_weapon() as they're picked up in the world —
## the player does not start with all four (see level scripts for pickups).

signal weapon_switched(index: int, weapon: WeaponBase)

var weapons: Array[WeaponBase] = []
var current_index: int = -1

func add_weapon(weapon: WeaponBase, player: Node) -> void:
	add_child(weapon)
	weapon.equip(player)
	weapons.append(weapon)
	if current_index == -1:
		current_index = weapons.size() - 1
		weapon_switched.emit(current_index, weapons[current_index])

func has_weapon(script_class: Script) -> bool:
	for w in weapons:
		if w.get_script() == script_class:
			return true
	return false

func switch_to(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return
	current_index = index
	weapon_switched.emit(current_index, weapons[current_index])
	AudioManager.play_sfx("ui_click")

func current_weapon() -> WeaponBase:
	if current_index < 0 or current_index >= weapons.size():
		return null
	return weapons[current_index]

func fire_primary() -> void:
	var w := current_weapon()
	if w:
		w.primary_fire()

func fire_secondary() -> void:
	var w := current_weapon()
	if w:
		w.secondary_fire()

func cycle_next() -> void:
	if weapons.is_empty():
		return
	switch_to((current_index + 1) % weapons.size())
