class_name QuizUI
extends CanvasLayer
## A plain question/answer challenge: shows a question, the player types an
## answer and presses Enter (or clicks Submit), gets told right/wrong, and
## can keep retrying with no penalty. Pauses the game and frees the mouse
## while open — unlike the old dialogue system, this is a clear modal with
## visible controls, so there's no "is it frozen?" confusion.

signal all_answered_correctly
signal closed

var _questions: Array = [] # [{"question": String, "answers": Array[String]}]
var _index: int = 0

var _question_label: Label
var _input: LineEdit
var _feedback_label: Label
var _progress_label: Label

func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_build_ui()

func start(questions: Array) -> void:
	_questions = questions
	_index = 0
	_show_current()

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560, 260)
	panel.position = Vector2(-280, -130)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.98)
	style.border_color = Color(1.0, 0.85, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 12)
	_progress_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	vbox.add_child(_progress_label)

	_question_label = Label.new()
	_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_question_label.custom_minimum_size = Vector2(500, 0)
	_question_label.add_theme_font_size_override("font_size", 20)
	_question_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	vbox.add_child(_question_label)

	_input = LineEdit.new()
	_input.placeholder_text = "Type your answer..."
	_input.custom_minimum_size = Vector2(500, 36)
	_input.text_submitted.connect(func(_t): _submit())
	vbox.add_child(_input)

	_feedback_label = Label.new()
	_feedback_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_feedback_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)

	var submit_btn := Button.new()
	submit_btn.text = "SUBMIT"
	submit_btn.pressed.connect(_submit)
	row.add_child(submit_btn)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.pressed.connect(_close)
	row.add_child(close_btn)

func _show_current() -> void:
	if _index >= _questions.size():
		all_answered_correctly.emit()
		_close()
		return
	var q: Dictionary = _questions[_index]
	_progress_label.text = "QUESTION %d / %d" % [_index + 1, _questions.size()]
	_question_label.text = q.get("question", "")
	_input.text = ""
	_feedback_label.text = ""
	_input.grab_focus()

func _submit() -> void:
	if _index >= _questions.size():
		return
	var q: Dictionary = _questions[_index]
	var accepted: Array = q.get("answers", [])
	var given := _input.text.strip_edges().to_lower()
	var correct := false
	for a in accepted:
		if given == String(a).strip_edges().to_lower():
			correct = true
			break
	if correct:
		AudioManager.play_sfx("terminal_beep")
		_index += 1
		_show_current()
	else:
		AudioManager.play_sfx("door_locked")
		_feedback_label.text = "INCORRECT — TRY AGAIN"
		_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		_input.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()
	queue_free()
