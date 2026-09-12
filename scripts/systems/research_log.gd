class_name ResearchLog
extends Interactable
## Optional lore pickup. Never required to finish a level — purely for
## players who want the deeper science/story context (Newtonian mechanics,
## coordinate systems, the facility's history...). See ASSETS_NEEDED.md for
## how to swap the placeholder text delivery for a holographic projection.

@export var log_title: String = "RESEARCH LOG"
@export var log_lines: Array[String] = []

var _read: bool = false

func _ready() -> void:
	super._ready()
	prompt_text = "READ LOG: " + log_title
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	shape.shape = box
	add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(0.3, 0.05, 0.2)
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL, EnvironmentGenerator.COLOR_INTERACTIVE, 0.8)
	add_child(mesh_instance)

func can_interact(_player: Node) -> bool:
	return enabled and not _read

func interact(_player: Node) -> void:
	if not can_interact(_player):
		return
	_read = true
	GameManager.research_logs_found += 1
	GameManager.score_optional_discoveries += 10
	AudioManager.play_sfx("terminal_beep")
	var packaged: Array = []
	for line in log_lines:
		packaged.append({"speaker": log_title, "text": line})
	DialogueManager.queue_lines(packaged, false)
