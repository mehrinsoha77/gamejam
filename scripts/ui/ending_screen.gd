extends CanvasLayer
## Generic ending / run-summary screen. Reads GameManager.pending_ending_*
## set by show_ending(), and always shows the Freedom Score + rank.
## Used for the four real endings (Escape / Liberation / Control / Secret)
## and for the vertical slice's "to be continued" screen alike.

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Engine.time_scale = 1.0
	_build_ui()
	AudioManager.set_music_state(AudioManager.MusicState.FINAL)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.01, 0.02)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-320, -160)
	box.custom_minimum_size = Vector2(640, 320)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	add_child(box)

	var title := Label.new()
	title.text = GameManager.pending_ending_title if GameManager.pending_ending_title != "" else "END OF DEMO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	box.add_child(title)

	var body := Label.new()
	body.text = GameManager.pending_ending_body
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.custom_minimum_size = Vector2(600, 0)
	body.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	box.add_child(body)

	var score := Label.new()
	score.text = "FREEDOM SCORE: %d   RANK: %s" % [GameManager.total_score(), GameManager.compute_rank()]
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.add_theme_font_size_override("font_size", 20)
	score.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	box.add_child(score)

	var btn := Button.new()
	btn.text = "MAIN MENU"
	btn.custom_minimum_size = Vector2(200, 40)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	var center := CenterContainer.new()
	center.add_child(btn)
	box.add_child(center)
