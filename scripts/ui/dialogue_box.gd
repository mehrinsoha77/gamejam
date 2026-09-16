class_name DialogueBox
extends Control
## Subtle communication interface for AI transmissions / story beats.
## Built entirely in code — no .tscn layout to keep in sync.
## Covers a small strip near the bottom of the screen, never the whole view.

var _panel: PanelContainer
var _speaker_label: Label
var _text_label: RichTextLabel
var _hint_label: Label

var _full_text: String = ""
var _reveal_progress: float = 0.0
const CHARS_PER_SECOND := 45.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	custom_minimum_size = Vector2(0, 160)
	position.y = -190
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.position = Vector2(-320, -170)
	_panel.custom_minimum_size = Vector2(640, 150)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.08, 0.85)
	style.border_color = Color(0.35, 0.8, 1.0, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	_panel.add_child(vbox)

	_speaker_label = Label.new()
	_speaker_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	_speaker_label.text = "AI SYSTEM"
	vbox.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.custom_minimum_size = Vector2(600, 70)
	_text_label.bbcode_enabled = false
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.add_theme_color_override("default_color", Color(0.92, 0.95, 1.0))
	vbox.add_child(_text_label)

	_hint_label = Label.new()
	_hint_label.text = "[ E ] CONTINUE"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_hint_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_hint_label)

func show_line(speaker: String, text: String) -> void:
	_speaker_label.text = speaker
	_full_text = text
	_reveal_progress = 0.0
	_text_label.text = ""
	_hint_label.visible = false
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func hide_box() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)

func is_revealing() -> bool:
	return _reveal_progress < _full_text.length()

func skip_reveal() -> void:
	_reveal_progress = _full_text.length()
	_text_label.text = _full_text
	_hint_label.visible = true

func _process(delta: float) -> void:
	if not visible or _full_text.is_empty():
		return
	if _reveal_progress < _full_text.length():
		_reveal_progress += CHARS_PER_SECOND * delta
		var count: int = clampi(int(_reveal_progress), 0, _full_text.length())
		_text_label.text = _full_text.substr(0, count)
		if count >= _full_text.length():
			_hint_label.visible = true
