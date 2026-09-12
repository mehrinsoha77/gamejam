class_name Door
extends Interactable
## A sliding door, self-contained: builds its own visual panel + a solid
## physical blocker, so level scripts just instance one and set door_size.
## Can be a plain locked/unlocked prop, or (when `freedom_gated` is true)
## an object with its own FreedomComponent whose TRANS_Y must be free for
## it to open — a simple, early example of the freedom-transfer puzzles
## that get more elaborate from Level 4 onward.

signal opened
signal closed

@export var freedom_gated: bool = false
@export var locked: bool = false
@export var door_size: Vector3 = Vector3(2.2, 2.6, 0.3)
@export var slide_distance: float = 2.6
@export var slide_time: float = 0.8
@export var door_color: Color = EnvironmentGenerator.COLOR_NEUTRAL

var _is_open: bool = false
var _closed_position: Vector3
var _mesh: MeshInstance3D
var _blocker: StaticBody3D
var _blocker_shape: CollisionShape3D

func _ready() -> void:
	super._ready()
	prompt_text = "OPEN DOOR"
	if freedom_gated:
		freedom_component = FreedomComponent.new()
		freedom_component.name = "FreedomComponent"
		freedom_component.display_name = "SECURITY DOOR"
		freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_Y]
		add_child(freedom_component)
	_closed_position = position

	var interact_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = door_size
	interact_shape.shape = box
	add_child(interact_shape)

	_mesh = MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = door_size
	_mesh.mesh = box_mesh
	_mesh.material_override = EnvironmentGenerator.make_material(door_color, EnvironmentGenerator.COLOR_WARNING if locked else EnvironmentGenerator.COLOR_INTERACTIVE, 0.6)
	add_child(_mesh)

	_blocker = StaticBody3D.new()
	_blocker.set_collision_layer_value(1, true)
	get_parent().add_child(_blocker)
	_blocker.global_position = global_position
	_blocker_shape = CollisionShape3D.new()
	var blocker_box := BoxShape3D.new()
	blocker_box.size = door_size
	_blocker_shape.shape = blocker_box
	_blocker.add_child(_blocker_shape)

func can_interact(_player: Node) -> bool:
	if not enabled or _is_open:
		return false
	if locked:
		return false
	if freedom_gated and not freedom_component.is_free(FreedomComponent.DOF.TRANS_Y):
		return false
	return true

func get_prompt() -> String:
	if locked:
		return "LOCKED"
	if freedom_gated and not freedom_component.is_free(FreedomComponent.DOF.TRANS_Y):
		return "NO POWER — REQUIRES Y-AXIS FREEDOM"
	return "OPEN DOOR"

func interact(_player: Node) -> void:
	if not can_interact(_player):
		AudioManager.play_sfx("door_locked")
		return
	open()

func open() -> void:
	if _is_open:
		return
	_is_open = true
	AudioManager.play_sfx("door_open")
	var target := _closed_position + Vector3.UP * slide_distance
	var tween := create_tween()
	tween.tween_property(self, "position", target, slide_time)
	_blocker_shape.set_deferred("disabled", true)
	opened.emit()

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	var tween := create_tween()
	tween.tween_property(self, "position", _closed_position, slide_time)
	_blocker_shape.set_deferred("disabled", false)
	closed.emit()

func force_unlock_and_open() -> void:
	locked = false
	open()
