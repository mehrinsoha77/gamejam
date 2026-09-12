class_name ElevatorPlatform
extends Interactable
## The textbook example from the design doc: this platform "owns" TRANS_Y.
## Scan it with the Vector and TAKE that freedom directly — the elevator
## seizes up (LOCKED, stops moving) and the player gains Y translation
## (can now jump/ascend) until they RETURN it. Direct [E] interaction (no
## Vector required) just calls it up and down for players who haven't
## found the Vector yet — a simple visual lift, not a physics carrier, to
## keep this optional bonus prop low-risk without an editor to test in.

@export var top_y: float = 6.0
@export var ride_time: float = 3.0

var _platform_mesh: Node3D
var _base_y: float
var _riding: bool = false

func _ready() -> void:
	super._ready()
	prompt_text = "CALL ELEVATOR"
	freedom_component = FreedomComponent.new()
	freedom_component.name = "FreedomComponent"
	freedom_component.display_name = "ELEVATOR PLATFORM"
	freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_Y]
	add_child(freedom_component)
	freedom_component.unlock(FreedomComponent.DOF.TRANS_Y)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.8, 0.4)
	shape.shape = box
	add_child(shape)
	var panel_mesh := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.4, 0.6, 0.15)
	panel_mesh.mesh = pm
	panel_mesh.material_override = EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL, EnvironmentGenerator.COLOR_INTERACTIVE, 0.9)
	add_child(panel_mesh)

func set_platform_mesh(mesh: Node3D) -> void:
	_platform_mesh = mesh
	_base_y = mesh.position.y

func can_interact(_player: Node) -> bool:
	return enabled and not _riding and freedom_component.is_free(FreedomComponent.DOF.TRANS_Y)

func get_prompt() -> String:
	if not freedom_component.is_free(FreedomComponent.DOF.TRANS_Y):
		return "POWER TAKEN — ELEVATOR OFFLINE"
	return "CALL ELEVATOR"

func interact(_player: Node) -> void:
	if not can_interact(_player) or _platform_mesh == null:
		AudioManager.play_sfx("door_locked")
		return
	_riding = true
	AudioManager.play_sfx("door_open")
	var target_y: float = top_y if _platform_mesh.position.y < _base_y + 0.1 else _base_y
	var tween := create_tween()
	tween.tween_property(_platform_mesh, "position:y", target_y, ride_time)
	tween.tween_callback(func(): _riding = false)
