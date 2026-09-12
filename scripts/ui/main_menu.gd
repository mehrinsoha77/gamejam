extends CanvasLayer
## Main Menu — the game's first scene (see project.godot run/main_scene).

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Engine.time_scale = 1.0
	_build_ui()
	AudioManager.set_music_state(AudioManager.MusicState.DISCOVERY)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.035)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title_box := VBoxContainer.new()
	title_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_box.position = Vector2(-260, 90)
	title_box.custom_minimum_size = Vector2(520, 140)
	root.add_child(title_box)

	var title := Label.new()
	title.text = "DEGREES OF FREEDOM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	title_box.add_child(title)

	var tagline := Label.new()
	tagline.text = "Every freedom has a cost."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 16)
	tagline.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	title_box.add_child(tagline)

	var menu_box := VBoxContainer.new()
	menu_box.set_anchors_preset(Control.PRESET_CENTER)
	menu_box.position = Vector2(-100, 20)
	menu_box.custom_minimum_size = Vector2(200, 220)
	menu_box.add_theme_constant_override("separation", 10)
	root.add_child(menu_box)

	menu_box.add_child(_make_button("NEW GAME", func(): GameManager.start_new_game()))
	var continue_btn := _make_button("CONTINUE", func(): GameManager.load_checkpoint())
	continue_btn.disabled = not GameManager.has_save()
	menu_box.add_child(continue_btn)
	menu_box.add_child(_make_button("SETTINGS", func(): _open_settings(root)))
	menu_box.add_child(_make_button("CREDITS", func(): get_tree().change_scene_to_file("res://scenes/credits.tscn")))
	menu_box.add_child(_make_button("QUIT", func(): get_tree().quit()))

func _make_button(text: String, on_press: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 40)
	btn.pressed.connect(func(): AudioManager.play_sfx("ui_click"); on_press.call())
	return btn

func _open_settings(root: Control) -> void:
	var settings := SettingsMenu.new()
	root.add_child(settings)
