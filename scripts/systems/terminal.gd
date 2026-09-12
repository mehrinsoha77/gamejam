class_name Terminal
extends Interactable
## Wall terminal that plays a short AI/story transmission when interacted
## with. Self-contained visual + collision shape — a level script just
## instances one, sets `lines`, and positions it.

@export var lines: Array[String] = []
@export var speaker: String = "AI SYSTEM"
@export var once: bool = true
@export var slow_time: bool = false
@export var terminal_size: Vector3 = Vector3(0.6, 0.9, 0.3)

var _used: bool = false
var _screen_mesh: MeshInstance3D

func _ready() -> void:
	super._ready()
	prompt_text = "READ TERMINAL"

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = terminal_size + Vector3(0.4, 0.4, 0.4)
	shape.shape = box
	add_child(shape)

	var body_mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = terminal_size
	body_mesh.mesh = bm
	body_mesh.material_override = EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL_DARK)
	add_child(body_mesh)

	_screen_mesh = MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(terminal_size.x * 0.7, terminal_size.y * 0.5, 0.02)
	_screen_mesh.mesh = sm
	_screen_mesh.position = Vector3(0, terminal_size.y * 0.15, terminal_size.z / 2.0 + 0.01)
	_screen_mesh.material_override = EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL, EnvironmentGenerator.COLOR_INTERACTIVE, 1.4)
	add_child(_screen_mesh)

func can_interact(_player: Node) -> bool:
	return enabled and not (once and _used)

func interact(_player: Node) -> void:
	if not can_interact(_player):
		return
	_used = true
	AudioManager.play_sfx("terminal_beep")
	var packaged: Array = []
	for line in lines:
		packaged.append({"speaker": speaker, "text": line})
	DialogueManager.queue_lines(packaged, slow_time)
