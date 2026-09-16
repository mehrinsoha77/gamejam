class_name QuizTerminal
extends Interactable
## A console the player interacts with to open a QuizUI. Emits `solved`
## the first time every question has been answered correctly in one
## sitting — level scripts hook that up exactly like NavigationPuzzle's
## `solved` signal (unlock a DOF, open a door, etc).
##
## Add more questions by appending to `questions` — each entry is
## {"question": "...", "answers": ["accepted", "answer", "strings"]}.
## Answers are matched case-insensitively with surrounding whitespace
## trimmed; list more than one string per question to accept variants.

signal solved

@export var questions: Array = []
@export var terminal_size: Vector3 = Vector3(0.7, 1.0, 0.35)

var _solved: bool = false

func _ready() -> void:
	super._ready()
	prompt_text = "ANSWER TERMINAL"

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

	var screen_mesh := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(terminal_size.x * 0.7, terminal_size.y * 0.5, 0.02)
	screen_mesh.position = Vector3(0, terminal_size.y * 0.15, terminal_size.z / 2.0 + 0.01)
	screen_mesh.mesh = sm
	screen_mesh.material_override = EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL, EnvironmentGenerator.COLOR_WARNING, 1.4)
	add_child(screen_mesh)

func can_interact(_player: Node) -> bool:
	return enabled and not _solved and not questions.is_empty()

func get_prompt() -> String:
	return "SOLVED" if _solved else "ANSWER TERMINAL"

func interact(_player: Node) -> void:
	if not can_interact(_player):
		return
	var quiz := QuizUI.new()
	get_tree().current_scene.add_child(quiz)
	quiz.all_answered_correctly.connect(_on_solved)
	quiz.start(questions)

func _on_solved() -> void:
	if _solved:
		return
	_solved = true
	solved.emit()
