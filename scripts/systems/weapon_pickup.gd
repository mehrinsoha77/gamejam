class_name WeaponPickup
extends Interactable
## Wall rack / floor pickup that grants a weapon to the player's
## WeaponSystem on interact, then disables itself.

signal collected

@export var weapon_script: Script
@export var pickup_label: String = "WEAPON"

var _collected: bool = false

func _ready() -> void:
	super._ready()
	prompt_text = "TAKE " + pickup_label
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.7, 0.7, 0.7)
	shape.shape = box
	add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.2, 0.15)
	mesh_instance.mesh = bm
	mesh_instance.material_override = EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL, EnvironmentGenerator.COLOR_WARNING, 0.9)
	add_child(mesh_instance)

func can_interact(_player: Node) -> bool:
	return enabled and not _collected and weapon_script != null

func interact(player: Node) -> void:
	if not can_interact(player):
		return
	_collected = true
	visible = false
	set_deferred("monitoring", false)
	var weapon: WeaponBase = weapon_script.new()
	player.weapon_system.add_weapon(weapon, player)
	AudioManager.play_sfx("scan_activate")
	collected.emit()
