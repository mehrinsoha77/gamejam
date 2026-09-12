extends Node
## DebugManager (autoload singleton)
## Dev-only overlay + cheats. Toggled with F1. Fully disabled in exported
## release builds so nothing debug-related ships to players.

var enabled: bool = false
var _overlay: CanvasLayer
var _label: Label

func _ready() -> void:
	if not _is_debug_allowed():
		set_process_unhandled_input(false)
		return
	_overlay = CanvasLayer.new()
	_overlay.layer = 100
	add_child(_overlay)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	_label.position = Vector2(12, 12)
	_overlay.add_child(_label)
	_overlay.visible = false

func _is_debug_allowed() -> bool:
	# Never active in a release export, regardless of the F1 toggle.
	return OS.is_debug_build() or OS.has_feature("editor")

func _unhandled_input(event: InputEvent) -> void:
	if not _is_debug_allowed():
		return
	if event.is_action_pressed("debug_toggle"):
		enabled = not enabled
		_overlay.visible = enabled

func _process(_delta: float) -> void:
	if not _is_debug_allowed() or not enabled:
		return
	var player := get_tree().get_first_node_in_group("player")
	var lines: Array[String] = []
	lines.append("FPS: %d" % Engine.get_frames_per_second())
	lines.append("FREEDOM: %d" % GameManager.freedom_points)
	if player and player.has_node("FreedomComponent"):
		var fc: FreedomComponent = player.get_node("FreedomComponent")
		for dof in FreedomComponent.DOF.values():
			var state_name: String = FreedomComponent.DOFState.keys()[fc.get_state(dof)]
			lines.append("%s: %s" % [FreedomComponent.DOF_NAMES[dof], state_name])
	lines.append("")
	lines.append("F1 debug | F2 give all DOF | F3 +100 freedom | F4 teleport fwd 5m")
	_label.text = "\n".join(lines)

func _input(event: InputEvent) -> void:
	if not _is_debug_allowed() or not enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var player := get_tree().get_first_node_in_group("player")
		match event.physical_keycode:
			KEY_F2:
				if player and player.has_node("FreedomComponent"):
					var fc: FreedomComponent = player.get_node("FreedomComponent")
					for dof in FreedomComponent.DOF.values():
						fc.unlock(dof)
			KEY_F3:
				GameManager.add_freedom_points(100)
			KEY_F4:
				if player:
					player.global_position += -player.global_transform.basis.z * 5.0
