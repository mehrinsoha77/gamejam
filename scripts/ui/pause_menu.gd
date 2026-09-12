class_name PauseMenu
extends CanvasLayer
## Instanced on demand by LevelBase when [ESC] is pressed during gameplay.

signal resumed

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_build_ui()

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-110, -140)
	box.custom_minimum_size = Vector2(220, 260)
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)

	box.add_child(_btn("RESUME", func(): _resume()))
	box.add_child(_btn("RESTART CHECKPOINT", func(): _resume(); GameManager.respawn_at_checkpoint()))
	box.add_child(_btn("SETTINGS", func(): _open_settings(box)))
	box.add_child(_btn("MAIN MENU", func(): _resume(); get_tree().change_scene_to_file("res://scenes/main_menu.tscn")))

func _btn(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 36)
	b.pressed.connect(func(): AudioManager.play_sfx("ui_click"); on_press.call())
	return b

func _open_settings(parent: Control) -> void:
	var settings := SettingsMenu.new()
	parent.add_child(settings)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_resume()
		get_viewport().set_input_as_handled()

func _resume() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	resumed.emit()
	queue_free()
