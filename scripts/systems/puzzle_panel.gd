class_name PuzzlePanel
extends Interactable
## One dial of the navigation puzzle. Pressing [E] cycles its value.
## Purely presentational feedback (label + emissive color) lives here;
## solution-checking lives in NavigationPuzzle so the same panel script
## can be reused by future puzzles with different rules.

signal value_changed(panel: PuzzlePanel, value: int)

@export var value_count: int = 4
@export var solved_color: Color = Color(0.3, 1.0, 0.5)
@export var unsolved_color: Color = Color(0.9, 0.75, 0.2)

var value: int = 0
var _label: Label3D
var _light: OmniLight3D

func _ready() -> void:
	super._ready()
	prompt_text = "CYCLE VALUE"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 0.5, 0.4)
	shape.shape = box
	add_child(shape)
	var panel_mesh := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.4, 0.4, 0.1)
	panel_mesh.mesh = pm
	panel_mesh.material_override = EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL_DARK)
	add_child(panel_mesh)
	_label = Label3D.new()
	_label.text = str(value)
	_label.font_size = 96
	_label.no_depth_test = true
	_label.position = Vector3(0, 0, 0.06)
	add_child(_label)
	_light = OmniLight3D.new()
	_light.light_color = unsolved_color
	_light.omni_range = 1.2
	_light.light_energy = 0.8
	add_child(_light)

func interact(_player: Node) -> void:
	if not enabled:
		return
	value = (value + 1) % value_count
	_label.text = str(value)
	AudioManager.play_sfx("ui_click")
	value_changed.emit(self, value)

func set_solved_visual(is_solved: bool) -> void:
	var color := solved_color if is_solved else unsolved_color
	_light.light_color = color
	_label.modulate = color
