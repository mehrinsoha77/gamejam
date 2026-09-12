class_name NavigationPuzzle
extends Node3D
## Level 1's "damaged navigation system" puzzle. Not a quiz: the correct
## combination is printed in-world on a conduit plaque near the panels
## (see level_1.gd), so solving it is an observe-and-input action rather
## than an exam question. Three dials must match the stamped sequence.

signal solved

@export var target_combination: Array[int] = [2, 4, 1]

var panels: Array[PuzzlePanel] = []
var _solved: bool = false

func register_panel(panel: PuzzlePanel) -> void:
	panels.append(panel)
	panel.value_changed.connect(_on_panel_changed)

func _on_panel_changed(_panel: PuzzlePanel, _value: int) -> void:
	if _solved:
		return
	_check_solution()

func _check_solution() -> void:
	if panels.size() < target_combination.size():
		return
	for i in range(target_combination.size()):
		if panels[i].value != target_combination[i]:
			for p in panels:
				p.set_solved_visual(false)
			return
	_solved = true
	for p in panels:
		p.set_solved_visual(true)
		p.enabled = false
	AudioManager.play_sfx("terminal_beep")
	solved.emit()
